output "vcn_id" {
  description = "VCN OCID."
  value       = oci_core_vcn.this.id
}

output "oke_cluster_id" {
  description = "OKE cluster OCID."
  value       = oci_containerengine_cluster.this.id
}

output "oke_node_pool_id" {
  description = "OKE node pool OCID."
  value       = oci_containerengine_node_pool.this.id
}

output "fss_file_system_id" {
  description = "OCI File Storage file system OCID."
  value       = oci_file_storage_file_system.this.id
}

output "fss_mount_target_ip" {
  description = "Private IP for the File Storage mount target."
  value       = data.oci_core_private_ip.fss_mount_target.ip_address
}

output "kubernetes_namespace" {
  description = "Namespace containing the demo deployment."
  value       = kubernetes_namespace.nfs_demo.metadata[0].name
}

output "deployment_name" {
  description = "Deployment that mounts OCI File Storage."
  value       = kubernetes_deployment.app.metadata[0].name
}
