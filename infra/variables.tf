variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-southeast-2"
}

variable "tenant_id" {
  description = "The unique ID for the tenant"
  type        = string
}

variable "domain_name" {
  description = "The custom domain for the tenant"
  type        = string
}

