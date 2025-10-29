output "canary_bucket_name" {
  description = "Name of the S3 bucket storing canary artifacts"
  value       = aws_s3_bucket.canary_artifacts.id
}

output "canary_bucket_arn" {
  description = "ARN of the S3 bucket storing canary artifacts"
  value       = aws_s3_bucket.canary_artifacts.arn
}

output "api_monitor_name" {
  description = "Name of the API monitor canary"
  value       = aws_synthetics_canary.api_monitor.name
}

output "api_monitor_arn" {
  description = "ARN of the API monitor canary"
  value       = aws_synthetics_canary.api_monitor.arn
}

output "ui_monitor_name" {
  description = "Name of the UI monitor canary"
  value       = aws_synthetics_canary.ui_monitor.name
}

output "ui_monitor_arn" {
  description = "ARN of the UI monitor canary"
  value       = aws_synthetics_canary.ui_monitor.arn
}

output "heartbeat_name" {
  description = "Name of the heartbeat canary"
  value       = aws_synthetics_canary.heartbeat.name
}

output "heartbeat_arn" {
  description = "ARN of the heartbeat canary"
  value       = aws_synthetics_canary.heartbeat.arn
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for canary alerts"
  value       = aws_sns_topic.canary_alerts.arn
}

output "canary_role_arn" {
  description = "ARN of the IAM role used by canaries"
  value       = aws_iam_role.canary_role.arn
}

output "cloudwatch_dashboard_url" {
  description = "URL to CloudWatch Synthetics dashboard"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#synthetics:canary/list"
output "function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.az_health_check.function_name
}

output "function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.az_health_check.arn
}

output "function_invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  value       = aws_lambda_function.az_health_check.invoke_arn
}

output "role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.lambda_role.arn
}

output "log_group_name" {
  description = "Name of the CloudWatch Log Group"
  value       = aws_cloudwatch_log_group.lambda_logs.name
}

output "invoke_command" {
  description = "AWS CLI command to invoke the function"
  value       = "aws lambda invoke --function-name ${aws_lambda_function.az_health_check.function_name} --payload '{\"availability_zone\":\"us-east-1a\"}' response.json && cat response.json"
}
