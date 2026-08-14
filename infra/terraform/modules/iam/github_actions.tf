resource "aws_iam_role" "terraform_plan_role" {
  name = "terraform-plan-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.oidc_provider.arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:*"
          }
        }
      },
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "terraform_plan_readonly" {
  role       = aws_iam_role.terraform_plan_role.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_policy" "terraform_plan_state_access" {
  name = "${var.project_name}-terraform-plan-state-access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::${var.state_bucket_name}",
          "arn:aws:s3:::${var.state_bucket_name}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "terraform_plan_state_access" {
  role       = aws_iam_role.terraform_plan_role.name
  policy_arn = aws_iam_policy.terraform_plan_state_access.arn
}

#######################################################################

resource "aws_iam_role" "terraform_apply_role" {
  name = "terraform-apply-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.oidc_provider.arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:ref:refs/heads/${var.github_branch}"
          }
        }
      },
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_policy" "terraform_apply_permissions" {
  name = "${var.project_name}-terraform-apply-permissions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ManageNetworking"
        Effect   = "Allow"
        Action   = ["ec2:*"]
        Resource = ["*"]
      },
      {
        Sid      = "ManageEKS"
        Effect   = "Allow"
        Action   = ["eks:*"]
        Resource = ["*"]
      },
      {
        Sid    = "ManageIAM"
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:GetRole",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:PassRole",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:CreatePolicy",
          "iam:CreatePolicyVersion",
          "iam:DeletePolicy",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:ListPolicyVersions",
          "iam:CreateOpenIDConnectProvider",
          "iam:DeleteOpenIDConnectProvider",
          "iam:GetOpenIDConnectProvider",
          "iam:TagOpenIDConnectProvider",
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:GetInstanceProfile",
          "iam:ListInstanceProfilesForRole",
          "iam:ListRoles",
          "iam:ListPolicies",
          "iam:ListEntitiesForPolicy",
          "iam:ListPolicyTags",
          "iam:ListRoleTags",
          "iam:ListOpenIDConnectProviders",
          "iam:ListOpenIDConnectProviderTags",
          "iam:GetRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:PutRolePolicy",
          "iam:UpdateRole",
          "iam:UpdateRoleDescription",
          "iam:TagPolicy",
          "iam:UntagPolicy"
        ]
        Resource = ["*"]
      },
      {
        Sid    = "ManageECR"
        Effect = "Allow"
        Action = [
          "ecr:CreateRepository",
          "ecr:DeleteRepository",
          "ecr:DescribeRepositories",
          "ecr:PutImageScanningConfiguration",
          "ecr:PutImageTagMutability",
          "ecr:TagResource",
          "ecr:UntagResource",
          "ecr:ListTagsForResource"
        ]
        Resource = ["*"]
      },
      {
        Sid      = "ManageRDS"
        Effect   = "Allow"
        Action   = ["rds:*"]
        Resource = ["*"]
      },
      {
        Sid    = "ManageKMS"
        Effect = "Allow"
        Action = [
          "kms:CreateKey",
          "kms:DescribeKey",
          "kms:EnableKeyRotation",
          "kms:GetKeyPolicy",
          "kms:GetKeyRotationStatus",
          "kms:ListKeys",
          "kms:ListResourceTags",
          "kms:PutKeyPolicy",
          "kms:TagResource",
          "kms:UntagResource",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion"
        ]
        Resource = ["*"]
      },
      {
        Sid      = "ManageLogs"
        Effect   = "Allow"
        Action   = ["logs:*"]
        Resource = ["*"]
      },
      {
        Sid    = "ManageState"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.state_bucket_name}",
          "arn:aws:s3:::${var.state_bucket_name}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "terraform_apply_permissions" {
  role       = aws_iam_role.terraform_apply_role.name
  policy_arn = aws_iam_policy.terraform_apply_permissions.arn
}

########################################################################

resource "aws_iam_role" "docker_pipeline_role" {
  name = "docker-pipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.oidc_provider.arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:ref:refs/heads/${var.github_branch}"
          }
        }
      },
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_policy" "docker_pipeline_ecr_access" {
  name = "${var.project_name}-docker-pipeline-ecr-access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = ["*"]
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:ListImages",
          "ecr:GetAuthorizationToken"
        ]
        Resource = ["arn:aws:ecr:${var.aws_region}:${var.aws_account_id}:repository/${var.project_name}-*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "docker_pipeline_ecr_access" {
  role       = aws_iam_role.docker_pipeline_role.name
  policy_arn = aws_iam_policy.docker_pipeline_ecr_access.arn
}