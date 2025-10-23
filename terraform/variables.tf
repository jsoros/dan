variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "az-health-check"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.function_name))
    error_message = "Function name must contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 30

  validation {
    condition     = var.lambda_timeout >= 10 && var.lambda_timeout <= 300
    error_message = "Lambda timeout must be between 10 and 300 seconds."
  }
}

variable "lambda_memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 256

  validation {
    condition     = contains([128, 256, 512, 1024, 2048, 3008], var.lambda_memory_size)
    error_message = "Memory size must be one of: 128, 256, 512, 1024, 2048, 3008."
  }
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention period in days"
  type        = number
  default     = 365

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention must be a valid CloudWatch Logs retention period."
  }
}

variable "enable_xray_tracing" {
  description = "Enable AWS X-Ray tracing for the Lambda function"
  type        = bool
  default     = true
}

variable "reserved_concurrent_executions" {
  description = "Amount of reserved concurrent executions for this lambda function (-1 for unreserved)"
  type        = number
  default     = -1

  validation {
    condition     = var.reserved_concurrent_executions >= -1
    error_message = "Reserved concurrent executions must be -1 or greater."
  }
}

variable "kms_key_arn" {
  description = "ARN of the KMS key for encrypting CloudWatch Logs and Lambda environment variables (if not provided, AWS managed key will be used for logs)"
  type        = string
  default     = ""
}

variable "enable_dlq" {
  description = "Enable Dead Letter Queue for failed Lambda invocations"
  type        = bool
  default     = false
}

variable "dlq_target_arn" {
  description = "ARN of the SQS queue or SNS topic for DLQ (required if enable_dlq is true)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Name        = "az-health-check"
    Purpose     = "AZ Health Monitoring"
    ManagedBy   = "Terraform"
  }
}
