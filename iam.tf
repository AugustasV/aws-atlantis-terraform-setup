# Data source for current AWS account
data "aws_caller_identity" "current" {}

# EKS Admin IAM Role
resource "aws_iam_role" "eks_admin" {
  name = "${var.project_name}-eks-admin"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      }
    ]
  })
}

# EKS Read-Only IAM Role
resource "aws_iam_role" "eks_read_only" {
  name = "${var.project_name}-eks-read-only"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      }
    ]
  })
}

# IAM policy for EKS cluster access
resource "aws_iam_policy" "eks_describe_cluster" {
  name        = "${var.project_name}-eks-describe-cluster"
  description = "Policy to allow describing EKS clusters"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DescribeClusterAccess"
        Effect = "Allow"
        Action = ["eks:DescribeCluster"]
        Resource = "arn:aws:eks:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/${var.cluster_name}"
      }
    ]
  })
}

# Attach policy to both roles
resource "aws_iam_role_policy_attachment" "eks_admin_describe" {
  role       = aws_iam_role.eks_admin.name
  policy_arn = aws_iam_policy.eks_describe_cluster.arn
}

resource "aws_iam_role_policy_attachment" "eks_read_only_describe" {
  role       = aws_iam_role.eks_read_only.name
  policy_arn = aws_iam_policy.eks_describe_cluster.arn
}
