module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.0.8"

  name               = "${local.name}-cluster"
  kubernetes_version = "1.33"

  enable_cluster_creator_admin_permissions = true
  endpoint_public_access                   = true
  # cloudwatch_log_group_retention_in_days   = 365

  addons = {
    coredns = {
      most_recent = true
    }
    eks-pod-identity-agent = {
      most_recent    = true
      before_compute = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent    = true
      before_compute = true
    }
  }

  # security_group_additional_rules = {
  #   ingress_from_vpc_cidr = {
  #     description = "Allow all traffic from the VPC CIDR"
  #     from_port   = 0
  #     to_port     = 0
  #     protocol    = "-1"
  #     type        = "ingress"
  #     cidr_blocks = [local.vpc_cidr]
  #   }
  # }

  # kms_key_administrators = [
  #   tolist(data.aws_iam_roles.github.arns)[0],
  #   tolist(data.aws_iam_roles.administrator.arns)[0]
  # ]

  # kms_key_users = [
  #   tolist(data.aws_iam_roles.github.arns)[0],
  #   tolist(data.aws_iam_roles.administrator.arns)[0]
  # ]

  # access_entries = {
  #   administrator = {
  #     principal_arn = tolist(data.aws_iam_roles.administrator.arns)[0]
  #     policy_associations = {
  #       Admin = {
  #         policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  #         access_scope = {
  #           type = "cluster"
  #         }
  #       }
  #     }
  #   }
  #   github = {
  #     principal_arn = tolist(data.aws_iam_roles.github.arns)[0]
  #     policy_associations = {
  #       Admin = {
  #         policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  #         access_scope = {
  #           type = "cluster"
  #         }
  #       }
  #     }
  #   }
  # }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  # Enable control plane logs for production visibility
  # enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  eks_managed_node_groups = {
    system = {
      min_size     = 2
      max_size     = 3
      desired_size = 2

      instance_types = ["t3.medium"]

      # labels = {
      #   CriticalAddonsOnly        = "true"
      #   "karpenter.sh/controller" = "true"
      # }

      # taints = {
      #   addons = {
      #     key    = "CriticalAddonsOnly"
      #     value  = "true"
      #     effect = "NO_SCHEDULE"
      #   },
      # }

      # iam_role_additional_policies = {
      #   AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      # }
    }
  }

  iam_role_name   = "${local.name}-eks-cluster-role"
  create_iam_role = true

  # node_security_group_tags = merge(local.tags, {
  #   # NOTE - if creating multiple security groups with this module, only tag the
  #   # security group that Karpenter should utilize with the following tag
  #   # (i.e. - at most, only one security group should have this tag in your account)
  #   "karpenter.sh/discovery" = "${local.name}-cluster"
  # })

  tags = local.tags
}
