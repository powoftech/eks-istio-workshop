output "eks_cluster_name" {
  description = "The name of the EKS cluster."
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "The endpoint for your EKS Kubernetes API server."
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_oidc_provider_arn" {
  description = "The ARN of the OIDC Provider for IRSA."
  value       = module.eks.oidc_provider_arn
}
