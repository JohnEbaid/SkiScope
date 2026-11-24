# Persistent CI identity. Separate from ../ on purpose: these resources are free, and they
# must survive `terraform destroy` of the expensive stack (ALB, Fargate, RDS).

terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "github_repo" {
  type    = string
  default = "JohnEbaid/SkiScope"
}

variable "branch" {
  type    = string
  default = "master"
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Project   = "skiscope"
      ManagedBy = "terraform"
    }
  }
}

data "aws_caller_identity" "current" {}

# Tells AWS to trust identity tokens issued by GitHub Actions. No keys are ever stored in GitHub.
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

resource "aws_iam_role" "github_actions" {
  name = "skiscope-github-actions"

  # Only a workflow running on this repo's branch can assume the role. A fork or another
  # branch presents a different "sub" claim and is rejected by AWS.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:ref:refs/heads/${var.branch}"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "deploy" {
  name = "build-push-deploy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "EcrLogin"
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*" # this one action cannot be scoped to a repository
      },
      {
        Sid    = "PushToSkiscopeRepoOnly"
        Effect = "Allow"
        Action = [
          "ecr:DescribeRepositories",
          "ecr:BatchCheckLayerAvailability",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage",
          "ecr:BatchGetImage", # docker push HEADs the manifest before and after upload
        ]
        Resource = "arn:aws:ecr:${var.region}:${data.aws_caller_identity.current.account_id}:repository/skiscope"
      },
      {
        # Express Mode service ARNs are not known until the service exists, so scope to
        # this account and region. Only this one service exists in the account.
        Sid    = "RedeployService"
        Effect = "Allow"
        Action = [
          "ecs:ListServices",
          "ecs:DescribeServices",
          "ecs:DescribeExpressGatewayService",
          "ecs:UpdateExpressGatewayService",
        ]
        Resource = "arn:aws:ecs:${var.region}:${data.aws_caller_identity.current.account_id}:*"
      },
      {
        # An update registers a new task definition revision for the service
        Sid    = "TaskDefinitionRevisions"
        Effect = "Allow"
        Action = [
          "ecs:RegisterTaskDefinition",
          "ecs:DescribeTaskDefinition",
          "ecs:DeregisterTaskDefinition",
          "ecs:TagResource",
        ]
        Resource = "arn:aws:ecs:${var.region}:${data.aws_caller_identity.current.account_id}:task-definition/default-skiscope:*"
      },
      {
        # An update re-passes the service's roles to ECS; allow only our two roles, only to ECS
        Sid    = "PassOnlyTheEcsRoles"
        Effect = "Allow"
        Action = "iam:PassRole"
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/skiscope-ecs-execution",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/skiscope-ecs-infrastructure",
        ]
        Condition = {
          StringEquals = { "iam:PassedToService" = "ecs.amazonaws.com" }
        }
      },
    ]
  })
}

output "role_arn" {
  description = "Put this in the GitHub repo variable AWS_ROLE_ARN"
  value       = aws_iam_role.github_actions.arn
}
