# ----------------------------------------------------------------------------------------------
# General data ---------------------------------------------------------------------------------
data "aws_caller_identity" "current" {}

data "kubectl_file_documents" "namespace" {
  content = file("${path.module}/manifests/namespace.yaml")
}

data "kubectl_file_documents" "argocd" {
  content = file("${path.module}/manifests/install.yaml")
}

data "kubectl_file_documents" "api_ingress" {
  content = file("${path.module}/manifests/api_ingress.yaml")
}

data "kubectl_file_documents" "static_ingress" {
  content = file("${path.module}/manifests/static_ingress.yaml")
}

data "template_file" "api_app" {
  count    = length(var.env_names)
  template = file("${path.module}/manifests/api_app.yaml")
  vars = {
    env = "${var.env_names[count.index]}"
  }
}

data "template_file" "static_app" {
  count    = length(var.env_names)
  template = file("${path.module}/manifests/static_app.yaml")
  vars = {
    env = "${var.env_names[count.index]}"
  }
}

data "template_file" "custom_html" {
  count    = length(var.env_names)
  template = file("${path.module}/manifests/custom_html.yaml")
  vars = {
    env = "${var.env_names[count.index]}"
  }
}

# --------------------------------------------------------------------------
# Dev ----------------------------------------------------------------------
data "kubectl_file_documents" "dev_api_application" {
  content = data.template_file.api_app[0].rendered
}

data "kubectl_file_documents" "dev_static_application" {
  content = data.template_file.static_app[0].rendered
}

data "kubectl_file_documents" "dev_custom_html_file" {
  content = data.template_file.custom_html[0].rendered
}

# --------------------------------------------------------------------------
# Stage --------------------------------------------------------------------
data "kubectl_file_documents" "stage_api_application" {
  content = data.template_file.api_app[1].rendered
}

data "kubectl_file_documents" "stage_static_application" {
  content = data.template_file.static_app[1].rendered
}

data "kubectl_file_documents" "stage_custom_html_file" {
  content = data.template_file.custom_html[1].rendered
}

# --------------------------------------------------------------------------
# Production ---------------------------------------------------------------
data "kubectl_file_documents" "production_api_application" {
  content = data.template_file.api_app[2].rendered
}

data "kubectl_file_documents" "production_static_application" {
  content = data.template_file.static_app[2].rendered
}

data "kubectl_file_documents" "production_custom_html_file" {
  content = data.template_file.custom_html[2].rendered
}