data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_eks_cluster_auth" "this" {
  name = data.terraform_remote_state.eks.outputs.eks_cluster_name
}
