# ═══════════════════════════════════════════════════════════════════════════
# OIDC Module - Configures OIDC provider for IRSA (Learning #155)
# ═══════════════════════════════════════════════════════════════════════════

variable "cluster_name" {
  type = string
}

# Get cluster info
data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

# Get the OIDC thumbprint
data "tls_certificate" "cluster" {
  url = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

# Create IAM OIDC Provider (Learning #155: CRITICAL for IRSA)
resource "aws_iam_openid_connect_provider" "cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates[0].sha1_fingerprint]
  url             = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

# Outputs
output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.cluster.arn
}

output "oidc_provider_url" {
  value = aws_iam_openid_connect_provider.cluster.url
}
