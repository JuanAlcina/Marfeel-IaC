# ----------------------------------------------------------------------------------------------
# Locals ---------------------------------------------------------------------------------------
locals {
  account_id = data.aws_caller_identity.current.account_id
}

# ----------------------------------------------------------------------------------------------
# VPC ------------------------------------------------------------------------------------------
module "vpc" {
  count   = length(var.env_names)
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.2"

  name = "${var.vpc_name}-${var.env_names[count.index]}"
  cidr = var.vpc_cidrs[count.index]

  azs             = var.vpc_azs
  private_subnets = var.vpc_private_subnets[count.index]
  public_subnets  = var.vpc_public_subnets[count.index]

  enable_nat_gateway = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}-${var.env_names[count.index]}" = "shared"
    "kubernetes.io/role/elb"                      = 1
  }
  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}-${var.env_names[count.index]}" = "shared"
    "kubernetes.io/role/internal-elb"                                         = 1
  }
}

# ----------------------------------------------------------------------------------------------
# EKS ------------------------------------------------------------------------------------------
module "eks" {
  providers = {kubernetes = kubernetes.dev}
  count                           = length(var.env_names)
  source                          = "terraform-aws-modules/eks/aws"
  version                         = "18.29.1"
  cluster_name                    = "${var.cluster_name}-${var.env_names[count.index]}"
  cluster_version                 = var.cluster_version
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  enable_irsa                     = true

  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
    }
  }

  vpc_id     = module.vpc[count.index].vpc_id
  subnet_ids = module.vpc[count.index].private_subnets

  manage_aws_auth_configmap = true

  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::${local.account_id}:user/eksadmin"
      username = "cluster-admin"
      groups   = ["system:masters"]
    },
  ]

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

  node_security_group_additional_rules = {
    ingress_allow_access_from_control_plane = {
      type                          = "ingress"
      protocol                      = "tcp"
      from_port                     = 9443
      to_port                       = 9443
      source_cluster_security_group = true
      description                   = "Allow access from control plane to webhook port of AWS load balancer controller"
    }
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  eks_managed_node_groups = {
    marfeel_nodes = {
      ami_type             = "BOTTLEROCKET_x86_64"
      platform             = "bottlerocket"
      min_size             = 1
      max_size             = 2
      desired_size         = 1
      capacity_type        = "SPOT"
      bootstrap_extra_args = <<-EOT
      [settings.kernel]
      lockdown = "integrity"
      EOT
    }
  }
}

# ----------------------------------------------------------------------------------------------
# Load Balancer Controller ---------------------------------------------------------------------
module "lb_role" {
  count                                  = length(var.env_names)
  depends_on                             = [module.eks]
  source                                 = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name                              = "aws-load-balancer-controller"
  attach_load_balancer_controller_policy = true
  oidc_providers = {
    main = {
      provider_arn               = module.eks[count.index].oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

resource "kubernetes_service_account" "service-account" {
  provider = kubernetes.dev
  count      = length(var.env_names)
  depends_on = [module.lb_role]
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
      "app.kubernetes.io/component" = "controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn"               = module.lb_role[count.index].iam_role_arn
      "eks.amazonaws.com/sts-regional-endpoints" = "true"
    }
  }
}

resource "helm_release" "lb" {
  provider = helm.dev
  count      = length(var.env_names)
  depends_on = [kubernetes_service_account.service-account]
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  set {
    name  = "region"
    value = "us-east-1"
  }

  set {
    name  = "vpcId"
    value = module.vpc[count.index].vpc_id
  }

  set {
    name  = "image.repository"
    value = "602401143452.dkr.ecr.us-east-1.amazonaws.com/amazon/aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "clusterName"
    value = "${var.cluster_name}-${var.env_names[count.index]}"
  }
}

# ----------------------------------------------------------------------------------------------
# ArgoCD ---------------------------------------------------------------------------------------

# Dev ------------------------------------------------------------------------------------------
resource "kubectl_manifest" "dev_namespace" {
  provider = kubectl.dev
  depends_on         = [module.eks]
  for_each           = data.kubectl_file_documents.namespace.manifests
  yaml_body          = each.value
  override_namespace = "argocd"
}

resource "kubectl_manifest" "dev_argocd" {
  provider = kubectl.dev
  depends_on         = [kubectl_manifest.dev_namespace]
  for_each           = data.kubectl_file_documents.argocd.manifests
  yaml_body          = each.value
  override_namespace = "argocd"
}

resource "kubectl_manifest" "dev_api_application" {
  provider = kubectl.dev
  depends_on         = [kubectl_manifest.dev_argocd]
  for_each           = data.kubectl_file_documents.dev_api_application.manifests
  yaml_body          = each.value
  override_namespace = "argocd"
}

resource "kubectl_manifest" "dev_static_application" {
  provider = kubectl.dev
  depends_on         = [kubectl_manifest.argocd]
  for_each           = data.kubectl_file_documents.dev_static_application.manifests
  yaml_body          = each.value
  override_namespace = "argocd"
}

resource "kubectl_manifest" "dev_api_ingress" {
  provider = kubectl.dev
  depends_on         = [kubectl_manifest.dev_api_application]
  for_each           = data.kubectl_file_documents.api_ingress.manifests
  yaml_body          = each.value
  override_namespace = "apiapp"
}

resource "kubectl_manifest" "dev_static_ingress" {
  provider = kubectl.dev
  depends_on         = [kubectl_manifest.dev_static_application]
  for_each           = data.kubectl_file_documents.static_ingress.manifests
  yaml_body          = each.value
  override_namespace = "staticapp"
}

resource "kubectl_manifest" "dev_custom_html" {
  provider = kubectl.dev
  depends_on         = [kubectl_manifest.dev_static_application]
  for_each           = data.kubectl_file_documents.dev_custom_html_file.manifests
  yaml_body          = each.value
  override_namespace = "staticapp"
}

# Stage ----------------------------------------------------------------------------------------
resource "kubectl_manifest" "stage_namespace" {
  provider = kubectl.stage
  depends_on         = [module.eks]
  for_each           = data.kubectl_file_documents.namespace.manifests
  yaml_body          = each.value
  override_namespace = "argocd"
}

resource "kubectl_manifest" "stage_argocd" {
  provider = kubectl.stage
  depends_on         = [kubectl_manifest.namespace]
  for_each           = data.kubectl_file_documents.argocd.manifests
  yaml_body          = each.value
  override_namespace = "argocd"
}

resource "kubectl_manifest" "stage_api_application" {
  provider = kubectl.stage
  depends_on         = [kubectl_manifest.argocd]
  for_each           = data.kubectl_file_documents.stage_api_application.manifests
  yaml_body          = each.value
  override_namespace = "argocd"
}

resource "kubectl_manifest" "stage_static_application" {
  provider = kubectl.stage
  depends_on         = [kubectl_manifest.argocd]
  for_each           = data.kubectl_file_documents.stage_static_application.manifests
  yaml_body          = each.value
  override_namespace = "argocd"
}

resource "kubectl_manifest" "stage_api_ingress" {
  provider = kubectl.stage
  depends_on         = [kubectl_manifest.stage_api_application]
  for_each           = data.kubectl_file_documents.api_ingress.manifests
  yaml_body          = each.value
  override_namespace = "apiapp"
}

resource "kubectl_manifest" "stage_static_ingress" {
  provider = kubectl.stage
  depends_on         = [kubectl_manifest.stage_static_application]
  for_each           = data.kubectl_file_documents.static_ingress.manifests
  yaml_body          = each.value
  override_namespace = "staticapp"
}

resource "kubectl_manifest" "stage_custom_html" {
  provider = kubectl.stage
  depends_on         = [kubectl_manifest.stage_static_application]
  for_each           = data.kubectl_file_documents.stage_custom_html_file.manifests
  yaml_body          = each.value
  override_namespace = "staticapp"
}


# Production -----------------------------------------------------------------------------------
/*resource "kubectl_manifest" "production_namespace" {
  provider = kubectl.production
  depends_on         = [module.eks]
  for_each           = data.kubectl_file_documents.namespace.manifests
  yaml_body          = each.value
  override_namespace = "argocd"
}

resource "kubectl_manifest" "production_argocd" {
  provider = kubectl.production
  depends_on         = [kubectl_manifest.namespace]
  for_each           = data.kubectl_file_documents.argocd.manifests
  yaml_body          = each.value
  override_namespace = "argocd"
}

resource "kubectl_manifest" "production_api_application" {
  provider = kubectl.production
  depends_on         = [kubectl_manifest.argocd]
  for_each           = data.kubectl_file_documents.api_application.manifests
  yaml_body          = each.value
  override_namespace = "argocd"
}

resource "kubectl_manifest" "production_static_application" {
  provider = kubectl.production
  depends_on         = [kubectl_manifest.argocd]
  for_each           = data.kubectl_file_documents.static_application.manifests
  yaml_body          = each.value
  override_namespace = "argocd"
}

resource "kubectl_manifest" "production_api_ingress" {
  provider = kubectl.production
  depends_on         = [kubectl_manifest.production_api_application]
  for_each           = data.kubectl_file_documents.api_ingress.manifests
  yaml_body          = each.value
  override_namespace = "apiapp"
}

resource "kubectl_manifest" "production_static_ingress" {
  provider = kubectl.production
  depends_on         = [kubectl_manifest.production_static_application]
  for_each           = data.kubectl_file_documents.static_ingress.manifests
  yaml_body          = each.value
  override_namespace = "staticapp"
}

resource "kubectl_manifest" "production_custom_html" {
  provider = kubectl.production
  depends_on         = [kubectl_manifest.production_static_application]
  for_each           = data.kubectl_file_documents.production_custom_html_file.manifests
  yaml_body          = each.value
  override_namespace = "staticapp"
}*/