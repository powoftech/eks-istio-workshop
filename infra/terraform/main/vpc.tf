module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.0.1"

  name = "${local.name}-vpc"
  cidr = local.vpc_cidr

  azs                        = local.azs
  private_subnets            = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]      # /20
  public_subnets             = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)] # Public LB /24
  intra_subnets              = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 52)] # EKS interface /24
  database_subnets           = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 56)] # RDS / Elastic cache /24
  database_subnet_group_name = "${local.name}-subnet-group"

  # Single NAT Gateway for dev
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  # # One NAT Gateway per subnet for prod
  # enable_nat_gateway     = true
  # single_nat_gateway     = false
  # one_nat_gateway_per_az = false

  # enable_dns_hostnames = true
  # enable_dns_support   = true

  # Tags required by EKS
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
    # Tags subnets for Karpenter auto-discovery
    "karpenter.sh/discovery" = "${local.name}-eks"
  }

  tags = local.tags
}

module "vpc_vpc-endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "6.0.1"

  vpc_id = module.vpc.vpc_id

  endpoints = {
    "s3" = {
      service      = "s3"
      service_type = "Gateway"
      route_table_ids = flatten([
        module.vpc.intra_route_table_ids,
        module.vpc.private_route_table_ids,
        module.vpc.public_route_table_ids
      ])
      tags = { Name = "s3-vpc-endpoint" }
    }
  }

  tags = local.tags
}

