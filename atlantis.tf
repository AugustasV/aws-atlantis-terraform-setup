# Kubernetes namespace for Atlantis
resource "kubernetes_namespace" "atlantis" {
  metadata {
    name = "atlantis"
  }
  
  depends_on = [module.eks]
}

# Kubernetes secret for GitHub credentials
resource "kubernetes_secret" "atlantis_github" {
  metadata {
    name      = "atlantis-github"
    namespace = kubernetes_namespace.atlantis.metadata[0].name
  }

  type = "Opaque"

  data = {
    token  = var.github_token
    secret = var.github_webhook_secret
  }
}

# Helm release for Atlantis
resource "helm_release" "atlantis" {
  name       = "atlantis"
  namespace  = kubernetes_namespace.atlantis.metadata[0].name
  repository = "https://runatlantis.github.io/helm-charts"
  chart      = "atlantis"
  version    = "5.2.0"

  values = [
    yamlencode({
      orgAllowlist = "github.com/${var.github_org}/*"
      
      github = {
        user   = var.atlantis_github_user
        token  = var.github_token
        secret = var.github_webhook_secret
      }

      service = {
        type = "LoadBalancer"
        port = 4528
      }
      ingress = {
        enabled = false
      }

      resources = {
        requests = {
          memory = "512Mi"
          cpu    = "250m"
        }
        limits = {
          memory = "1Gi"
          cpu    = "500m"
        }
      }

      volumeClaim = {
        enabled     = true
        dataStorage = "5Gi"
      }

      replicaCount = 1

      serviceAccount = {
        create = true
        name   = "atlantis"
      }

      defaultTFVersion = "1.8.0"

      environment = {
        ATLANTIS_DEFAULT_TF_VERSION = "1.8.0"
        ATLANTIS_REPO_ALLOWLIST     = "github.com/${var.github_org}/*"
        ATLANTIS_GITHUB_USER   = var.atlantis_github_user
        GITHUB_TOKEN  = var.github_token
        GITHUB_WEBHOOK_SECRET = var.github_webhook_secret
        GITHUB_ORG = var.github_org
      }

      # Configure AWS credentials for Atlantis
      aws = {
        credentials = ""
        config      = ""
      }

      # Security context
      statefulSet = {
        securityContext = {
          fsGroup    = 1000
          runAsUser  = 100
        }
      }

      containerSecurityContext = {
        allowPrivilegeEscalation = false
        readOnlyRootFilesystem   = false
        runAsNonRoot            = true
        runAsUser               = 100
        capabilities = {
          drop = ["ALL"]
        }
      }
    })
  ]

  depends_on = [
    module.eks,
    kubernetes_namespace.atlantis,
    kubernetes_secret.atlantis_github
  ]

  timeout = 600
}

# Service account for Atlantis with IAM role
module "atlantis_irsa" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${var.cluster_name}-atlantis-irsa"

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["atlantis:atlantis"]
    }
  }

  role_policy_arns = {
    policy = "arn:aws:iam::aws:policy/PowerUserAccess"
  }

  tags = {
    Environment = var.environment
  }
}

# Update service account with IAM role annotation
resource "kubernetes_annotations" "atlantis_service_account" {
  api_version = "v1"
  kind        = "ServiceAccount"
  
  metadata {
    name      = "atlantis"
    namespace = kubernetes_namespace.atlantis.metadata[0].name
  }
  
  annotations = {
    "eks.amazonaws.com/role-arn" = module.atlantis_irsa.iam_role_arn
  }
  
  depends_on = [helm_release.atlantis]
}