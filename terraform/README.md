# Terraform for EKS (argocdnodejsapp)

Creates VPC, EKS cluster, and AWS Load Balancer Controller. See [../docs/EKS-DEPLOYMENT.md](../docs/EKS-DEPLOYMENT.md) for full documentation and security measures.

## Quick start

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars (region, cluster name, node sizes)

terraform init
terraform plan
terraform apply
```

## Two-stage apply (recommended)

The Kubernetes/Helm providers depend on the EKS cluster. If the first apply fails on the Helm release, run:

```bash
# Stage 1: VPC + EKS only
terraform apply -target=module.vpc -target=module.eks

# Stage 2: Load Balancer Controller (needs cluster)
terraform apply
```

Then configure kubectl:

```bash
aws eks update-kubeconfig --region <your-region> --name <cluster_name>
```

## Boston / East Coast

Set `aws_region = "us-east-1"` in `terraform.tfvars` to run the cluster in the region closest to Boston.

## Outputs

After apply, use `terraform output` to see cluster name and the `configure_kubectl` command.
