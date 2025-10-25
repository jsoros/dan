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
