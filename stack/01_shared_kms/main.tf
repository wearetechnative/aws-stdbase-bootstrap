module "default_kms" {

  source = "git@github.com:wearetechnative/terraform-aws-kms.git?ref=6d85ef07545a6a0e36afade4960a80ad4e3a079c"

  name        = "default_kms"
  role_access = []
}
