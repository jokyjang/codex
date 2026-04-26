provider "oci" {
  region = var.region
}

resource "oci_core_vcn" "this" {
  cidr_block     = var.vcn_cidr
  compartment_id = var.compartment_id
  display_name   = "${var.project_name}-vcn"
  dns_label      = "okedemovcn"
}

resource "oci_core_internet_gateway" "this" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.project_name}-igw"
  is_enabled     = true
}

resource "oci_core_nat_gateway" "this" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.project_name}-nat"
}

resource "oci_core_route_table" "public" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.project_name}-public-rt"

  route_rules {
    network_entity_id = oci_core_internet_gateway.this.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}

resource "oci_core_route_table" "private" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.project_name}-private-rt"

  route_rules {
    network_entity_id = oci_core_nat_gateway.this.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}

resource "oci_core_security_list" "oke_endpoint" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.project_name}-endpoint-sl"

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      min = 6443
      max = 6443
    }
  }
}

resource "oci_core_security_list" "workers" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.project_name}-workers-sl"

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

  ingress_security_rules {
    protocol = "all"
    source   = var.worker_subnet_cidr
  }

  ingress_security_rules {
    protocol = "all"
    source   = var.oke_endpoint_subnet_cidr
  }
}

resource "oci_core_security_list" "fss" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.project_name}-fss-sl"

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

  ingress_security_rules {
    protocol = "6"
    source   = var.worker_subnet_cidr

    tcp_options {
      min = 111
      max = 111
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = var.worker_subnet_cidr

    tcp_options {
      min = 2048
      max = 2050
    }
  }
}

resource "oci_core_subnet" "oke_endpoint" {
  cidr_block                 = var.oke_endpoint_subnet_cidr
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.this.id
  display_name               = "${var.project_name}-endpoint-subnet"
  dns_label                  = "okeendpoint"
  route_table_id             = oci_core_route_table.public.id
  security_list_ids          = [oci_core_security_list.oke_endpoint.id]
  prohibit_public_ip_on_vnic = false
}

resource "oci_core_subnet" "workers" {
  cidr_block                 = var.worker_subnet_cidr
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.this.id
  display_name               = "${var.project_name}-workers-subnet"
  dns_label                  = "okeworkers"
  route_table_id             = oci_core_route_table.private.id
  security_list_ids          = [oci_core_security_list.workers.id]
  prohibit_public_ip_on_vnic = true
}

resource "oci_core_subnet" "fss" {
  cidr_block                 = var.fss_subnet_cidr
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.this.id
  display_name               = "${var.project_name}-fss-subnet"
  dns_label                  = "fsssubnet"
  route_table_id             = oci_core_route_table.private.id
  security_list_ids          = [oci_core_security_list.fss.id]
  prohibit_public_ip_on_vnic = true
}

resource "oci_containerengine_cluster" "this" {
  compartment_id     = var.compartment_id
  kubernetes_version = var.kubernetes_version
  name               = "${var.project_name}-cluster"
  vcn_id             = oci_core_vcn.this.id

  endpoint_config {
    is_public_ip_enabled = true
    subnet_id            = oci_core_subnet.oke_endpoint.id
  }

  options {
    service_lb_subnet_ids = [oci_core_subnet.oke_endpoint.id]

    add_ons {
      is_kubernetes_dashboard_enabled = false
      is_tiller_enabled               = false
    }

    kubernetes_network_config {
      pods_cidr     = "10.244.0.0/16"
      services_cidr = "10.96.0.0/16"
    }
  }
}

resource "oci_containerengine_node_pool" "this" {
  cluster_id         = oci_containerengine_cluster.this.id
  compartment_id     = var.compartment_id
  kubernetes_version = var.kubernetes_version
  name               = "${var.project_name}-np"
  node_shape         = var.node_shape

  node_config_details {
    placement_configs {
      availability_domain = var.availability_domain
      subnet_id           = oci_core_subnet.workers.id
    }

    size = var.node_pool_size
  }

  node_shape_config {
    ocpus         = var.node_ocpus
    memory_in_gbs = var.node_memory_in_gbs
  }

  node_source_details {
    image_id    = var.node_image_id
    source_type = "IMAGE"
  }

  ssh_public_key = var.ssh_public_key
}

resource "oci_file_storage_file_system" "this" {
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_id
  display_name        = "${var.project_name}-fs"
}

resource "oci_file_storage_mount_target" "this" {
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_id
  subnet_id           = oci_core_subnet.fss.id
  display_name        = "${var.project_name}-mt"
}

resource "oci_file_storage_export" "this" {
  export_set_id  = oci_file_storage_mount_target.this.export_set_id
  file_system_id = oci_file_storage_file_system.this.id
  path           = var.nfs_export_path

  export_options {
    source                         = var.worker_subnet_cidr
    access                         = "READ_WRITE"
    identity_squash                = "NONE"
    require_privileged_source_port = false
  }
}

data "oci_core_private_ip" "fss_mount_target" {
  private_ip_id = oci_file_storage_mount_target.this.private_ip_ids[0]
}

data "oci_containerengine_cluster_kube_config" "this" {
  cluster_id    = oci_containerengine_cluster.this.id
  token_version = "2.0.0"

  depends_on = [oci_containerengine_node_pool.this]
}

locals {
  kubeconfig = yamldecode(data.oci_containerengine_cluster_kube_config.this.content)
}

provider "kubernetes" {
  host                   = local.kubeconfig.clusters[0].cluster.server
  cluster_ca_certificate = base64decode(local.kubeconfig.clusters[0].cluster["certificate-authority-data"])
  token                  = local.kubeconfig.users[0].user.token
}

resource "kubernetes_namespace" "nfs_demo" {
  metadata {
    name = var.k8s_namespace
  }

  depends_on = [oci_containerengine_node_pool.this]
}

resource "kubernetes_persistent_volume" "nfs" {
  metadata {
    name = "${var.project_name}-pv"
  }

  spec {
    capacity = {
      storage = "50Gi"
    }

    access_modes                     = ["ReadWriteMany"]
    persistent_volume_reclaim_policy = "Retain"

    persistent_volume_source {
      nfs {
        server = data.oci_core_private_ip.fss_mount_target.ip_address
        path   = var.nfs_export_path
      }
    }
  }

  depends_on = [oci_file_storage_export.this]
}

resource "kubernetes_persistent_volume_claim" "nfs" {
  metadata {
    name      = "${var.project_name}-pvc"
    namespace = kubernetes_namespace.nfs_demo.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "50Gi"
      }
    }

    volume_name = kubernetes_persistent_volume.nfs.metadata[0].name
  }
}

resource "kubernetes_deployment" "app" {
  metadata {
    name      = "${var.project_name}-app"
    namespace = kubernetes_namespace.nfs_demo.metadata[0].name
    labels = {
      app = "nfs-demo"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "nfs-demo"
      }
    }

    template {
      metadata {
        labels = {
          app = "nfs-demo"
        }
      }

      spec {
        container {
          name  = "app"
          image = "nginx:1.27"

          port {
            container_port = 80
          }

          volume_mount {
            mount_path = "/usr/share/nginx/html"
            name       = "shared-data"
          }
        }

        container {
          name    = "writer"
          image   = "busybox:1.36"
          command = ["/bin/sh", "-c", "while true; do date > /data/index.html; sleep 10; done"]

          volume_mount {
            mount_path = "/data"
            name       = "shared-data"
          }
        }

        volume {
          name = "shared-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.nfs.metadata[0].name
          }
        }
      }
    }
  }
}
