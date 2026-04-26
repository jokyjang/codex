variable "compartment_id" {
  description = "Compartment OCID where all resources will be created."
  type        = string
}

variable "region" {
  description = "OCI region identifier, such as us-phoenix-1."
  type        = string
}

variable "availability_domain" {
  description = "Availability domain used by node pool and File Storage resources (for example: Uocm:PHX-AD-1)."
  type        = string
}

variable "kubernetes_version" {
  description = "OKE Kubernetes version for cluster and node pool."
  type        = string
  default     = "v1.29.1"
}

variable "node_shape" {
  description = "Compute shape for OKE worker nodes."
  type        = string
  default     = "VM.Standard.E4.Flex"
}

variable "node_ocpus" {
  description = "OCPUs for flex worker shape."
  type        = number
  default     = 2
}

variable "node_memory_in_gbs" {
  description = "Memory (GB) for flex worker shape."
  type        = number
  default     = 16
}

variable "node_image_id" {
  description = "Image OCID used for worker nodes."
  type        = string
}

variable "node_pool_size" {
  description = "Worker nodes in node pool."
  type        = number
  default     = 1
}

variable "ssh_public_key" {
  description = "SSH public key inserted into worker nodes."
  type        = string
}

variable "vcn_cidr" {
  description = "CIDR block for VCN."
  type        = string
  default     = "10.0.0.0/16"
}

variable "oke_endpoint_subnet_cidr" {
  description = "Public subnet CIDR for OKE API endpoint."
  type        = string
  default     = "10.0.0.0/24"
}

variable "worker_subnet_cidr" {
  description = "Private subnet CIDR for OKE worker nodes."
  type        = string
  default     = "10.0.1.0/24"
}

variable "fss_subnet_cidr" {
  description = "Private subnet CIDR for OCI File Storage mount target."
  type        = string
  default     = "10.0.2.0/24"
}

variable "project_name" {
  description = "Prefix for all resource names."
  type        = string
  default     = "oke-nfs-demo"
}

variable "nfs_export_path" {
  description = "Export path inside OCI File Storage."
  type        = string
  default     = "/appshare"
}

variable "k8s_namespace" {
  description = "Namespace that will host the demo workload."
  type        = string
  default     = "nfs-demo"
}
