variable region {
    type = string
    description = "AWS region used to deploy resources"
}

variable profile {
    type = string
    description = "Profile used to deploy resources"
}

variable vpc_name {
    type = string
    default = "Marfeel-VPC"
    description = "Name of AWS vpc"
}

variable cluster_name {
    type = string
    default = "MarfeelEKS"
    description = "Name of the EKS cluster"
}