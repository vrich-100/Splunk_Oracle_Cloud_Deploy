#*************************************
#           Outputs
#*************************************

# output "secondary_public_ip_addresses" {
#   value = [data.oci_core_vnic.secondary_vnic.*.public_ip_address]
# }

# output "secondary_private_ip_addresses" {
#   value = [data.oci_core_vnic.secondary_vnic.*.private_ip_address]
# }

# output "id-for-route-table-that-includes-the-internet-gateway" {
#   description = "OCID of the internet-route table. This route table has an internet gateway to be used for public subnets"
#   value =oci_core_internet_gateway.ig
# }
# output "nat-gateway-id" {
#   description = "OCID for NAT gateway"
#   value = oci_core_nat_gateway.splunk_nat_gateway
# }
# output "id-for-for-route-table-that-includes-the-nat-gateway" {
#   description = "OCID of the nat-route table - This route table has a nat gateway to be used for private subnets. This route table also has a service gateway."
#   value = oci_core_route_table.route_table
# }

# output "Manager_server_private_IP" {
#   value = oci_core_instance.test_instance7.private_ip
# }

output "Forwarder_server_public_IP" {
  value = oci_core_instance.HeavyForwarder.public_ip
}

#output "dynamicPolicies" {
#  value = data.oci_identity_policies.dynamic-policies-1.policies
#}
