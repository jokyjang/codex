# codex

Terraform infrastructure sample for OCI that provisions a minimal OKE environment with OCI File Storage (NFS) mounted into a containerized workload.

## What is included

- `infra/` runnable Terraform root module
- VCN, subnets, route tables, security lists, Internet/NAT gateways
- OKE cluster + node pool
- OCI File Storage file system + mount target + export
- Kubernetes namespace, PV/PVC, and Deployment that mounts NFS

## Quick start

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars
terraform init
terraform plan
terraform apply
```

For more details, see [`infra/README.md`](infra/README.md).
