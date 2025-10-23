"""
AWS Lambda function to check Availability Zone health status.

This function checks if an AWS Availability Zone is experiencing issues by:
1. Querying AWS Health API for AZ-specific events
2. Checking EC2 AZ status and state
3. Analyzing recent service events in the region
"""

import json
import logging
from typing import Dict, List, Any
from datetime import datetime, timedelta

import boto3
from botocore.exceptions import ClientError

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
health_client = boto3.client('health', region_name='us-east-1')  # Health API only available in us-east-1
ec2_client = boto3.client('ec2')


def get_az_health_events(region: str, availability_zone: str) -> List[Dict[str, Any]]:
    """
    Query AWS Health API for events affecting the specified AZ.

    Args:
        region: AWS region (e.g., 'us-east-1')
        availability_zone: AZ name (e.g., 'us-east-1a')

    Returns:
        List of health events affecting the AZ
    """
    try:
        # Query for events in the last 7 days
        end_time = datetime.now()
        start_time = end_time - timedelta(days=7)

        event_filter = {
            'regions': [region],
            'availabilityZones': [availability_zone],
            'eventStatusCodes': ['open', 'upcoming'],
            'startTimes': [
                {
                    'from': start_time,
                    'to': end_time
                }
            ]
        }

        events = []
        paginator = health_client.get_paginator('describe_events')

        for page in paginator.paginate(filter=event_filter):
            events.extend(page.get('events', []))

        logger.info(f"Found {len(events)} health events for AZ {availability_zone}")
        return events

    except ClientError as e:
        error_code = e.response['Error']['Code']
        if error_code == 'SubscriptionRequiredException':
            logger.warning("AWS Health API requires AWS Business or Enterprise Support plan")
            return []
        else:
            logger.error(f"Error querying Health API: {e}")
            raise
    except Exception as e:
        logger.error(f"Unexpected error querying Health API: {e}")
        return []


def check_az_status(availability_zone: str) -> Dict[str, Any]:
    """
    Check the status of an Availability Zone using EC2 API.

    Args:
        availability_zone: AZ name (e.g., 'us-east-1a')

    Returns:
        Dictionary containing AZ status information
    """
    try:
        response = ec2_client.describe_availability_zones(
            ZoneNames=[availability_zone]
        )

        if not response.get('AvailabilityZones'):
            return {
                'exists': False,
                'status': 'unknown',
                'state': 'unknown',
                'messages': []
            }

        az_info = response['AvailabilityZones'][0]

        return {
            'exists': True,
            'zone_name': az_info.get('ZoneName'),
            'zone_id': az_info.get('ZoneId'),
            'state': az_info.get('State'),
            'region': az_info.get('RegionName'),
            'messages': az_info.get('Messages', []),
            'network_border_group': az_info.get('NetworkBorderGroup')
        }

    except ClientError as e:
        logger.error(f"Error checking AZ status: {e}")
        raise
    except Exception as e:
        logger.error(f"Unexpected error checking AZ status: {e}")
        raise


def analyze_health_status(
    az_info: Dict[str, Any],
    health_events: List[Dict[str, Any]]
) -> Dict[str, Any]:
    """
    Analyze AZ health based on status and events.

    Args:
        az_info: AZ status information from EC2 API
        health_events: List of health events from AWS Health API

    Returns:
        Dictionary containing health analysis
    """
    issues = []
    severity = 'healthy'

    # Check if AZ exists
    if not az_info.get('exists'):
        return {
            'status': 'error',
            'severity': 'critical',
            'message': 'Availability Zone does not exist',
            'issues': ['AZ not found'],
            'health_events': []
        }

    # Check AZ state
    if az_info.get('state') != 'available':
        issues.append(f"AZ state is {az_info.get('state')} (expected: available)")
        severity = 'critical'

    # Check for AZ-specific messages
    if az_info.get('messages'):
        for msg in az_info['messages']:
            issues.append(f"AZ message: {msg}")
        if severity == 'healthy':
            severity = 'warning'

    # Analyze health events
    critical_events = []
    warning_events = []

    for event in health_events:
        event_type_category = event.get('eventTypeCategory', '')
        event_info = {
            'arn': event.get('arn'),
            'service': event.get('service'),
            'event_type_code': event.get('eventTypeCode'),
            'event_type_category': event_type_category,
            'status': event.get('statusCode'),
            'start_time': event.get('startTime').isoformat() if event.get('startTime') else None,
            'end_time': event.get('endTime').isoformat() if event.get('endTime') else None,
            'last_updated': event.get('lastUpdatedTime').isoformat() if event.get('lastUpdatedTime') else None
        }

        if event_type_category in ['issue', 'accountNotification']:
            critical_events.append(event_info)
            issues.append(f"Critical event: {event.get('eventTypeCode')} - {event.get('service')}")
            if severity != 'critical':
                severity = 'critical'
        else:
            warning_events.append(event_info)
            if severity == 'healthy':
                severity = 'warning'

    # Determine overall status
    if severity == 'critical':
        status = 'unhealthy'
    elif severity == 'warning':
        status = 'degraded'
    else:
        status = 'healthy'

    return {
        'status': status,
        'severity': severity,
        'message': f"AZ is {status}",
        'issues': issues,
        'critical_events': critical_events,
        'warning_events': warning_events,
        'az_info': az_info
    }


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda function handler to check AZ health.

    Expected event format:
    {
        "availability_zone": "us-east-1a",
        "region": "us-east-1"  # Optional, will be inferred from AZ name if not provided
    }

    Returns:
        Dictionary containing health check results
    """
    try:
        # Extract parameters
        availability_zone = event.get('availability_zone')

        if not availability_zone:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Missing required parameter: availability_zone'
                })
            }

        # Infer region from AZ name if not provided
        region = event.get('region')
        if not region:
            # AZ format is typically <region><letter>, e.g., us-east-1a
            region = availability_zone[:-1]

        logger.info(f"Checking health for AZ: {availability_zone} in region: {region}")

        # Reinitialize EC2 client with correct region if needed
        global ec2_client
        current_region = ec2_client.meta.region_name
        if current_region != region:
            ec2_client = boto3.client('ec2', region_name=region)

        # Get AZ status
        az_info = check_az_status(availability_zone)

        # Get health events
        health_events = get_az_health_events(region, availability_zone)

        # Analyze overall health
        health_analysis = analyze_health_status(az_info, health_events)

        # Prepare response
        response = {
            'availability_zone': availability_zone,
            'region': region,
            'timestamp': datetime.now().isoformat(),
            'health': health_analysis
        }

        logger.info(f"Health check complete: {health_analysis['status']}")

        return {
            'statusCode': 200,
            'body': json.dumps(response, default=str)
        }

    except ClientError as e:
        logger.error(f"AWS API error: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'AWS API error',
                'message': str(e)
            })
        }
    except Exception as e:
        logger.error(f"Unexpected error: {e}", exc_info=True)
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal error',
                'message': str(e)
            })
        }


# For local testing
if __name__ == '__main__':
    # Example test event
    test_event = {
        'availability_zone': 'us-east-1a',
        'region': 'us-east-1'
    }

    result = lambda_handler(test_event, None)
    print(json.dumps(json.loads(result['body']), indent=2))
