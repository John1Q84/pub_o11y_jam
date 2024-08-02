terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.9.0" # 원하는 버전을 지정하세요
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.10.0" # Kubernetes 프로바이더도 필요할 수 있습니다
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = data.aws_region.current.name
  alias  = "default"
}


#provider "helm" {
#  kubernetes {
#    host                   = data.aws_eks_cluster.cluster.endpoint
#    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority)
#    exec {
#      api_version = "client.authentication.k8s.io/v1beta1"
#      args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.cluster.name]
#      command     = "aws"
#    }
#  }
#}

provider "helm" {
  kubernetes {
    host                   = data.terraform_remote_state.eks.outputs.cluster_endpoint
    cluster_ca_certificate = base64decode(data.terraform_remote_state.eks.outputs.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}


provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority)
  token                  = data.aws_eks_cluster_auth.cluster.token
}
