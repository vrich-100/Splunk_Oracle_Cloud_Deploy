#*************************************
#           TF Requirements
#*************************************
variable "tenancy_ocid" {}
variable "region" {}
variable "compartment_ocid" {}
variable "user_ocid" {}
variable "private_key_password" {}
variable "private_key_path" {}
variable "fingerprint" {}

variable "generate_ssh_key_pair" {
  description = "Auto-generate SSH key pair"
  type        = string
  default     = "true"
}

variable "ssh_public_key" {
  description = "ssh public key used to connect to the compute instance"
  default     = "" # This value has to be defaulted to blank, otherwise terraform apply would request for one.
  type        = string
}
variable "ssh_private_key" {
  description = "ssh private key used to connect to the compute instance"
  default     = "" # This value has to be defaulted to blank, otherwise terraform apply would request for one.
  type        = string
}


# ------------------------------
# Splunk Server variables
# ------------------------------

variable "splunk_server_ip" {
  type  = string
  description = "IP Address or Host name and port of Splunk Server."
  
}

variable "splunk_server_port" {
  type  = string
  description = "Port number of Splunk Server recieving endpoint"
  
}

variable "splunk_oci_index_name" {
  type =string
  description = "Destintation index of the forwarded logs."
  default = "oci_index"

}

variable "splunk_compartment_id" {
  type = string
  
}

variable "network_compartment_id" {
  type = string
  default = ""
}

# ------------------------------
# Splunk Heavy Forwarder variables
# ------------------------------

variable "splunk_hf_instance_shape" {
  description = "Shape of the instance"
  type        = string
  default     = "VM.Standard2.1"
  # update
}

variable "splunk_hf_subnet_id" {
  description = "Subnet OCID that for the heavy forwarder to be deployed in."
  type  = string
}

variable "splunk_hf_password" {
  type = string
  description = "Admin user password for the Heavy Forwarder. Must be changed on first login."
}

# ------------------------------
# manager instance variables
# ------------------------------

variable "manager_disk_count" {
  default = 1
}

variable "manager_disk_size" {
  default = 500
}



variable "sites_string" {
  default = "site1"
}

# ------------------------------
# indexer instance variables
# ------------------------------

variable "indexer_count" {
  default = 1
}

# variable "public_ip" {}
