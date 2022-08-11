# ------------------------------
# providers
# ------------------------------
terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
      version = "4.87.0"
      #make sure to use the current provider
    }
  }
}

provider "oci" {
  region               = var.region
  tenancy_ocid         = var.tenancy_ocid
  user_ocid            = var.user_ocid
  fingerprint          = var.fingerprint
  private_key_path     = var.private_key_path
  private_key_password = var.private_key_password
}

provider "tls" {

}



# Generate the private and public key pair
resource "tls_private_key" "ssh_keypair" {
  algorithm = "RSA" # Required
  rsa_bits  = 2048  # Optional
}


#*************************************
#       NSGs for Heavy forwarder
#*************************************
locals {
  splunk_nsgs = {
  "splunk_hf_nsg" : {
    vcn_id : data.oci_core_subnet.splunk_hf_subnet.vcn_id
    defined_tags  : null
    freeform_tags : null
    ingress_rules : {
      admin-console-access-rule : {
        is_create : true
        description : "Admin Console Access to Splunk on port 8000"
        protocol    : "6"
        stateless   : false
        src_type    : "CIDR_BLOCK"
        src : "24.193.160.152/32"
        dst_port_max : 8000
        dst_port_min : 8000
        src_port_max : null
        src_port_min : null
        icmp_type : null
        icmp_code : null
      },
      remove-ssh-console-access-rule : {
        is_create : true
        description : "Admin Console Access to Splunk on port 8000"
        protocol    : "6"
        stateless   : false
        src_type    : "CIDR_BLOCK"
        src : "24.193.160.152/32"
        dst_port_max : 22
        dst_port_min : 22
        src_port_max : null
        src_port_min : null
        icmp_type : null
        icmp_code : null
      }
    }
    egress_rules : {
      heavy-forwarder-to-splunk-server-rule : {
        is_create : true
        description : "For log forwarder to Splunk Server at ${var.splunk_server_ip}."
        stateless : false
        protocol  : "6"
        dst_type : "CIDR_BLOCK"
        dst : "${var.splunk_server_ip}/32"
        dst_port_min : var.splunk_server_port
        dst_port_max : var.splunk_server_port 
        src_port_max : null
        src_port_min  : null
        icmp_type : null
        icmp_code : null
      },
      heavy-forwarder-to-internet-rule : {
        is_create : true
        description : "For log forwarder to download Splunk."
        stateless : false
        protocol  : "6"
        dst_type : "CIDR_BLOCK"
        dst : "0.0.0.0/0"
        dst_port_min : 443
        dst_port_max : 443
        src_port_max : null
        src_port_min  : null
        icmp_type : null
        icmp_code : null
      }
    }
  }}
}

module "lz_splunk_nsgs" {
  source         = "../cis-oci-landing-zone/modules/network/security"
  compartment_id = data.oci_core_subnet.splunk_hf_subnet.compartment_id
  nsgs           = local.splunk_nsgs

}






#*************************************
#           Compute Requirements
#*************************************

# ------------------------------
# SH Captain instance variables
# ------------------------------

# resource "oci_core_instance" "test_instance1" {
#   availability_domain = data.oci_identity_availability_domain.ad.name
#   compartment_id      = var.compartment_ocid
#   display_name        = "SHCaptain"
#   shape               = "VM.Standard2.1"
#   source_details {
#     source_type = "image"
#     source_id   = var.instance_image_ocid[var.region]
#   }
#   create_vnic_details {
#     subnet_id      = oci_core_subnet.splunk_subnet.id
#     assign_public_ip = false
#     hostname_label = "SHCaptain"
#   }

#   metadata = {
#    ssh_authorized_keys = var.generate_ssh_key_pair ? tls_private_key.ssh_keypair.public_key_openssh : var.ssh_public_key
#    user_data           = base64encode(join(
#         "\n",
#         [
#           "#!/usr/bin/env bash",
#           file("./scripts/bootstrap2.sh"),
#         ],
#       ),
#     )
#  }

#   extended_metadata = {
#     config = jsonencode(
#       {
#         "shape"        = "VM.Standard2.1"
#         "disk_count"   = var.manager_disk_count
#         "disk_size"    = var.manager_disk_size
#         "password"     = var.password
#         "sites_string" = var.sites_string
#       },
#     )
#   }
# }

# ------------------------------
# HF forwarder instance variables
# ------------------------------

resource "oci_core_instance" "HeavyForwarder" {
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = var.splunk_compartment_id
  display_name        = "HF Forwarder"
  shape               = "VM.Standard2.1"
  source_details {
    source_type = "image"
    source_id   = local.instance_image_ocid[var.region]
  }
  create_vnic_details {
    subnet_id      = var.splunk_hf_subnet_id
    hostname_label = "HeavyForwarder"
    nsg_ids = [module.lz_splunk_nsgs.nsgs["splunk_hf_nsg"].id]
  }

  metadata = {
   ssh_authorized_keys = var.ssh_public_key
   user_data           = base64encode(join(
        "\n",
        [
          "#!/usr/bin/env bash",
          file("./scripts/bootstrap.sh"),
        ],
      ),
    )
 }

  extended_metadata = {
    config = jsonencode(
      {
        "shape"         = "VM.Standard2.1"
        "disk_count"    = var.manager_disk_count
        "disk_size"     = var.manager_disk_size
        "password"      = var.splunk_hf_password
        "sites_string"  = var.sites_string
        "splunk_server" = "${var.splunk_server_ip}:${var.splunk_server_port}"
      },
    )
  }
}


# ------------------------------
# Indexer Cluster_Manager Instance
# ------------------------------

# resource "oci_core_instance" "test_instance7" {
#   availability_domain = data.oci_identity_availability_domain.ad.name
#   compartment_id      = var.compartment_ocid
#   display_name        = "Cluster_Manager"
#   shape               = "VM.Standard2.1"
#   source_details {
#     source_type = "image"
#     source_id   = var.instance_image_ocid[var.region]
#   }
#   create_vnic_details {
#     subnet_id      = oci_core_subnet.splunk_subnet.id
#     assign_public_ip = false
#   }
#   metadata = {
#    ssh_authorized_keys = var.generate_ssh_key_pair ? tls_private_key.ssh_keypair.public_key_openssh : var.ssh_public_key
#    user_data           = base64encode(join(
#         "\n",
#         [
#           "#!/usr/bin/env bash",
#           file("./scripts/bootstrap1.sh"),
#         ],
#       ),
#     )
#  }

#   extended_metadata = {
#     config = jsonencode(
#       {
#         "shape"        = "VM.Standard2.1"
#         "disk_count"   = var.manager_disk_count
#         "disk_size"    = var.manager_disk_size
#         "password"     = var.password
#         "sites_string" = var.sites_string
#       },
#     )
#   }
# }

# ------------------------------
# Indexer Instance
# ------------------------------

# resource "oci_core_instance" "indexer" {
#   display_name        = "indexer${count.index}"
#   compartment_id      = var.compartment_ocid
#   availability_domain = data.oci_identity_availability_domain.ad.name
#   shape               = "VM.Standard2.1"

#   source_details {
#     source_id   = var.instance_image_ocid[var.region]
#     source_type = "image"
#   }

#   create_vnic_details {
#     subnet_id      = oci_core_subnet.splunk_subnet.id
#     hostname_label = "indexer${count.index}"
#   }

#   metadata = {
#     ssh_authorized_keys = var.ssh_public_key
#     user_data = base64encode(
#       join(
#         "\n",
#         [
#           "#!/usr/bin/env bash",
#           file("./scripts/indexers.sh"),
#         ],
#       ),
#     )
#   }

#   extended_metadata = {
#     config = jsonencode(
#       {
#         "shape"            = var.instance_shape
#         "disk_count"       = var.indexer_count
#         "password"     = var.password
#         "sites_string" = var.sites_string
#         "count"            = count.index
#         "public_ip" = var.public_ip
#       },
#     )
#   }

#   count = var.indexer_count
# }




