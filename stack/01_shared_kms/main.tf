### IF USE ASSUME ROLE IS TRUE YOU NEED THIS CONFIGURATION BELOW

module "default_kms" {

  source = "git@github.com:wearetechnative/terraform-aws-kms.git"

  name        = "default_kms"
  role_access = []
}

### IF USE ASSUME ROLE IS FALSE YOU NEED THIS CONFIGURATION BELOW

# module "default_kms" {
#   source = "git@github.com:wearetechnative/terraform-aws-kms.git"
#
#   name        = "default"
#   role_access = []
#   resource_policy_additions = jsondecode(data.aws_iam_policy_document.kms_iam_user_permissions.json)
# }

# data "aws_iam_policy_document" "kms_iam_user_permissions" {
#   statement {
#     sid = "Allow iam user to access the KMS at any time."
#
#     actions = [
#       "kms:*",
#     ]
#
#     principals {
#       type        = "AWS"
#       identifiers = [
#         "arn:aws:iam::000000000000:root",
#         "arn:aws:iam::000000000000:user/ADMINUSERNAME"
#       ]
#     }
#     resources = ["*"]
#   }
# }
