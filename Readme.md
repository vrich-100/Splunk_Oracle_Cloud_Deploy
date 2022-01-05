Getting Started

Plan architecture:
Indexer cluster, y/n?
Sh cluster, y/n?
Deployer on Cluster_Manager
Multi-site, y/n?

In OCI
Create config file in your OCI deployment [for necessary variables for TA and app]

Create your required reserve IPs (think 1 for cluster master and 1 for search head cluster captain)

In your .tf

Replace cluster master ip in the bash script with your reserve IP or desired ip:
  boostrap1.sh line 250
  bootstrap2.sh lines 248, 252, 255
  indexers.sh line 246

Replace sh cluster ip in bash scripts []

Confirm desired ports listed [bash scripts]

OCI-Resource Manager-Stacks

Create New Stack
Install .tf

After Instances are Created
Get OCID for Heavy Forwarder: __________
Add the reserve ip to the Cluster_Manager instance
OCI-Instance(cluster-manager)-Attached VNICs, Click on {Name}, IPv4 address, Reserved IP

Confirm the policies for:
-Logging
-Streaming
-Service Connector Hub, make sure to add the Audit logs
- Create Dynamic Group (update with compartment OCID or instance.id of the Heavy Forwarder):
Name of Dynamic Group:______________________ (ex SplunkTest)
Ex: Any {instance.compartment.id ='ocid1.tenancy.oc1..aXXXX'}

 Create Policy permissions:
	Allow dynamic-group SplunkTest to use stream-pull in tenancy


Splunk On Heavy Forwarder:
-create index for OCI events NAME OF INDEX: _____________
-install OCI TA
-Configure TA with the stream writing to the created index
-confirm forwarding settings
-configure indexer clustering settings; peer node

Splunk On Cluster Manager
-install Splunk app for OCI
-follow directions on splunkbase

Splunk on SHCaptain


In OCI
-add an index to the stack


Result: Splunk, OCI HF, Index Cluster, SHCaptain
