module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets = ["10.0.128.0/20", "10.0.144.0/20", "10.0.160.0/20"]
  public_subnets  = ["10.0.0.0/20", "10.0.16.0/20", "10.0.32.0/20"]

  # Single NAT Gateway for development
  # enable_nat_gateway     = true
  # single_nat_gateway     = true
  # one_nat_gateway_per_az = false

  # # One NAT Gateway per subnet for production
  # enable_nat_gateway     = true
  # single_nat_gateway     = false
  # one_nat_gateway_per_az = false

  enable_dns_hostnames = true
  enable_dns_support   = true
}
