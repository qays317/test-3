//=================================================================================================================
// OIDC provider
//=================================================================================================================

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}


//=================================================================================================================
// kubernetes-terraform-ci-role
//=================================================================================================================

resource "aws_iam_role" "terraform_ci" {
  name = "kubernetes-terraform-ci-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:YOUR_GITHUB_USERNAME/YOUR_REPO_NAME:*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "terraform_admin" {
  role = aws_iam_role.terraform_ci.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}


//=================================================================================================================
// kubernetes-deploy-app-ci-role
//=================================================================================================================

resource "aws_iam_role" "deploy_app_ci" {
  name = "kubernetes-deploy-app-ci-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:YOUR_GITHUB_USERNAME/YOUR_REPO_NAME:*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "deploy_app_policy" {
  name = "kubernetes-app-deploy-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "deploy_app_attach" {
  role = aws_iam_role.deploy_app_ci.name
  policy_arn = aws_iam_policy.deploy_app_policy.arn
}


