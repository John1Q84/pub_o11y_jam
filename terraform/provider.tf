terraform {
  required_version = ">= 1.3.8"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.30.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }

  }
}

provider "aws" {
  region = data.aws_region.current.name
  alias  = "default"
}

#provider "kubernetes" {
#  host                   = module.eks_blueprints.eks_cluster_endpoint
#  cluster_ca_certificate = base64decode(module.eks_blueprints.eks_cluster_certificate_authority_data)
#  token                  = data.aws_eks_cluster_auth.this.token
#}

provider "kubernetes" {
  #host                   = module.eks.cluster_endpoint
  host                   = data.eks.cluster.endpoint
  cluster_ca_certificate = base64decode(data.eks.cluster.ca_data)
  token                  = data.aws_eks_cluster_auth.this.token

}
provider "helm" {
  kubernetes {
    host                   = data.eks.cluster.endpoint
    cluster_ca_certificate = base64decode(data.eks.cluster.ca_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

provider "kubectl" {
  apply_retry_count      = 10
  host                   = data.eks.cluster.endpoint
  cluster_ca_certificate = base64decode(data.eks.cluster.ca_data)
  load_config_file       = false
  token                  = data.aws_eks_cluster_auth.this.token
}
