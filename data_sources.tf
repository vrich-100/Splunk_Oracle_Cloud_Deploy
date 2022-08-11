#*************************************
#           Network Requirements
#*************************************

data "oci_identity_availability_domain" "ad" {
  compartment_id = var.tenancy_ocid
  ad_number      = 1
}

data "oci_core_subnet" "splunk_hf_subnet" {
    #Required
    subnet_id = var.splunk_hf_subnet_id
}

#*************************************
#           IAM Requirements
#*************************************

data "oci_identity_compartment" "this" {
  id = var.compartment_ocid
}


data "oci_core_instance" "HeavyForwarder" {
    #Required
    instance_id = oci_core_instance.HeavyForwarder.id
}

