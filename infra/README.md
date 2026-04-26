# OCI OKE + NFS Terraform module

This folder is a runnable Terraform root module that creates:

1. A minimal VCN and required networking (subnets, route tables, security lists, gateways).
2. A minimal OKE cluster and node pool.
3. OCI File Storage (NFS) with mount target and export.
4. A Kubernetes deployment in OKE that mounts the NFS export through a PV/PVC.

## Prerequisites

- Terraform 1.5+
- OCI credentials configured for Terraform provider (env vars, config file, or instance principal)
- Permissions to create networking, OKE, and File Storage resources in the target compartment

## Usage

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars with your real OCIDs and SSH key
terraform init
terraform plan
terraform apply
```

After apply:

```bash
kubectl get pods -n nfs-demo
kubectl get pv,pvc -n nfs-demo
```

The deployment includes:
- `nginx` container serving files from the mounted NFS path.
- `busybox` sidecar updating `/data/index.html` every 10 seconds on the same NFS volume.

## Notes

- This module intentionally keeps the architecture minimal for demonstration purposes.
- Tighten CIDRs, security list rules, and tenancy IAM policies before production usage.
