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
}
