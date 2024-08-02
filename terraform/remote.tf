data "terraform_remote_state" "eks" {
  backend = "local"

  config = {
    path = "./terraform.tfstate"
  }
}

data "eks" "cluster" {
  ca_data  = data.terraform_remote_state.eks.outputs.eks_cluster_ca_data
  endpoint = data.terraform_remote_state.eks.outputs.eks_cluster_endpoint

}

