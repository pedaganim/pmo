# --- GitHub OIDC Provider (Using existing) ---
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
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
          Federated = data.aws_iam_openid_connect_provider.github.arn
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
