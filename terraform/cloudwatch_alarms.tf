# CloudWatch Alarms for Canaries

# API Monitor Alarm
resource "aws_cloudwatch_metric_alarm" "api_monitor_failed" {
  alarm_name          = "${var.project_name}-api-monitor-failed-${var.environment}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "SuccessPercent"
  namespace           = "CloudWatchSynthetics"
  period              = var.alarm_period
  statistic           = "Average"
  threshold           = var.alarm_threshold
  alarm_description   = "This metric monitors API monitor canary success rate"
  treat_missing_data  = "notBreaching"

  dimensions = {
    CanaryName = aws_synthetics_canary.api_monitor.name
  }

  alarm_actions = [aws_sns_topic.canary_alerts.arn]
  ok_actions    = [aws_sns_topic.canary_alerts.arn]

  tags = {
    Name   = "API Monitor Failed Alarm"
    Canary = aws_synthetics_canary.api_monitor.name
  }
}

resource "aws_cloudwatch_metric_alarm" "api_monitor_duration" {
  alarm_name          = "${var.project_name}-api-monitor-slow-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "Duration"
  namespace           = "CloudWatchSynthetics"
  period              = var.alarm_period
  statistic           = "Average"
  threshold           = var.duration_threshold_ms
  alarm_description   = "This metric monitors API monitor canary response time"
  treat_missing_data  = "notBreaching"

  dimensions = {
    CanaryName = aws_synthetics_canary.api_monitor.name
  }

  alarm_actions = [aws_sns_topic.canary_alerts.arn]
  ok_actions    = [aws_sns_topic.canary_alerts.arn]

  tags = {
    Name   = "API Monitor Slow Response Alarm"
    Canary = aws_synthetics_canary.api_monitor.name
  }
}

# UI Monitor Alarm
resource "aws_cloudwatch_metric_alarm" "ui_monitor_failed" {
  alarm_name          = "${var.project_name}-ui-monitor-failed-${var.environment}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "SuccessPercent"
  namespace           = "CloudWatchSynthetics"
  period              = var.alarm_period
  statistic           = "Average"
  threshold           = var.alarm_threshold
  alarm_description   = "This metric monitors UI monitor canary success rate"
  treat_missing_data  = "notBreaching"

  dimensions = {
    CanaryName = aws_synthetics_canary.ui_monitor.name
  }

  alarm_actions = [aws_sns_topic.canary_alerts.arn]
  ok_actions    = [aws_sns_topic.canary_alerts.arn]

  tags = {
    Name   = "UI Monitor Failed Alarm"
    Canary = aws_synthetics_canary.ui_monitor.name
  }
}

# Heartbeat Alarm
resource "aws_cloudwatch_metric_alarm" "heartbeat_failed" {
  alarm_name          = "${var.project_name}-heartbeat-failed-${var.environment}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "SuccessPercent"
  namespace           = "CloudWatchSynthetics"
  period              = var.alarm_period
  statistic           = "Average"
  threshold           = var.alarm_threshold
  alarm_description   = "This metric monitors heartbeat canary success rate"
  treat_missing_data  = "notBreaching"

  dimensions = {
    CanaryName = aws_synthetics_canary.heartbeat.name
  }

  alarm_actions = [aws_sns_topic.canary_alerts.arn]
  ok_actions    = [aws_sns_topic.canary_alerts.arn]

  tags = {
    Name   = "Heartbeat Failed Alarm"
    Canary = aws_synthetics_canary.heartbeat.name
  }
}
