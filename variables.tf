# General variables --------------------------------------------------------
variable profile {
    type = string
    description = "Profile used to deploy resources"
}

variable region {
    type = string
    default = "us-east-1"
    description = "AWS region used to deploy resources"
}

# VPC and EKS variables ----------------------------------------------------
variable vpc_name {
    type = string
    default = "MarfeelVPC"
    description = "Name of AWS vpc"
}

variable cluster_name {
    type = string
    default = "MarfeelEKS"
    description = "Name of the EKS cluster"
}

variable cluster_version {
    type = string
    default = "1.24"
    description = "K8s version in the cluster"
}

variable "instance_types" {
    type = string
    default = "m5.large"
    description = "Instance type of the workers in the cluster"
}