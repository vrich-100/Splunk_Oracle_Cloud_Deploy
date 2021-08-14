import oci

signer = oci.auth.signers.InstancePrincipalsSecurityTokenSigner()

identity_client = oci.identity.IdentityClient(config={}, signer=signer)

compartment_id = signer.tenancy_id

region_list = identity_client.list_regions().data

assert region_list is not None
print("PythonSDK Install Validation Success")
