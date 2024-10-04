module "backend_setup" {

  source = "git@github.com:wearetechnative/terraform-aws-module-terraform-backend.git?ref=3d17fc2346e0ef3049f584e312c7de4cd3a22310"

  name           = "${var.aws_account_id}-${var.infra_environment}"
  kms_key_arn    = var.kms_arn
  use_fixed_name = true
}
