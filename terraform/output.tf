output "region" {
  description = "Current region code"
  value       = data.aws_region.current.name
}

output "vpc_id" {
  description = "the VPC id"
  value       = module.vpc.vpc_id
}

output "eks_cluster_id" {
  description = "ID of eks cluster"
  value       = module.eks.cluster_id
}

output "eks_cluster_endpoint" {
  description = "ID of eks cluster"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_ca_data" {
  description = "ID of eks cluster"
  value       = module.eks.cluster_certificate_authority_data
}

output "eks_cluster_name" {
  description = "Name of the eks cluster"
  value       = module.eks.cluster_name
}

output "eks_oidc_provider_arn" {
  description = "ARN of EKS OIDC provider"
  value       = module.eks.oidc_provider_arn
}

output "eks_oidc_provider" {
  description = "url of EKS OIDC provider, with out 'https'"
  value       = module.eks.oidc_provider
}


output "lb_role_arn" {
  description = "ARN of LB role"
  value       = module.lb_role.iam_role_arn
}

output "lb_role_name" {
  description = "ARN of LB role"
  value       = module.lb_role.iam_role_name
}
