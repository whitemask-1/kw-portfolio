variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "S3 bucket name for portfolio website"
  type        = string
  default     = "kw-portfolio-bucket-123456"
}

variable "domain_name" {
  description = "Domain name for the portfolio website"
  type        = string
  default     = ""
}

