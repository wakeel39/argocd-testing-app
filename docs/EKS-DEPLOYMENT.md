# Deploy argocdnodejsapp on AWS EKS (Boston / East Coast and Security)

This guide explains how to deploy the application on **Amazon EKS** with a **load balancer**, **horizontal scaling**, and the **security measures** we apply. You can use the same setup for a **Boston (East Coast) server** by choosing the `us-east-1` region (N. Virginia is the closest AWS region to Boston).

---

## Table of contents

1. [Architecture overview](#1-architecture-overview)
2. [Prerequisites](#2-prerequisites)
3. [Terraform: what each file does](#3-terraform-what-each-file-does)
4. [Deploy infrastructure (EKS, VPC, Load Balancer Controller)](#4-deploy-infrastructure-eks-vpc-load-balancer-controller)
5. [Security measures](#5-security-measures)
6. [Load balancer (ALB)](#6-load-balancer-alb)
7. [Horizontal scaling (HPA)](#7-horizontal-scaling-hpa)
8. [Deploy the application](#8-deploy-the-application)
9. [Boston / East Coast (region)](#9-boston--east-coast-region)
10. [Checks and operations](#10-checks-and-operations)

---

## 1. Architecture overview

- **VPC**: Private and public subnets in multiple AZs; NAT gateway for outbound traffic from private subnets.
- **EKS**: Kubernetes control plane and managed node group in private subnets.
- **AWS Load Balancer Controller**: Runs in the cluster; creates an **Application Load Balancer (ALB)** when you create an Ingress with `className: alb`.
- **Application**: Deployed via Helm (or Argo CD); **HorizontalPodAutoscaler (HPA)** scales pods on CPU/memory; **Service** type NodePort (or ClusterIP) behind the Ingress/ALB.

```
Internet → ALB (public subnets) → Ingress → Service → Pods (private subnets)
                                        ↑
                              HPA scales Pod count
```

---

## 2. Prerequisites

- **AWS CLI** installed and configured (`aws configure`) with credentials that can create VPC, EKS, IAM.
- **kubectl** installed.
- **Terraform** >= 1.0.
- **Helm** 3.x (if you deploy the app with Helm).

---

## 3. Terraform: what each file does

All Terraform files are under **`terraform/`**.

| File | Purpose |
|------|--------|
| **versions.tf** | Terraform and provider version constraints (AWS, Kubernetes, Helm). Optional S3 backend for state. |
| **variables.tf** | Inputs: region, environment, cluster name, VPC CIDR, node min/max/desired, instance types, encryption and endpoint options, tags. |
| **vpc.tf** | VPC with public and private subnets in 3 AZs; NAT gateway; tags for EKS and load balancers. |
| **eks.tf** | EKS cluster and managed node group; KMS for secret encryption; IRSA; IMDSv2 for nodes. |
| **load-balancer-controller.tf** | IRSA role for AWS Load Balancer Controller; Helm release that installs the controller in `kube-system`. |
| **providers.tf** | AWS provider; Kubernetes and Helm providers wired to the EKS cluster (after it exists). |
| **outputs.tf** | Cluster name, endpoint, `update-kubeconfig` command, VPC and subnet IDs. |
| **main.tf** | Placeholder / entry point. |

**Boston / East Coast:** Set **`aws_region = "us-east-1"`** in variables or a `.tfvars` file so the cluster and load balancer run in the region closest to Boston.

---

## 4. Deploy infrastructure (EKS, VPC, Load Balancer Controller)

From the repo root:

```bash
cd terraform
terraform init
terraform plan -var-file=terraform.tfvars   # optional
terraform apply -var-file=terraform.tfvars  # or -auto-approve
```

Example **terraform.tfvars** (Boston / East Coast, small prod-like setup):

```hcl
aws_region   = "us-east-1"
environment  = "prod"
cluster_name = "argocdnodejsapp-eks"

node_desired_size = 2
node_min_size     = 1
node_max_size     = 5
node_instance_types = ["t3.medium"]

enable_cluster_encryption = true
enable_private_endpoint   = false  # set true if you use VPN/private access only

tags = {
  Team = "platform"
}
```

After apply:

- Configure kubectl:  
  `aws eks update-kubeconfig --region us-east-1 --name argocdnodejsapp-eks`
- Verify nodes:  
  `kubectl get nodes`

The **AWS Load Balancer Controller** is installed by Terraform; it will create an ALB when you deploy an Ingress with `alb` class (see below).

---

## 5. Security measures

These are the security controls we use and how they are applied.

| Measure | Where / How |
|--------|-------------|
| **Secrets encryption** | EKS control plane: KMS envelope encryption for Kubernetes Secrets (`enable_cluster_encryption` / `create_kms_key` in `eks.tf`). |
| **IMDSv2 only** | Node group `metadata_options`: `http_tokens = "required"` so only IMDSv2 is used (reduces SSRF risk). |
| **Private subnets for nodes** | Worker nodes run in private subnets; no direct internet. Outbound via NAT. |
| **IRSA (IAM Roles for Service Accounts)** | Load Balancer Controller uses an IAM role via IRSA; no long-lived access keys in the cluster. |
| **Least privilege for LB controller** | Terraform attaches only the AWS Load Balancer Controller policy to the IRSA role. |
| **Restrictive EKS endpoint (optional)** | `enable_private_endpoint = true` in prod so the API is only reachable from your VPC (e.g. VPN). |
| **Network** | VPC and security groups managed by Terraform; EKS module sets up node and cluster security groups. |
| **Pod resources** | In Helm `values`: `resources.requests` and `limits` set so the scheduler and HPA can work and no single pod can overuse the node. |

You can add more later (e.g. Pod Security Standards/Admission, network policies, image scanning) without changing the structure of this doc.

---

## 6. Load balancer (ALB)

- **What:** An **Application Load Balancer (ALB)** in front of the app. It is created by the **AWS Load Balancer Controller** when an Ingress with `ingressClassName: alb` exists.
- **Where:** Terraform installs the controller in **load-balancer-controller.tf**. The ALB is created in the **public subnets** (they are tagged for ELB).
- **How (Helm):** In `helm-chart/values.yaml` set:

```yaml
ingress:
  enabled: true
  className: nginx   # or alb
  alb:
    enabled: true
    scheme: internet-facing
    sslRedirect: true
```

Then install/upgrade the Helm chart; the controller will create the ALB and target the app’s Service. The Ingress template uses `ingressClassName: alb` when `ingress.alb.enabled` is true.

- **DNS:** Point your domain (e.g. Boston office or public URL) to the ALB’s DNS name (shown in AWS Console or `kubectl get ingress` after the ALB is created).

---

## 7. Horizontal scaling (HPA)

- **What:** **HorizontalPodAutoscaler** scales the number of pod replicas between a min and max based on CPU and/or memory.
- **Where:** Helm chart **templates/hpa.yaml** (and **values.yaml**).
- **How:** In `values.yaml`:

```yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80
```

- **Why:** So under load the application scales out; when load drops it scales back within min/max. EKS node group also autoscales (Terraform `node_min_size` / `node_max_size`) so enough nodes exist for the HPA to schedule pods.

---

## 8. Deploy the application

After EKS and the Load Balancer Controller are up:

**Option A – Helm (from repo root):**

```bash
# Create namespace if needed
kubectl create namespace sardar --dry-run=client -o yaml | kubectl apply -f -

# Install with ALB and HPA enabled
helm upgrade --install argocdnodejsapp ./helm-chart \
  --namespace sardar \
  --set image.tag=1.0.1 \
  --set ingress.alb.enabled=true \
  --set autoscaling.enabled=true
```

**Option B – Argo CD:** Point the Argo CD Application at this repo, path **helm-chart**, and use the same values (e.g. in an Argo CD values file or Helm values in the Application spec). The GitHub Actions workflow can still sync from a temp copy with the new image tag; for EKS you’d set `ingress.alb.enabled=true` and `autoscaling.enabled=true` in that copy or in Argo CD.

---

## 9. Boston / East Coast (region)

- **Boston** does not have an AWS region; the closest is **us-east-1 (N. Virginia)**. Use it for “Boston server” or “East Coast”.
- Set in Terraform:

  **variables.tf** default or **terraform.tfvars**:

  ```hcl
  aws_region = "us-east-1"
  ```

- All resources (VPC, EKS, ALB) will be in that region. For lower latency from Boston, prefer **us-east-1** over us-west-2 or eu regions.

---

## 10. Checks and operations

- **Terraform**
  - `terraform plan` / `terraform apply` only when you intend to change infra.
  - Keep state in a safe backend (e.g. S3 + DynamoDB) for production; see **versions.tf** comments.

- **EKS / kubectl**
  - `kubectl get nodes`
  - `kubectl get pods -n sardar`
  - `kubectl get ingress -n sardar` (see ALB hostname when ALB Ingress is used)
  - `kubectl get hpa -n sardar`

- **Security**
  - Confirm KMS key exists for the cluster (AWS Console → EKS → cluster → Configuration).
  - Confirm node group has IMDSv2 required (EC2 → Launch templates used by the node group).
  - Prefer `enable_private_endpoint = true` in production and access API via VPN/bastion.

- **Load balancer**
  - In AWS Console → EC2 → Load Balancers, find the ALB created by the controller; check listeners and target health.
  - If the Ingress stays “pending”, check the controller logs: `kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller`.

- **HPA**
  - `kubectl get hpa -n sardar -w` to watch scaling.
  - Generate load (e.g. simple HTTP loop) and confirm replica count and metrics (e.g. `kubectl top pods -n sardar` if metrics-server is installed).

---

## Summary

| Item | Where | Purpose |
|------|--------|--------|
| **EKS + VPC** | Terraform (`vpc.tf`, `eks.tf`) | Cluster and network in your chosen region (e.g. us-east-1 for Boston). |
| **Security** | EKS encryption, IMDSv2, IRSA, private subnets, optional private API | Reduce risk and follow good practices. |
| **Load balancer** | Terraform (controller) + Helm (Ingress with `alb`) | ALB in front of the app. |
| **Horizontal scaling** | Helm chart (HPA) + EKS node group size | Scale pods and nodes with load. |
| **Application** | Helm or Argo CD from `helm-chart/` | Deploy and update the app with the same values (image tag, ALB, HPA). |

All of this is intended to be declarative (Terraform + Helm/Argo CD) and documented in this file so you can deploy and operate the application on EKS (including for a “Boston server” in us-east-1) with load balancer and horizontal scaling under the described security measures.
