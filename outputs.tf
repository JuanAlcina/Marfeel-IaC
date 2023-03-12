# General outputs --------------------------------------------------------
output "region" {
  value       = var.region
  description = "AWS region to deploy resources"
}

output "vpc_id" {
  value = [module.vpc.*.vpc_id]
}

# Dev outputs ------------------------------------------------------------

output "dev_cluster_endpoint" {
  value       = [module.dev_eks.cluster_endpoint]
  description = "Endpoint for EKS control plane"
}

output "dev_oidc_provider_arn" {
  value = [module.dev_eks.oidc_provider_arn]
}

output "dev_cluster_certificate_authority_data" {
  value       = [module.dev_eks.cluster_certificate_authority_data]
  description = "Base64 encoded certificate data required to communicate with the cluster"
}

output "dev_iam_role_arn" {
  value = [module.dev_lb_role.iam_role_arn]
}

# Stage outputs ------------------------------------------------------------

output "stage_cluster_endpoint" {
  value       = [module.stage_eks.cluster_endpoint]
  description = "Endpoint for EKS control plane"
}

output "stage_oidc_provider_arn" {
  value = [module.stage_eks.oidc_provider_arn]
}

output "stage_cluster_certificate_authority_data" {
  value       = [module.stage_eks.cluster_certificate_authority_data]
  description = "Base64 encoded certificate data required to communicate with the cluster"
}

output "stage_iam_role_arn" {
  value = [module.stage_lb_role.iam_role_arn]
}

# production outputs --------------------------------------------------------

output "production_cluster_endpoint" {
  value       = [module.production_eks.cluster_endpoint]
  description = "Endpoint for EKS control plane"
}

output "production_oidc_provider_arn" {
  value = [module.production_eks.oidc_provider_arn]
}

output "production_cluster_certificate_authority_data" {
  value       = [module.production_eks.cluster_certificate_authority_data]
  description = "Base64 encoded certificate data required to communicate with the cluster"
}

output "production_iam_role_arn" {
  value = [module.production_lb_role.iam_role_arn]
}