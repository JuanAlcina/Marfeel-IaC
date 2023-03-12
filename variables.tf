# General variables --------------------------------------------------------
variable "profile" {
  type        = string
  description = "Profile used to deploy resources"
}

variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region used to deploy resources"
}

variable "env_names" {
  type        = list(string)
  default     = ["dev", "stage", "production"]
  description = "List of environments"
}

# VPC variables ------------------------------------------------------------
variable "vpc_name" {
  type        = string
  default     = "MarfeelVPC"
  description = "Name of AWS vpc"
}

variable "vpc_cidrs" {
  type        = list(string)
  default     = ["10.0.0.0/16", "10.1.0.0/16", "10.2.0.0/16"]
  description = "List of cidrs for each vpc"
}

variable "vpc_azs" {
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
  description = "List of available azs"
}

variable "vpc_private_subnets" {
  default = [
    ["10.0.1.0/24", "10.0.2.0/24"],
    ["10.1.1.0/24", "10.1.2.0/24"],
    ["10.2.1.0/24", "10.2.2.0/24"]
  ]
  description = "List of private subnets for each vpc"
}

variable "vpc_public_subnets" {
  default = [
    ["10.0.4.0/24", "10.0.5.0/24"],
    ["10.1.4.0/24", "10.1.5.0/24"],
    ["10.2.4.0/24", "10.2.5.0/24"]
  ]
  description = "List of public subnets for each vpc"
}

# EKS variables ------------------------------------------------------------
variable "cluster_name" {
  type        = string
  default     = "MarfeelEKS"
  description = "Name of the EKS cluster"
}

variable "cluster_version" {
  type        = string
  default     = "1.23"
  description = "K8s version in the cluster"
}

variable "instance_types" {
  type        = list(string)
  default     = ["m5.large"]
  description = "Instance type of the workers in the cluster"
}