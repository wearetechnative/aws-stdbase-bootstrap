variable "aws_account_id" {
  description = "ID of the AWS account."
  type        = string
}

variable "infra_environment" {
  description = "Name of the infrastructure environment."
  type        = string
}

variable "kms_arn" {
  description = "KMS ARN"
  type = string
}
