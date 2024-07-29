output "region" {
  description = "Current region code"
  value       = data.aws_region.current.name
}

output "vpc_id" {
  description = "the VPC id"
  value       = module.vpc.vpc_id
}

output "eks_cluster_name" {
  description = "Name of eks cluster"
  #value       = module.eks_blueprints.eks_cluster_id
  value = module.eks.cluster_id
}

output "eks_oidc_provider_arn" {
  description = "ARN of EKS OIDC provider"
  value       = module.eks.oidc_provider_arn
}

output "eks_oidc_provider" {
  description = "url of EKS OIDC provider, with out 'https'"
  value       = module.eks.oidc_provider
}
