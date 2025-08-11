module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "production-cluster"
  kubernetes_version = "1.33"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Managed Node Group Configuration
  eks_managed_node_groups = {
    main = {
      min_size       = 2
      max_size       = 5
      desired_size   = 3
      instance_types = ["t2.micro"] # Choose appropriate instance types
    }
  }

  # Enable control plane logs for production visibility
  enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  tags = {
    Project = "EKS-Production-Platform"
  }
}
