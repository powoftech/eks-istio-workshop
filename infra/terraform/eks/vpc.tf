module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "eks-vpc"
  cidr = var.vpc_cidr

  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets = ["10.0.0.0/19", "10.0.32.0/19", "10.0.64.0/19"]
  public_subnets  = ["10.0.128.0/20", "10.0.144.0/20", "10.0.160.0/20"]

  enable_nat_gateway   = true
  single_nat_gateway   = false # Set to true to save costs in dev, false for prod HA
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}
