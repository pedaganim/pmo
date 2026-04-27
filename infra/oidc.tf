import {
  to = aws_iam_openid_connect_provider.github
  id = "arn:aws:iam::967438331002:oidc-provider/token.actions.githubusercontent.com"
}

# --- GitHub OIDC Provider ---
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"] # GitHub's current thumbprint
}

# --- IAM Role for GitHub Actions ---
resource "aws_iam_role" "github_actions_role" {
  name = "github-actions-pmo-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" : "repo:pedaganim/pmo:*"
          }
        }
      }
    ]
  })
}

# --- Attach Policy to the Role ---
resource "aws_iam_role_policy" "github_actions_policy" {
  name   = "github-actions-pmo-policy"
  role   = aws_iam_role.github_actions_role.id
  policy = file("${path.module}/../deployment-iam-policy.json")
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions_role.arn
}
