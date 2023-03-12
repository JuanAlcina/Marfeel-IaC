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
  host                   = module.eks[0].cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks[0].cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1"
    args        = ["eks", "get-token", "--cluster-name", "${var.cluster_name}-${var.env_names[0]}"]
    command     = "aws"
  }
}

provider "kubernetes" {
  alias                  = "stage"
  host                   = module.eks[1].cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks[1].cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1"
    args        = ["eks", "get-token", "--cluster-name", "${var.cluster_name}-${var.env_names[1]}"]
    command     = "aws"
  }
}

/*provider "kubernetes" {
  alias                  = "production"
  host                   = module.eks[2].cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks[2].cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1"
    args        = ["eks", "get-token", "--cluster-name", "${var.cluster_name}-${var.env_names[2]}"]
    command     = "aws"
  }
}*/

# ----------------------------------------------------------------------------------------------
# Kubectl --------------------------------------------------------------------------------------
provider "kubectl" {
  alias                  = "dev"
  apply_retry_count      = 2
  host                   = module.eks[0].cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks[0].cluster_certificate_authority_data)
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
  host                   = module.eks[1].cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks[1].cluster_certificate_authority_data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", "${var.cluster_name}-${var.env_names[1]}"]
  }
}

/*provider "kubectl" {
  alias                  = "production"
  apply_retry_count      = 2
  host                   = module.eks[2].cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks[2].cluster_certificate_authority_data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", "${var.cluster_name}-${var.env_names[2]}"]
  }
}*/

# ----------------------------------------------------------------------------------------------
# Helm -----------------------------------------------------------------------------------------
provider "helm" {
  alias = "dev"
  kubernetes {
    host                   = module.eks[0].cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks[0].cluster_certificate_authority_data)
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
    host                   = module.eks[1].cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks[1].cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1"
      args        = ["eks", "get-token", "--cluster-name", "${var.cluster_name}-${var.env_names[1]}"]
      command     = "aws"
    }
  }
}

/*provider "helm" {
  alias = "production"
  kubernetes {
    host                   = module.eks[2].cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks[2].cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1"
      args        = ["eks", "get-token", "--cluster-name", "${var.cluster_name}-${var.env_names[2]}"]
      command     = "aws"
    }
  }
}*/