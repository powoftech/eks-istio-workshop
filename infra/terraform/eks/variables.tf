variable "aws_region" {
  description = "The AWS region where the EKS cluster will be created."
  type        = string
  default     = "us-east-2"
}

variable "vpc_name" {
  description = "The name of the VPC."
  type        = string
  default     = "eks-vpc"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "eks_cluster_name" {
  description = "The name of the EKS cluster."
  type        = string
  default     = "production-cluster"
  
}
