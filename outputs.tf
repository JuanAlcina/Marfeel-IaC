output "region" {
  value       = var.region
  description = "AWS region to deploy resources"
}

output "vpc_id" {
  value = [module.vpc.*.vpc_id]
}

output "cluster_endpoint" {
  value       = [module.eks.*.cluster_endpoint]
  description = "Endpoint for EKS control plane"
}

output "oidc_provider_arn" {
  value = [module.eks.*.oidc_provider_arn]
}

output "cluster_certificate_authority_data" {
  value       = [module.eks.*.cluster_certificate_authority_data]
  description = "Base64 encoded certificate data required to communicate with the cluster"
}

output "iam_role_arn" {
  value = [module.lb_role.*.iam_role_arn]
}