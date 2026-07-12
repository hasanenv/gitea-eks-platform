resource "aws_iam_role" "load_balancer_controller_role" {
  name = "${var.project_name}-load-balancer-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = var.cluster_oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${var.cluster_oidc_issuer_url}:aud" = "sts.amazonaws.com"
            "${var.cluster_oidc_issuer_url}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_policy" "load_balancer_controller_policy" {
  name   = "${var.project_name}-load-balancer-controller-policy"
  policy = file("${path.module}/lbc_policy.json")
}

resource "aws_iam_role_policy_attachment" "load_balancer_controller_policy_attachment" {
  role       = aws_iam_role.load_balancer_controller_role.name
  policy_arn = aws_iam_policy.load_balancer_controller_policy.arn
}

########################################################################

resource "aws_iam_role" "external_dns_role" {
  name = "${var.project_name}-external-dns-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = var.cluster_oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${var.cluster_oidc_issuer_url}:aud" = "sts.amazonaws.com"
            "${var.cluster_oidc_issuer_url}:sub" = "system:serviceaccount:kube-system:external-dns"
          }
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_policy" "external_dns_policy" {
  name   = "${var.project_name}-external-dns-policy"
  policy = file("${path.module}/ed_policy.json")
}

resource "aws_iam_role_policy_attachment" "external_dns_policy_attachment" {
  role       = aws_iam_role.external_dns_role.name
  policy_arn = aws_iam_policy.external_dns_policy.arn
}

########################################################################

resource "aws_iam_role" "cert_manager_role" {
  name = "${var.project_name}-cert-manager-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = var.cluster_oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${var.cluster_oidc_issuer_url}:aud" = "sts.amazonaws.com"
            "${var.cluster_oidc_issuer_url}:sub" = "system:serviceaccount:cert-manager:cert-manager"
          }
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_policy" "cert_manager_policy" {
  name   = "${var.project_name}-cert-manager-policy"
  policy = file("${path.module}/cm_policy.json")
}

resource "aws_iam_role_policy_attachment" "cert_manager_policy_attachment" {
  role       = aws_iam_role.cert_manager_role.name
  policy_arn = aws_iam_policy.cert_manager_policy.arn
}

########################################################################

resource "aws_iam_role" "ebs_csi_driver_role" {
  name = "${var.project_name}-ebs-csi-driver-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = var.cluster_oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${var.cluster_oidc_issuer_url}:aud" = "sts.amazonaws.com"
            "${var.cluster_oidc_issuer_url}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          }
        }
      }
    ]
  })

  tags = local.common_tags

}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver_policy_attachment" {
  role       = aws_iam_role.ebs_csi_driver_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}