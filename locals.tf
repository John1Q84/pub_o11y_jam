locals {
  name            = "eks-jam"
  region          = data.aws_region.current.name
  cluster_version = "1.29"
  vpc_cidr        = "10.0.0.0/16"
  azs             = slice(data.aws_availability_zones.available.names, 0, 3)

  node_group_name = "managed_ondemand"

  tags = {
    Terraform = "true"
    Event     = local.name
  }
  eks_addon_vpc_cni_version    = data.aws_eks_addon_version.vpc_cni_latest.version
  eks_addon_coredns_version    = data.aws_eks_addon_version.coredns_latest.version
  eks_addon_kube_proxy_version = data.aws_eks_addon_version.kube_proxy_latest.version
}
