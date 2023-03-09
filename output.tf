output "region" {
  description = "Current region code"
  value       = data.aws_region.current.name
}

output "vpc_id" {
  description = "the VPC id"
  value       = module.vpc.vpc_id
}
