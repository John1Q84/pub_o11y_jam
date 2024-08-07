data "terraform_remote_state" "eks" {
  backend = "local"

  config = {
    path = "../terraform.tfstate"
  }
}

data "aws_eks_cluster" "cluster" {
  name = data.terraform_remote_state.eks.outputs.eks_cluster_name
}

