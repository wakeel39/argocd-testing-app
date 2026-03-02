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

On Windows, if `terraform apply -var-file=terraform.tfvars` fails with "cannot find the file specified", run `terraform apply` only (Terraform auto-loads `terraform.tfvars` from the current directory), or use: `terraform apply -var-file=".\terraform.tfvars"`.

## Free Tier

If you see **"instance type is not eligible for Free Tier"**, set `node_instance_types = ["t3.micro"]` in `terraform.tfvars` (already the default).

## Two-stage apply (if Helm reports "cluster unreachable")

The Kubernetes/Helm providers need the EKS cluster to be reachable. If the first apply fails on the Helm release with "cluster unreachable" or "provide credentials", either:

**Option A – target apply then full apply**

```bash
terraform apply -target=module.vpc -target=module.eks
aws eks update-kubeconfig --region <your-region> --name <cluster_name>
terraform apply
```

**Option B – disable LB controller for first apply**

In `terraform.tfvars` set `install_aws_load_balancer_controller = false`, then:

```bash
terraform apply
aws eks update-kubeconfig --region <your-region> --name <cluster_name>
```

Then set `install_aws_load_balancer_controller = true` and run `terraform apply` again.

## Boston / East Coast

Set `aws_region = "us-east-1"` in `terraform.tfvars` to run the cluster in the region closest to Boston.

## Outputs

After apply, use `terraform output` to see cluster name and the `configure_kubectl` command.
