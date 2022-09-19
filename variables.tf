#*************************************
#           TF Requirements
#*************************************
variable "tenancy_ocid" {}
variable "region" {}
variable "compartment_ocid" {}

variable "instance_shape" {
  description = "Shape of the instance"
  type        = string
  default     = "VM.Standard2.1"
}

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

variable "use_tenancy_level_policy" {
  description = "Compute instance to access all resources at tenancy level"
  type        = bool
  default     = true
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

variable "password" {
  type = string
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

variable "public_ip" {}
