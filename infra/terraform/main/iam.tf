# data "aws_iam_policy_document" "aws_load_balancer_controller" {
#   source_policy_documents = [file("${path.module}/iam_policy.json")]
# }

module "aws_load_balancer_controller_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.60.0"

  role_name                              = "aws-load-balancer-controller"
  attach_load_balancer_controller_policy = true // Uses the module's built-in policy which is kept up to date

  # This links the role to the OIDC provider of our EKS cluster
  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = local.tags
}
