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
  value       = module.eks_blueprints.eks_cluster_id
}
