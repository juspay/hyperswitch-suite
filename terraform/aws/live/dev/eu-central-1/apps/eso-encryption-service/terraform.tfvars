# Common tags
common_tags = {
  Project     = "hyperswitch"
  Environment = "dev"
  ManagedBy   = "terraform"
}

# OIDC Provider Configuration
# Replace with your EKS cluster's OIDC provider ARN
# Found in EKS cluster details under OIDC provider section
oidc_provider_arn = "arn:aws:iam::XXXXXXXXXXXX:oidc-provider/oidc.eks.REGION.amazonaws.com/id/XXXXXXXXXXXXXXXXXXXXXXXXXX"

# Customer managed policy ARNs (optional)
customer_managed_policy_arns = []