output region {
  value = var.region
  description = "AWS region to deploy resources"
}
# Cluster outputs --------------------------------------------------------
output "cluster_id" {
  value = module.eks.cluster_id
  description = "The ID of the EKS cluster."
}

output "cluster_name" {
  value       = module.eks.cluster_name
  description = "Kubernetes Cluster Name"
}

output "cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "Endpoint for EKS control plane"
}

output "cluster_security_group_id" {
  value       = module.eks.cluster_security_group_id
  description = "Security group ids attached to the cluster control plane"
}

output "cluster_certificate_authority_data" {
  value       = module.eks.cluster_certificate_authority_data
  description = "Base64 encoded certificate data required to communicate with the cluster"
}