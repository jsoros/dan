# Data source to create Lambda deployment package
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

# IAM Policy for Lambda
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.function_name}-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeAvailabilityZones"
        ]
        Resource = "*"
        # Note: ec2:DescribeAvailabilityZones does not support resource-level permissions
      },
      {
        Effect = "Allow"
        Action = [
          "health:DescribeEvents",
          "health:DescribeEventDetails",
          "health:DescribeAffectedEntities"
        ]
        Resource = "*"
        # Note: health:* actions do not support resource-level permissions
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
        # Note: X-Ray actions do not support resource-level permissions
      }
    ]
  })
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn != "" ? var.kms_key_arn : null

  tags = var.tags
}

# Lambda Function
resource "aws_lambda_function" "az_health_check" {
  filename                       = data.archive_file.lambda_zip.output_path
  function_name                  = var.function_name
  role                          = aws_iam_role.lambda_role.arn
  handler                       = "lambda_function.lambda_handler"
  source_code_hash              = data.archive_file.lambda_zip.output_base64sha256
  runtime                       = "python3.11"
  timeout                       = var.lambda_timeout
  memory_size                   = var.lambda_memory_size
  reserved_concurrent_executions = var.reserved_concurrent_executions >= 0 ? var.reserved_concurrent_executions : null
  kms_key_arn                   = var.kms_key_arn != "" ? var.kms_key_arn : null

  description = "Checks AWS Availability Zone health status using Health API and EC2 API"

  environment {
    variables = {
      LOG_LEVEL = "INFO"
    }
  }

  # X-Ray tracing configuration
  tracing_config {
    mode = var.enable_xray_tracing ? "Active" : "PassThrough"
  }

  # Dead Letter Queue configuration
  dynamic "dead_letter_config" {
    for_each = var.enable_dlq && var.dlq_target_arn != "" ? [1] : []
    content {
      target_arn = var.dlq_target_arn
    }
  }

  tags = var.tags

  depends_on = [
    aws_cloudwatch_log_group.lambda_logs,
    aws_iam_role_policy.lambda_policy
  ]
}
