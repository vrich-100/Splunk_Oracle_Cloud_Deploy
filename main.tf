#*************************************
#           TF  Environment
#*************************************

variable "secondary_vnic_count" {
  default = 1
}


variable "instance_image_ocid" {
  type = map(string)

  default = {
    # See https://docs.us-phoenix-1.oraclecloud.com/images/
    # Oracle-provided image "Oracle-Linux-7.5-2018.10.16-0"
    us-phoenix-1   = "ocid1.image.oc1.phx.aaaaaaaaoqj42sokaoh42l76wsyhn3k2beuntrh5maj3gmgmzeyr55zzrwwa"
    us-ashburn-1   = "ocid1.image.oc1.iad.aaaaaaaaj6pcmnh6y3hdi3ibyxhhflvp3mj2qad4nspojrnxc6pzgn2w3k5q"
    eu-frankfurt-1 = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaaitzn6tdyjer7jl34h2ujz74jwy5nkbukbh55ekp6oyzwrtfa4zma"
    uk-london-1    = "ocid1.image.oc1.uk-london-1.aaaaaaaa32voyikkkzfxyo4xbdmadc2dmvorfxxgdhpnk6dw64fa3l4jh7wa"
  }
}

locals {
  current_time                    = formatdate("YYYYMMDDhhmmss", timestamp())
  app_name                        = "splunk-oci-dev-kit"
  display_name                    = join("-", [local.app_name, local.current_time])
  compartment_name                = data.oci_identity_compartment.this.name
  #dynamic_group_tenancy_level     = "Allow dynamic-group ${oci_identity_dynamic_group.for_instance.name} to manage all-resources in tenancy"
  #dynamic_group_compartment_level = "Allow dynamic-group ${oci_identity_dynamic_group.for_instance.name} to manage all-resources in compartment ${local.compartment_name}"
}

# ------------------------------
# providers
# ------------------------------
terraform {
  required_providers {
    oci = {
      source = "hashicorp/oci"
      version = "4.37.0"
      #make sure to use the current provider
    }
  }
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  region           = var.region
}

provider "tls" {

}


#*************************************
#           Network Requirements
#*************************************

data "oci_identity_availability_domain" "ad" {
  compartment_id = var.tenancy_ocid
  ad_number      = 1
}

# ------------------------------
# virtual cloud network
# ------------------------------

resource "oci_core_vcn" "splunk_vcn" {
  cidr_block     = "10.0.0.0/16"
  compartment_id = var.compartment_ocid
  display_name   = "splunkvcn"
  dns_label      = "splunkvcn"

}

# ------------------------------
# subnet
# ------------------------------

resource "oci_core_subnet" "splunk_subnet" {
  availability_domain = data.oci_identity_availability_domain.ad.name
  cidr_block          = "10.0.1.0/24"
  display_name        = "SplunkSubnet"
  compartment_id      = var.compartment_ocid
  vcn_id              = oci_core_vcn.splunk_vcn.id
  route_table_id      = oci_core_route_table.route_table.id
  security_list_ids   = [oci_core_security_list.security_list.id]
  dhcp_options_id     = oci_core_dhcp_options.dhcp_options.id
  dns_label           = "splunk"
}

# ------------------------------
# secondary vnic attachment
# ------------------------------

resource "oci_core_vnic_attachment" "secondary_vnic_attachment" {
  instance_id  = oci_core_instance.test_instance1.id
  display_name = "SecondaryVnicAttachment_${count.index}"

  create_vnic_details {
    subnet_id              = oci_core_subnet.splunk_subnet.id
    display_name           = "SecondaryVnic_${count.index}"
    assign_public_ip       = true
    skip_source_dest_check = true
    nsg_ids                = [oci_core_network_security_group.network_security_group.id]
  }

  count = var.secondary_vnic_count
}

data "oci_core_vnic" "secondary_vnic" {
  count = var.secondary_vnic_count
  vnic_id = element(
    oci_core_vnic_attachment.secondary_vnic_attachment.*.vnic_id,
    count.index,
  )
}

# ------------------------------
# nat gateway
# ------------------------------

resource "oci_core_nat_gateway" "splunk_nat_gateway" {
    #Required
   compartment_id = var.compartment_ocid
   vcn_id = oci_core_vcn.splunk_vcn.id
}

data "oci_core_services" "base_services" {
}

# ------------------------------
# service gateway
# ------------------------------

resource "oci_core_service_gateway" "base_service_gateway" {
    #Required
    compartment_id = var.compartment_ocid
    vcn_id         = oci_core_vcn.splunk_vcn.id
    services {
        #Required
        service_id = lookup(data.oci_core_services.base_services.services[0], "id")
    }
}

# ------------------------------
# internet gateway
# ------------------------------

resource "oci_core_internet_gateway" "ig" {
  display_name   = "internet_gateway"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.splunk_vcn.id
}

resource "oci_core_route_table" "route_table" {
  display_name   = "route_table"
  compartment_id = var.compartment_ocid
  vcn_id = oci_core_vcn.splunk_vcn.id

    route_rules {
      # * With this route table, Internet Gateway is always declared as the default gateway
      destination       = "0.0.0.0/0"
      network_entity_id = oci_core_internet_gateway.ig.id
      description       = "Terraformed - Auto-generated at Internet Gateway creation: Internet Gateway as default gateway"
    }
}

resource "oci_core_drg" "drg" {
  compartment_id = var.compartment_ocid
  #display_name   = var.label_prefix == "none" ? var.drg_display_name : "${var.label_prefix}-drg"

  #freeform_tags = var.tags

  #count = var.create_drg == true ? 1 : 0
}

resource "oci_core_drg_attachment" "drg" {
 drg_id = oci_core_drg.drg.id
 vcn_id = oci_core_vcn.splunk_vcn.id

 #count = var.create_drg == true ? 1 : 0
}


#*************************************
#           Security Requirements
#*************************************

resource "oci_core_security_list" "security_list" {
 display_name   = "security_list"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.splunk_vcn.id

  egress_security_rules {
    protocol    = "All"
    destination = "0.0.0.0/0"
  }

  ingress_security_rules {
    protocol = "All"
    source   = "0.0.0.0/0"
  }
}

resource "oci_core_network_security_group" "network_security_group" {
  #Required
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.splunk_vcn.id
  #Optional
  display_name = "TestNetworkSecurityGroup"
}

resource "oci_core_network_security_group_security_rule" "ingress_ssh" {
  network_security_group_id = oci_core_network_security_group.network_security_group.id # Required
  direction                 = "INGRESS"                              # Required
  protocol                  = "6"                                    # Required
  source                    = "0.0.0.0/0"                         # Required
  source_type               = "CIDR_BLOCK"                           # Required
  stateless                 = false                                  # Optional
  tcp_options {                                                      # Optional
    destination_port_range {                                         # Optional
      max = "22"                                                     # Required
      min = "22"                                                     # Required
    }
  }
  description = "ssh only allowed" # Optional
}

resource "oci_core_network_security_group_security_rule" "ingress_icmp_3_4" {
  network_security_group_id = oci_core_network_security_group.network_security_group.id # Required
  direction                 = "INGRESS"                              # Required
  protocol                  = "1"                                    # Required
  source                    = "0.0.0.0/0"                        # Required
  source_type               = "CIDR_BLOCK"                           # Required
  stateless                 = false                                  # Optional
  icmp_options {                                                     # Optional
    type = "3"                                                       # Required
    code = "4"                                                       # Required
  }
  description = "icmp option 1" # Optional
}

resource "oci_core_network_security_group_security_rule" "ingress_icmp_3" {
  network_security_group_id = oci_core_network_security_group.network_security_group.id # Required
  direction                 = "INGRESS"                              # Required
  protocol                  = "1"                                    # Required
  source                    = "10.0.0.0/16"                          # Required
  source_type               = "CIDR_BLOCK"                           # Required
  stateless                 = false                                  # Optional
  icmp_options {                                                     # Optional
    type = "3"                                                       # Required
  }
  description = "icmp option 2" # Optional
}

resource "oci_core_network_security_group_security_rule" "egress" {
  network_security_group_id = oci_core_network_security_group.network_security_group.id # Required
  direction                 = "EGRESS"                               # Required
  protocol                  = "6"                                    # Required
  destination               = "0.0.0.0/0"                        # Required
  destination_type          = "CIDR_BLOCK"                           # Required
  stateless                 = false                                  # Optional
  description               = "connect to any network"
}


resource "oci_core_dhcp_options" "dhcp_options" {
    #Required
    compartment_id = var.compartment_ocid
    options {
        type = "DomainNameServer"
        server_type = "VcnLocalPlusInternet"
    }

    options {
        type = "SearchDomain"
        search_domain_names = [ "test.com" ]
    }

    vcn_id = oci_core_vcn.splunk_vcn.id

    #Optional
    #display_name = var.dhcp_options_display_name
}


#*************************************
#           IAM Requirements
#*************************************

data "oci_identity_compartment" "this" {
  id = var.compartment_ocid
}

# Generate the private and public key pair
resource "tls_private_key" "ssh_keypair" {
  algorithm = "RSA" # Required
  rsa_bits  = 2048  # Optional
}

#resource "oci_identity_dynamic_group" "SplunkDemo" {
#  compartment_id = var.tenancy_ocid
#  description    = "To Access OCI CLI"
#  name           = "${local.display_name}-dynamic-group"
  #matching_rule  = "ANY {instance.id = 'CHANGE TO INSTANCE OR COMPARTMENT OCID FOR INSTANCE PRINCIPAL'"
  #freeform_tags  = var.common_tags
#}


#resource "oci_identity_policy" "dynamic-policy-1" {
#  name           = "tf-example-dynamic-policy"
#  description    = "dynamic policy created by terraform"
#  compartment_id = data.oci_identity_compartments.compartments1.compartments[0].id
#
#  statements = [
#    "Allow dynamic-group ${oci_identity_dynamic_group.dynamic-group-1.name} to read instances in compartment ${data.oci_identity_compartments.compartments1.compartments[0].name}",
#    "Allow dynamic-group ${oci_identity_dynamic_group.dynamic-group-1.name} to inspect instances in compartment ${data.oci_identity_compartments.compartments1.compartments[0].name}",
#  ]
#}

#data "oci_identity_policies" "dynamic-policies-1" {
#  compartment_id = data.oci_identity_compartments.compartments1.compartments[0].id

#  filter {
#    name   = "id"
#    values = [oci_identity_policy.dynamic-policy-1.id]
#  }
#}
#





#*************************************
#           Compute Requirements
#*************************************

# ------------------------------
# SH Captain instance variables
# ------------------------------

resource "oci_core_instance" "test_instance1" {
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = var.compartment_ocid
  display_name        = "SHCaptain"
  shape               = "VM.Standard2.1"
  source_details {
    source_type = "image"
    source_id   = var.instance_image_ocid[var.region]
  }
  create_vnic_details {
    subnet_id      = oci_core_subnet.splunk_subnet.id
    assign_public_ip = false
    hostname_label = "SHCaptain"
  }

  metadata = {
   ssh_authorized_keys = var.generate_ssh_key_pair ? tls_private_key.ssh_keypair.public_key_openssh : var.ssh_public_key
   user_data           = base64encode(join(
        "\n",
        [
          "#!/usr/bin/env bash",
          file("./scripts/bootstrap2.sh"),
        ],
      ),
    )
 }

  extended_metadata = {
    config = jsonencode(
      {
        "shape"        = "VM.Standard2.1"
        "disk_count"   = var.manager_disk_count
        "disk_size"    = var.manager_disk_size
        "password"     = var.password
        "sites_string" = var.sites_string
      },
    )
  }
}

# ------------------------------
# HF forwarder instance variables
# ------------------------------

resource "oci_core_instance" "test_instance2" {
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = var.compartment_ocid
  display_name        = "HF Forwarder"
  shape               = "VM.Standard2.1"
  source_details {
    source_type = "image"
    source_id   = var.instance_image_ocid[var.region]
  }
  create_vnic_details {
    subnet_id      = oci_core_subnet.splunk_subnet.id
    hostname_label = "Forwarder"
  }

  metadata = {
   ssh_authorized_keys = var.generate_ssh_key_pair ? tls_private_key.ssh_keypair.public_key_openssh : var.ssh_public_key
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
        "shape"        = "VM.Standard2.1"
        "disk_count"   = var.manager_disk_count
        "disk_size"    = var.manager_disk_size
        "password"     = var.password
        "sites_string" = var.sites_string
      },
    )
  }
}

data "oci_core_instance" "test_instance2" {
    #Required
    instance_id = oci_core_instance.test_instance2.id
}

# ------------------------------
# Indexer Cluster_Manager Instance
# ------------------------------

resource "oci_core_instance" "test_instance7" {
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = var.compartment_ocid
  display_name        = "Cluster_Manager"
  shape               = "VM.Standard2.1"
  source_details {
    source_type = "image"
    source_id   = var.instance_image_ocid[var.region]
  }
  create_vnic_details {
    subnet_id      = oci_core_subnet.splunk_subnet.id
    assign_public_ip = false
  }
  metadata = {
   ssh_authorized_keys = var.generate_ssh_key_pair ? tls_private_key.ssh_keypair.public_key_openssh : var.ssh_public_key
   user_data           = base64encode(join(
        "\n",
        [
          "#!/usr/bin/env bash",
          file("./scripts/bootstrap1.sh"),
        ],
      ),
    )
 }

  extended_metadata = {
    config = jsonencode(
      {
        "shape"        = "VM.Standard2.1"
        "disk_count"   = var.manager_disk_count
        "disk_size"    = var.manager_disk_size
        "password"     = var.password
        "sites_string" = var.sites_string
      },
    )
  }
}

# ------------------------------
# Indexer Instance
# ------------------------------

resource "oci_core_instance" "indexer" {
  display_name        = "indexer${count.index}"
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domain.ad.name
  shape               = "VM.Standard2.1"

  source_details {
    source_id   = var.instance_image_ocid[var.region]
    source_type = "image"
  }

  create_vnic_details {
    subnet_id      = oci_core_subnet.splunk_subnet.id
    hostname_label = "indexer${count.index}"
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data = base64encode(
      join(
        "\n",
        [
          "#!/usr/bin/env bash",
          file("./scripts/indexers.sh"),
        ],
      ),
    )
  }

  extended_metadata = {
    config = jsonencode(
      {
        "shape"            = var.instance_shape
        "disk_count"       = var.index_count
        "password"     = var.password
        "sites_string" = var.sites_string
        "count"            = count.index
        "public_ip" = var.public_ip
      },
    )
  }

  count = var.index_count
}



#*********************************************************
#           Logging, Stream, Service Connector
#*********************************************************

data "oci_logging_log_group" "to_splunk_log_group" {
    #Required
    log_group_id = oci_logging_log_group.to_splunk_log_group.id
}

resource "oci_logging_log_group" "to_splunk_log_group" {
	#Required
	compartment_id = var.compartment_ocid
	display_name = "to_splunk_log_group"

	#Optional
	#defined_tags = {"Operations.CostCenter"= "42"}
	#description = var.log_group_description
	#freeform_tags = {"Department"= "Finance"}
}

resource "oci_logging_log" "test_log" {
    #Required
    display_name = "TestFlowLogs"
    log_group_id = oci_logging_log_group.to_splunk_log_group.id
    log_type = "SERVICE"

    #Optional
    configuration {
        #Required
        source {
            #Required
            category = "all"
            resource = oci_core_subnet.splunk_subnet.id
            service = "flowlogs"
            source_type = "OCISERVICE"
        }

        #Optional
        compartment_id = var.compartment_ocid
    }
    #defined_tags = {"Operations.CostCenter"= "42"}
    #freeform_tags = {"Department"= "Finance"}
    is_enabled = true
    retention_duration = 60
}

resource "oci_streaming_stream" "test_stream" {
    #Required
    name = "xyz"
    partitions = 1


    #Optional
    compartment_id = var.compartment_ocid
    #defined_tags = var.stream_defined_tags
    #freeform_tags = {"Department"= "Finance"}
    retention_in_hours = 24
    #stream_pool_id = oci_streaming_stream_pool.test_stream_pool.id
}


data "oci_sch_service_connectors" "test_service_connectors" {
	#Required
	compartment_id = var.compartment_ocid

	#Optional
	display_name = "test_service_connector"
	#state = var.service_connector_state
}

resource "oci_sch_service_connector" "test_service_connector" {
    #Required
    compartment_id = var.compartment_ocid
    display_name = "splunk sch_connector"
    source {
        #Required
        kind = "logging"


        log_sources {

            #Optional
            compartment_id = var.compartment_ocid
            log_group_id = oci_logging_log_group.to_splunk_log_group.id
            log_id = oci_logging_log.test_log.id
        }
    }
    target {
        #Required
        kind = "streaming"

        #Optional
        #batch_rollover_size_in_mbs = var.service_connector_target_batch_rollover_size_in_mbs
        #batch_rollover_time_in_ms = var.service_connector_target_batch_rollover_time_in_ms
        #bucket = var.service_connector_target_bucket
        #compartment_id = var.compartment_id
        #enable_formatted_messaging = var.service_connector_target_enable_formatted_messaging
        #function_id = oci_functions_function.test_function.id
        log_group_id = oci_logging_log_group.to_splunk_log_group.id
        #metric = var.service_connector_target_metric
        #metric_namespace = var.service_connector_target_metric_namespace
        #namespace = var.service_connector_target_namespace
        #object_name_prefix = var.service_connector_target_object_name_prefix
        stream_id = oci_streaming_stream.test_stream.id
        #topic_id = oci_ons_notification_topic.test_notification_topic.id
    }
}


#*************************************
#           Outputs
#*************************************

output "secondary_public_ip_addresses" {
  value = [data.oci_core_vnic.secondary_vnic.*.public_ip_address]
}

output "secondary_private_ip_addresses" {
  value = [data.oci_core_vnic.secondary_vnic.*.private_ip_address]
}

output "id-for-route-table-that-includes-the-internet-gateway" {
  description = "OCID of the internet-route table. This route table has an internet gateway to be used for public subnets"
  value =oci_core_internet_gateway.ig
}
output "nat-gateway-id" {
  description = "OCID for NAT gateway"
  value = oci_core_nat_gateway.splunk_nat_gateway
}
output "id-for-for-route-table-that-includes-the-nat-gateway" {
  description = "OCID of the nat-route table - This route table has a nat gateway to be used for private subnets. This route table also has a service gateway."
  value = oci_core_route_table.route_table
}

output "Manager_server_private_IP" {
  value = oci_core_instance.test_instance7.private_ip
}

output "Forwarder_server_public_IP" {
  value = oci_core_instance.test_instance2.public_ip
}

#output "dynamicPolicies" {
#  value = data.oci_identity_policies.dynamic-policies-1.policies
#}
