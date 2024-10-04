output "terraform_backend_dynamodb_name" {
  value = module.backend_setup.terraform_backend_dynamodb_name
}

output "terraform_backend_s3_id" {
  value = module.backend_setup.terraform_backend_s3_id
}
