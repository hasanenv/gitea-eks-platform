# Self-Hosted Git Platform on Amazon EKS (Terraform, ArgoCD, Helm, GitHub Actions)
![AWS](https://img.shields.io/badge/AWS-EKS-orange)
![Kubernetes](https://img.shields.io/badge/Kubernetes-1.34-blue)
![Terraform](https://img.shields.io/badge/Terraform-IaC-purple)
![Helm](https://img.shields.io/badge/Helm-Package%20Manager-blue)
![Traefik](https://img.shields.io/badge/Traefik-Ingress-blue)
![Prometheus](https://img.shields.io/badge/Prometheus-Monitoring-orange)
![Grafana](https://img.shields.io/badge/Grafana-Observability-orange)
![ArgoCD](https://img.shields.io/badge/ArgoCD-GitOps-red)
![GitHub Actions](https://img.shields.io/badge/GitHub%20Actions-CI%2FCD-blue)
![Trivy](https://img.shields.io/badge/Trivy-Container%20Scanning-blue)
![Checkov](https://img.shields.io/badge/Checkov-IaC%20Security-green)
![OIDC](https://img.shields.io/badge/Security-OIDC%20%2F%20IRSA-green)

<p align="center">
  <img src="assets/eks-gitea.drawio.png" width="1200">
</p>

---

## Table of Contents
- [Overview](#overview)
- [Platform Demo](#platform-demo)
- [Design Priorities](#design-priorities)
- [Architecture Overview](#architecture-overview)
- [Repository Structure](#repository-structure)
- [GitOps Workflow](#gitops-workflow)
- [CI/CD Pipelines](#cicd-pipelines)
- [Observability](#observability)
- [Security](#security)
- [Key Technical Decisions](#key-technical-decisions)
- [Known Limitations and Future Improvements](#known-limitations-and-future-improvements)
- [Quick Start](#quick-start)

## Overview

A production-grade, self-hosted Git platform built on AWS EKS, deploying Gitea as an alternative to cloud-hosted services like GitHub. Designed for organisations that require data sovereignty, regulatory compliance, or cost control at scale, keeping source code within their own infrastructure rather than relying on a third-party platform.

Infrastructure is provisioned via Terraform and deployments are managed through ArgoCD using a GitOps approach. TLS certificates, DNS records, and container image scanning are all automated. Kubernetes provides automated self-healing, horizontal scalability, and rolling deployments that are significantly harder to achieve reliably on a single VM. EKS removes the operational burden of managing the control plane, allowing focus on the workloads rather than the infrastructure underneath.

## Platform Demo

<p align="center">
  <img src="assets/gitea_demo.gif" width="1100">
</p>

Gitea running on Amazon EKS, accessible over HTTPS at `gitea.hasanenv.co.uk` with a valid Let's Encrypt TLS certificate.

## Design Priorities

- Modular Terraform structure with one module per concern, making infrastructure easier to maintain, extend, and redeploy independently
- GitOps via ArgoCD with Git as the single source of truth, ensuring every cluster change is version controlled and auditable
- Fully automated TLS and DNS through cert-manager and ExternalDNS, removing the need for manual certificate or record management
- Security built in at every layer (see the [Security](#security) section)

## Architecture Overview

The platform runs across two Availability Zones within a custom VPC in eu-west-2.

**Networking**
- Public subnets host NAT Gateways and the internet-facing Network Load Balancer
- Private subnets host EKS worker nodes and RDS PostgreSQL
- All application traffic enters via the NLB and is routed internally by Traefik

**Ingress**
- The NLB handles incoming traffic at Layer 4, forwarding raw TCP to Traefik inside the cluster
- Traefik handles TLS termination and host-based routing via Kubernetes Ingress resources, keeping all routing config in Git rather than AWS

> [!NOTE]
> NLB was chosen over ALB so all routing configuration lives as Kubernetes-native Ingress resources in Git, keeping routing logic within Kubernetes and independent of AWS-specific ingress behaviour.

**Compute**
- EKS 1.34 with a managed node group running t3.medium **SPOT instances**
- Worker nodes run all platform components as Kubernetes pods via Helm charts, managed by ArgoCD

> [!NOTE]
> EKS 1.34 was the latest stable version at time of deployment. t3.medium was chosen for cost efficiency. A production deployment would require larger instance types depending on workload requirements.

> [!WARNING]
> SPOT instances were used to minimise cost during development and demonstration. For production, ON_DEMAND instances are recommended for nodes running stateful workloads, as SPOT reclamation can cause scheduling failures when EBS volumes are tied to a specific Availability Zone.

**Storage**
- RDS PostgreSQL (Multi-AZ) for Gitea application data
- EBS gp3 volumes for Git repository files and Valkey session persistence
- Valkey (Redis-compatible) for Gitea session management and caching

**DNS and TLS**
- Cloudflare manages DNS with ExternalDNS automatically creating records when Ingresses are deployed
- cert-manager issues and renews TLS certificates from Let's Encrypt via DNS01 challenge

## Repository Structure

```
gitea-eks-platform/
├── .github/
│   └── workflows/
│       ├── terraform.yml          # Terraform plan (PR) and apply (merge)
│       └── gitea-release.yml      # Trivy scan, ECR push, image tag update
├── assets/                        # Architecture diagram, screenshots, and demo GIF
├── infra/
│   ├── bootstrap/
│   │   ├── argocd.sh              # Bootstraps ArgoCD via Helm and creates ArgoCD Application manifests
│   │   ├── post-deploy.sh         # Creates Kubernetes secrets, StorageClass, and ClusterIssuer
│   │   └── values.yaml            # ArgoCD Helm values
│   ├── kubernetes/
│   │   ├── app/
│   │   │   └── gitea/             # Gitea Helm values
│   │   └── platform/
│   │       ├── argocd/            # ArgoCD Application manifests (gitea, traefik, cert-manager, aws-lbc, external-dns, monitoring)
│   │       ├── aws-lbc/           # AWS Load Balancer Controller values
│   │       ├── cert-manager/      # cert-manager values and ClusterIssuer
│   │       ├── external-dns/      # ExternalDNS values
│   │       ├── monitoring/        # Prometheus and Grafana values
│   │       └── traefik/           # Traefik values
│   └── terraform/
│       ├── bootstrap/             # S3 state bucket
│       ├── envs/prod/             # Entry point: wires all modules together, where terraform apply is run
│       └── modules/
│           ├── ecr/               # ECR repository
│           ├── eks/               # EKS cluster, node group, and KMS encryption
│           ├── iam/               # IRSA roles, GitHub Actions OIDC, IAM policies
│           ├── rds/               # RDS PostgreSQL instance and security group
│           └── vpc/               # VPC, subnets, NAT gateways, routing
├── .trivyignore                   # Accepted vulnerabilities with no fix at time of encounter
├── .gitignore
└── README.md
```

## GitOps Workflow

All cluster configuration is managed through ArgoCD using a GitOps approach. The Git repository is the single source of truth. Any change to the cluster goes through Git first.

ArgoCD continuously watches the repository and reconciles the cluster state to match what is defined in Git. If someone manually changes something in the cluster, ArgoCD will revert it on the next sync.

<p align="center">
  <img src="assets/argocd-ui.png" width="800">
</p>

**How it works**
- ArgoCD Application manifests in `infra/kubernetes/platform/argocd/` define what to deploy and where to pull it from
- Each application points at a Helm chart and a values file in this repository
- When a values file is updated and pushed to `main`, ArgoCD detects the change and redeploys the affected workload
- The Gitea release pipeline updates `infra/kubernetes/app/gitea/values.yaml` with the new image tag after a successful scan and push to ECR
- ArgoCD picks this up and redeploys Gitea with the new image

> [!NOTE]
> ArgoCD was bootstrapped manually using `infra/bootstrap/argocd.sh`. Once running, it manages its own configuration and all other platform components through GitOps.

## CI/CD Pipelines

Two pipelines run via GitHub Actions, both authenticating to AWS using OIDC to avoid stored long-lived credentials.

### Terraform Pipeline (`terraform.yml`)

Triggered on pull requests and pushes to `main` for any changes under `infra/terraform/`.

- **On pull request:** Checkov security scan and `terraform plan` only (no changes applied)
- **On merge to main:** Checkov scan, `terraform plan`, then `terraform apply`

This ensures infrastructure changes are reviewed and scanned before being applied.

<p align="center">
  <img src="assets/terraform-plan-pipeline.png" width="300">
  <img src="assets/terraform-apply-pipeline.png" width="300">
</p>
<p align="center">
  <img src="assets/pipeline-pr.png" width="600">
</p>

### Gitea Release Pipeline (`gitea-release.yml`)

Triggered manually via `workflow_dispatch` with a tag input (e.g. `1.27.1-rootless`).

- Pulls the specified Gitea image from Docker Hub
- Scans with Trivy. Pipeline fails on HIGH or CRITICAL vulnerabilities
- Pushes the scanned image to ECR
- Updates the image tag in `infra/kubernetes/app/gitea/values.yaml` and commits to `main`
- ArgoCD detects the Git change and redeploys Gitea using the new image from ECR

<p align="center">
  <img src="assets/gitea-release-pipeline.png" width="300">
</p>

> [!NOTE]
> Known vulnerabilities with no available fix are listed in `.trivyignore` with justification comments.

## Observability

The platform uses the kube-prometheus-stack Helm chart, deploying Prometheus and Grafana as ArgoCD-managed workloads.

- Prometheus scrapes metrics from cluster components automatically via the pre-configured ServiceMonitors included with kube-prometheus-stack
- Grafana provides pre-built Kubernetes dashboards out of the box, covering cluster resource usage, pod health, and network traffic
- Metrics are retained for 7 days

<p align="center">
  <img src="assets/grafana-dashboard.png" width="800">
</p>

## Security

**IAM and IRSA**
- Two dedicated IAM roles for GitHub Actions: `terraform-plan-role` (read-only, PRs) and `terraform-apply-role` (scoped write access, merge to main)
- Both use GitHub Actions OIDC for keyless authentication. No AWS credentials stored in GitHub
- AWS Load Balancer Controller and EBS CSI Driver each assume their own IAM role scoped to a specific Kubernetes service account via IRSA trust policy conditions

> [!NOTE]
> ExternalDNS and cert-manager do not use IRSA as they communicate with Cloudflare rather than AWS. They read their Cloudflare API token from a Kubernetes Secret.

**Container and IaC Scanning**
- Trivy scans container images before push to ECR. Pipeline fails on HIGH or CRITICAL findings
- Checkov scans Terraform before every apply. Misconfigurations are caught before infrastructure is provisioned
- Immutable ECR image tags prevent any image from being silently overwritten after scanning

**Secrets Management**
- No secrets committed to Git at any point
- Application secrets are stored as Kubernetes Secrets (Cloudflare API token, DB credentials, admin credentials)
- The RDS master password is generated and stored automatically in AWS Secrets Manager

**Rootless Gitea**
- Gitea runs as a non-root user using the official rootless image variant, reducing the impact of container-level privilege escalation and following the principle of least privilege

**KMS Encryption**
- Kubernetes Secrets are encrypted at rest using AWS KMS with automatic key rotation enabled

## Key Technical Decisions

### NLB over ALB

An NLB was chosen over an ALB so routing logic stays entirely within Kubernetes. With ALB, AWS LBC translates Ingress rules into AWS listener rules. The actual routing behaviour lives in AWS, not in Git, which means debugging requires checking both your Kubernetes config and what AWS generated from it. With NLB and Traefik, Traefik reads the Ingress resources directly. What is in Git is exactly what is routing traffic.

### Cloudflare for DNS

The domain was already registered and managed in Cloudflare. Attempts to delegate DNS to Route 53 were unsuccessful, so ExternalDNS was configured to use the Cloudflare provider directly. This also avoided introducing Route 53 as an additional service to manage.

### GitOps for image updates

The Gitea release pipeline commits the new image tag to Git and ArgoCD handles the redeployment, keeping Git as the single source of truth for what version is running in the cluster.

## Known Limitations and Future Improvements

- **Cluster Autoscaler** not configured. Node scaling requires manual intervention when pod capacity is exceeded or SPOT nodes are reclaimed
- **Separate node groups** for stateful and stateless workloads, with ON_DEMAND instances for pods with EBS volume dependencies, would prevent scheduling failures on SPOT reclamation
- **EKS version** will require upgrading as older versions reach end of support. Upgrade paths should be tested in a non-production environment first
- **VPC ID and RDS endpoint** must be manually updated in values files after each cluster rebuild. Automating this via Terraform pipeline outputs is a planned improvement
- **ClusterIssuer** is applied manually after cert-manager deploys. ArgoCD sync wave ordering would automate this but adds complexity
- **Kubernetes Secrets** are created manually via `post-deploy.sh`. External Secrets Operator would pull secrets directly from AWS Secrets Manager, removing the manual step entirely
- **Single region** deployment. A multi-region setup would improve resilience for production workloads
- **No destroy pipeline**. Infrastructure teardown is performed manually and requires cleaning up LBC-managed resources (NLB, security groups) that sit outside Terraform state

## Quick Start

### Prerequisites

- AWS account with appropriate permissions
- Terraform, `kubectl`, and `helm` installed
- Cloudflare account with a domain and API token (Zone Read + DNS Edit permissions)
- GitHub repository forked from this one

### 1. Bootstrap State Bucket

```bash
cd infra/terraform/bootstrap
terraform init
terraform apply
```

### 2. Configure GitHub Actions

Add the following to your repository under Settings > Secrets and Variables:

**Secrets:**
- `AWS_ACCOUNT_ID` (e.g. `123456789012`)
- `MY_REPO` (e.g. `hasanenv/gitea-eks-platform`)
- `AWS_REPO` (e.g. `gitea-eks-platform-gitea`)
- `CLUSTER_NAME` (e.g. `gitea-eks-cluster`)
- `DB_USERNAME` (e.g. `gitea_user`)
- `EKS_PUBLIC_ACCESS_CIDRS` (e.g. `1.2.3.4/32,5.6.7.8/32`)
- `STATE_BUCKET_NAME` (e.g. `gitea-eks-platform-terraform-state`)
- `VPC_CIDR` (e.g. `10.0.0.0/16`)
- `PUBLIC_SUBNETS` (e.g. `["10.0.1.0/24","10.0.2.0/24"]`)
- `PRIVATE_SUBNETS` (e.g. `["10.0.3.0/24","10.0.4.0/24"]`)

**Variables:**
- `AWS_REGION` (e.g. `eu-west-2`)
- `OWNER` (e.g. `your name`)
- `PROJECT_NAME` (e.g. `gitea-eks-platform`)
- `AZS` (e.g. `["eu-west-2a","eu-west-2b"]`)
- `DESIRED_SIZE` (e.g. `3`)
- `MAX_SIZE` (e.g. `5`)
- `MIN_SIZE` (e.g. `1`)
- `INSTANCE_TYPES` (e.g. `["t3.medium"]`)
- `CAPACITY_TYPE` (e.g. `SPOT`)
- `REPO_BRANCH` (e.g. `main`)
- `INSTANCE_CLASS` (e.g. `db.t3.micro`)

### 3. Bootstrap IAM Roles

The GitHub Actions pipeline cannot authenticate until the IAM roles exist. Apply them locally first using credentials with sufficient AWS permissions:

```bash
cd infra/terraform/envs/prod
terraform init
terraform apply -target=module.iam
```

### 4. Deploy Infrastructure

Push to `main` to trigger the Terraform pipeline. The pipeline will provision all remaining AWS infrastructure including VPC, EKS, RDS, and ECR.

> [!NOTE]
> EKS cluster creation takes approximately 15 minutes. RDS takes an additional 10-20 minutes.

### 5. Update Values Files

After the pipeline completes, update the following with the new cluster values:

- `infra/kubernetes/platform/aws-lbc/values.yaml` -- update `vpcId`
- `infra/kubernetes/app/gitea/values.yaml` -- update the RDS `HOST` endpoint

> [!IMPORTANT]
> The VPC ID and RDS endpoint change with every cluster rebuild. Skipping this step will prevent the NLB from being created and Gitea from connecting to the database.

Commit and push before proceeding:

```bash
git add .
git commit -m "fix: update VPC ID and RDS endpoint for new deployment"
git push
```

### 6. Configure kubectl

```bash
aws eks update-kubeconfig --region eu-west-2 --name gitea-eks-cluster
```

### 7. Bootstrap ArgoCD

```bash
bash infra/bootstrap/argocd.sh
```

Installs ArgoCD and registers all platform applications.

### 8. Run Post-Deploy Script

```bash
bash infra/bootstrap/post-deploy.sh
```

The script will prompt for:
- GitHub PAT (Contents: Read) - for ArgoCD to pull manifests from your private repo. Generate at GitHub > Settings > Developer settings > Fine-grained tokens
- Cloudflare API token - needs Zone Read and DNS Edit permissions. Generate in Cloudflare dashboard > My Profile > API Tokens
- RDS DB password - auto-generated by AWS and stored in Secrets Manager. Retrieve using the TIP below
- Gitea admin username and password - choose anything, this creates the first admin account on Gitea
- Grafana admin password - choose anything, this sets the Grafana login password

> [!TIP]
> Retrieve the RDS password with: `aws secretsmanager get-secret-value --secret-id $(aws secretsmanager list-secrets --region eu-west-2 --query "SecretList[0].ARN" --output text) --region eu-west-2 --query SecretString --output text`

### 9. Run the Gitea Release Pipeline

Trigger the `gitea-release` pipeline manually from GitHub Actions with a tag (e.g. `1.27.1-rootless`) to scan and push the Gitea image to ECR. ArgoCD will redeploy Gitea automatically once the image is available.

### 10. Verify

```bash
kubectl get applications -n argocd
kubectl get pods -A
```

All ArgoCD applications should show `Synced` and `Healthy` within a few minutes.

> [!NOTE]
> This project was built and tested on EKS 1.34. Newer Kubernetes versions may introduce breaking changes in Helm chart compatibility. Test against the target version before deploying.

---

If you find issues or have suggestions, feel free to open an issue or connect with me on [LinkedIn](https://www.linkedin.com/in/hasankamranenv/).
