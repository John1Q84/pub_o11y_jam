terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.5.0" # 원하는 버전을 지정하세요
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.10.0" # Kubernetes 프로바이더도 필요할 수 있습니다
    }
  }
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

