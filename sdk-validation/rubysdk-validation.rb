require 'oci'
require 'pp'

instance_principals_signer = OCI::Auth::Signers::InstancePrincipalsSecurityTokenSigner.new

identity_client = OCI::Identity::IdentityClient.new(signer: instance_principals_signer)

response = identity_client.list_regions

pp 'Regions: '
pp response.data
