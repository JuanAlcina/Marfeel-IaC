# ----------------------------------------------------------------------------------------------
# AWS ------------------------------------------------------------------------------------------
provider "aws" {
  region  = var.region
  profile = var.profile
}

# ----------------------------------------------------------------------------------------------
# Kubernetes -----------------------------------------------------------------------------------
provider "kubernetes" {
  alias                  = "dev"
  host                   = module.dev_eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.dev_eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1"
    args        = ["eks", "get-token", "--cluster-name", "${var.cluster_name}-${var.env_names[0]}"]
    command     = "aws"
  }
}

provider "kubernetes" {
  alias                  = "stage"
  host                   = module.stage_eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.stage_eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1"
    args        = ["eks", "get-token", "--cluster-name", "${var.cluster_name}-${var.env_names[1]}"]
    command     = "aws"
  }
}

provider "kubernetes" {
  alias                  = "production"
  host                   = module.production_eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.production_eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1"
    args        = ["eks", "get-token", "--cluster-name", "${var.cluster_name}-${var.env_names[2]}"]
    command     = "aws"
  }
}

# ----------------------------------------------------------------------------------------------
# Kubectl --------------------------------------------------------------------------------------
provider "kubectl" {
  alias                  = "dev"
  apply_retry_count      = 2
  host                   = module.dev_eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.dev_eks.cluster_certificate_authority_data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", "${var.cluster_name}-${var.env_names[0]}"]
  }
}

provider "kubectl" {
  alias                  = "stage"
  apply_retry_count      = 2
  host                   = module.stage_eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.stage_eks.cluster_certificate_authority_data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", "${var.cluster_name}-${var.env_names[1]}"]
  }
}

provider "kubectl" {
  alias                  = "production"
  apply_retry_count      = 2
  host                   = module.production_eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.production_eks.cluster_certificate_authority_data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", "${var.cluster_name}-${var.env_names[2]}"]
  }
}

# ----------------------------------------------------------------------------------------------
# Helm -----------------------------------------------------------------------------------------
provider "helm" {
  alias = "dev"
  kubernetes {
    host                   = module.dev_eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.dev_eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1"
      args        = ["eks", "get-token", "--cluster-name", "${var.cluster_name}-${var.env_names[0]}"]
      command     = "aws"
    }
  }
}

provider "helm" {
  alias = "stage"
  kubernetes {
    host                   = module.stage_eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.stage_eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1"
      args        = ["eks", "get-token", "--cluster-name", "${var.cluster_name}-${var.env_names[1]}"]
      command     = "aws"
    }
  }
}

provider "helm" {
  alias = "production"
  kubernetes {
    host                   = module.production_eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.production_eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1"
      args        = ["eks", "get-token", "--cluster-name", "${var.cluster_name}-${var.env_names[2]}"]
      command     = "aws"
    }
  }
}