data "aws_caller_identity" "current" {}

data "kubectl_file_documents" "namespace" {
  content = file("${path.module}/manifests/namespace.yaml")
}

data "kubectl_file_documents" "argocd" {
  content = file("${path.module}/manifests/install.yaml")
}

data "kubectl_file_documents" "application" {
  content = file("${path.module}/manifests/api_app.yaml")
}

data "kubectl_file_documents" "ingress" {
  content = file("${path.module}/manifests/ingress.yaml")
}