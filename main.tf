# VPC --------------------------------------------------------
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name = var.vpc_name

  cidr = "10.0.0.0/16"
  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24"]

  enable_nat_gateway = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
  }
  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
  }
}

# EKS --------------------------------------------------------
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true
  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"
    instance_types = var.instance_types
  }

  cluster_security_group_additional_rules = {
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
  }

  eks_managed_node_groups = {
    one = {
      name = "node-group-1"
      min_size     = 1
      max_size     = 2
      desired_size = 1
    }
    two = {
      name = "node-group-2"
      min_size     = 1
      max_size     = 2
      desired_size = 1
    }
  }
}

# ArgoCD --------------------------------------------------------
resource "kubectl_manifest" "namespace" {
  depends_on = [
    module.eks
  ]
  for_each           = data.kubectl_file_documents.namespace.manifests
  yaml_body          = each.value
  override_namespace = "argocd"
}

resource "kubectl_manifest" "argocd" {
  depends_on = [
    kubectl_manifest.namespace
  ]
  for_each           = data.kubectl_file_documents.argocd.manifests
  yaml_body          = each.value
  override_namespace = "argocd"
}

resource "kubectl_manifest" "application" {
  depends_on = [
    kubectl_manifest.argocd
  ]
  for_each           = data.kubectl_file_documents.application.manifests
  yaml_body          = each.value
  override_namespace = "argocd"
}