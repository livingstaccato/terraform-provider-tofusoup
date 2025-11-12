# Query AWS provider information from Terraform registry
data "tofusoup_provider_info" "aws_terraform" {
  namespace = "hashicorp"
  name      = "aws"
  registry  = "terraform"
}

# Query null provider from OpenTofu registry
data "tofusoup_provider_info" "null_opentofu" {
  namespace = "hashicorp"
  name      = "null"
  registry  = "opentofu"
}

output "terraform_version" {
  description = "Latest AWS provider version from Terraform registry"
  value       = data.tofusoup_provider_info.aws_terraform.latest_version
}

output "terraform_downloads" {
  description = "Total downloads from Terraform registry"
  value       = data.tofusoup_provider_info.aws_terraform.downloads
}

output "opentofu_version" {
  description = "Latest null provider version from OpenTofu registry"
  value       = data.tofusoup_provider_info.null_opentofu.latest_version
}

output "opentofu_description" {
  description = "Description of null provider from OpenTofu registry"
  value       = data.tofusoup_provider_info.null_opentofu.description
}
