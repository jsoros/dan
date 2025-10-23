variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "synthetics"
}

variable "alert_email" {
  description = "Email address for canary alerts (leave empty to skip email subscription)"
  type        = string
  default     = ""
}

# Canary Configuration
variable "start_canary" {
  description = "Whether to start the canaries after creation"
  type        = bool
  default     = true
}

variable "api_monitor_schedule" {
  description = "Schedule expression for API monitor canary (cron or rate)"
  type        = string
  default     = "rate(5 minutes)"
}

variable "ui_monitor_schedule" {
  description = "Schedule expression for UI monitor canary (cron or rate)"
  type        = string
  default     = "rate(15 minutes)"
}

variable "heartbeat_schedule" {
  description = "Schedule expression for heartbeat canary (cron or rate)"
  type        = string
  default     = "rate(5 minutes)"
}

# Retention Configuration
variable "artifact_retention_days" {
  description = "Number of days to retain canary artifacts in S3"
  type        = number
  default     = 30
}

variable "success_retention_days" {
  description = "Number of days to retain successful canary runs"
  type        = number
  default     = 31
}

variable "failure_retention_days" {
  description = "Number of days to retain failed canary runs"
  type        = number
  default     = 31
}

# CloudWatch Alarm Configuration
variable "alarm_threshold" {
  description = "Success rate threshold for alarms (percentage)"
  type        = number
  default     = 90
}

variable "alarm_evaluation_periods" {
  description = "Number of periods to evaluate for alarm"
  type        = number
  default     = 2
}

variable "alarm_period" {
  description = "Period in seconds for alarm evaluation"
  type        = number
  default     = 300
}

variable "duration_threshold_ms" {
  description = "Duration threshold in milliseconds for slow response alarms"
  type        = number
  default     = 10000
}
