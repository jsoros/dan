terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = "AWS-Synthetics-Monitoring"
    }
  }
}

# S3 bucket for canary artifacts (screenshots, logs, etc.)
resource "aws_s3_bucket" "canary_artifacts" {
  bucket = "${var.project_name}-canary-artifacts-${var.environment}"
}

resource "aws_s3_bucket_versioning" "canary_artifacts" {
  bucket = aws_s3_bucket.canary_artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "canary_artifacts" {
  bucket = aws_s3_bucket.canary_artifacts.id

  rule {
    id     = "delete-old-artifacts"
    status = "Enabled"

    expiration {
      days = var.artifact_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}

resource "aws_s3_bucket_public_access_block" "canary_artifacts" {
  bucket = aws_s3_bucket.canary_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM role for canaries
resource "aws_iam_role" "canary_role" {
  name = "${var.project_name}-canary-role-${var.environment}"
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
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for canaries
resource "aws_iam_role_policy" "canary_policy" {
  name = "${var.project_name}-canary-policy-${var.environment}"
  role = aws_iam_role.canary_role.id
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
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.canary_artifacts.arn,
          "${aws_s3_bucket.canary_artifacts.arn}/*"
        ]
          "ec2:DescribeAvailabilityZones"
        ]
        Resource = "*"
        # Note: ec2:DescribeAvailabilityZones does not support resource-level permissions
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:*:log-group:/aws/lambda/cwsyn-*"
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
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "cloudwatch:namespace" = "CloudWatchSynthetics"
          }
        }
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach AWS managed policy for Lambda basic execution
resource "aws_iam_role_policy_attachment" "canary_basic_execution" {
  role       = aws_iam_role.canary_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# SNS topic for canary alarms
resource "aws_sns_topic" "canary_alerts" {
  name = "${var.project_name}-canary-alerts-${var.environment}"
}

resource "aws_sns_topic_subscription" "canary_alerts_email" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.canary_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# Archive canary source code
data "archive_file" "api_monitor" {
  type        = "zip"
  source_file = "${path.module}/../canaries/api-monitor/apiMonitor.js"
  output_path = "${path.module}/canary-artifacts/api-monitor.zip"
}

data "archive_file" "ui_monitor" {
  type        = "zip"
  source_file = "${path.module}/../canaries/ui-monitor/uiMonitor.js"
  output_path = "${path.module}/canary-artifacts/ui-monitor.zip"
}

data "archive_file" "heartbeat" {
  type        = "zip"
  source_file = "${path.module}/../canaries/heartbeat/heartbeat.js"
  output_path = "${path.module}/canary-artifacts/heartbeat.zip"
}

# Upload canary code to S3
resource "aws_s3_object" "api_monitor_code" {
  bucket = aws_s3_bucket.canary_artifacts.id
  key    = "canary-code/api-monitor.zip"
  source = data.archive_file.api_monitor.output_path
  etag   = filemd5(data.archive_file.api_monitor.output_path)
}

resource "aws_s3_object" "ui_monitor_code" {
  bucket = aws_s3_bucket.canary_artifacts.id
  key    = "canary-code/ui-monitor.zip"
  source = data.archive_file.ui_monitor.output_path
  etag   = filemd5(data.archive_file.ui_monitor.output_path)
}

resource "aws_s3_object" "heartbeat_code" {
  bucket = aws_s3_bucket.canary_artifacts.id
  key    = "canary-code/heartbeat.zip"
  source = data.archive_file.heartbeat.output_path
  etag   = filemd5(data.archive_file.heartbeat.output_path)
}

# API Monitor Canary
resource "aws_synthetics_canary" "api_monitor" {
  name                 = "${var.project_name}-api-monitor-${var.environment}"
  artifact_s3_location = "s3://${aws_s3_bucket.canary_artifacts.id}/api-monitor/"
  execution_role_arn   = aws_iam_role.canary_role.arn
  handler              = "apiMonitor.handler"
  runtime_version      = "syn-nodejs-puppeteer-6.2"
  start_canary         = var.start_canary
  zip_file             = data.archive_file.api_monitor.output_path

  schedule {
    expression = var.api_monitor_schedule
  }

  run_config {
    timeout_in_seconds = 60
    memory_in_mb       = 960
  }

  success_retention_period = var.success_retention_days
  failure_retention_period = var.failure_retention_days

  tags = {
    Name = "API Monitor"
    Type = "API"
  }

  depends_on = [
    aws_iam_role_policy.canary_policy,
    aws_s3_object.api_monitor_code
  ]
}

# UI Monitor Canary
resource "aws_synthetics_canary" "ui_monitor" {
  name                 = "${var.project_name}-ui-monitor-${var.environment}"
  artifact_s3_location = "s3://${aws_s3_bucket.canary_artifacts.id}/ui-monitor/"
  execution_role_arn   = aws_iam_role.canary_role.arn
  handler              = "uiMonitor.handler"
  runtime_version      = "syn-nodejs-puppeteer-6.2"
  start_canary         = var.start_canary
  zip_file             = data.archive_file.ui_monitor.output_path

  schedule {
    expression = var.ui_monitor_schedule
  }

  run_config {
    timeout_in_seconds = 120
    memory_in_mb       = 1024
  }

  success_retention_period = var.success_retention_days
  failure_retention_period = var.failure_retention_days

  tags = {
    Name = "UI Monitor"
    Type = "UI"
  }

  depends_on = [
    aws_iam_role_policy.canary_policy,
    aws_s3_object.ui_monitor_code
  ]
}

# Heartbeat Canary
resource "aws_synthetics_canary" "heartbeat" {
  name                 = "${var.project_name}-heartbeat-${var.environment}"
  artifact_s3_location = "s3://${aws_s3_bucket.canary_artifacts.id}/heartbeat/"
  execution_role_arn   = aws_iam_role.canary_role.arn
  handler              = "heartbeat.handler"
  runtime_version      = "syn-nodejs-puppeteer-6.2"
  start_canary         = var.start_canary
  zip_file             = data.archive_file.heartbeat.output_path

  schedule {
    expression = var.heartbeat_schedule
  }

  run_config {
    timeout_in_seconds = 30
    memory_in_mb       = 960
  }

  success_retention_period = var.success_retention_days
  failure_retention_period = var.failure_retention_days

  tags = {
    Name = "Heartbeat"
    Type = "Heartbeat"
  }

  depends_on = [
    aws_iam_role_policy.canary_policy,
    aws_s3_object.heartbeat_code
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
