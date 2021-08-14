variable "tenancy_ocid" {}
variable "region" {}

provider "oci" {
  tenancy_ocid = var.tenancy_ocid
  region       = var.region
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

output "ads"{
  value = data.oci_identity_availability_domains.ads
}
