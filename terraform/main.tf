module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  #version = "~> 3.0"
  version = "5.9.0"

  name = local.name ## 모든 resource의 Name tag에 추가 됩니다.
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 10)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 100)]

  public_subnet_suffix  = "pub-sb"
  private_subnet_suffix = "priv-sb"

  enable_nat_gateway   = true
  create_igw           = true
  enable_dns_hostnames = true
  single_nat_gateway   = true

  manage_default_network_acl    = true
  default_network_acl_tags      = { Name = "${local.name}-default" }
  manage_default_route_table    = true
  default_route_table_tags      = { Name = "${local.name}-default" }
  manage_default_security_group = true
  default_security_group_tags   = { Name = "${local.name}-default" }


  ## subnet tagging for alb-controller
  private_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/internal-elb"     = 1
  }
  public_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/elb"              = 1
  }

  ## additional tags
  tags = local.tags

}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name                   = local.name
  cluster_version                = local.cluster_version
  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni    = {}
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_group_defaults = {
    instance_types = ["m6i.large"]
  }

  eks_managed_node_groups = {
    sample = {
      instance_types = ["m6i.large"]
      min_size       = 2
      max_size       = 5
      desired_size   = 5
    }
  }

  cluster_enabled_log_types   = [] ## Controle Plane monitoring 기능 모두 해제
  create_cloudwatch_log_group = false

  tags = {
    Terraform   = "true"
    Environment = "eks-jam"
  }
}

module "lb_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.41.0"

  role_name                              = "${local.name}-lb-irsa"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"] # namespace:serviceaccount
    }
  }
}

