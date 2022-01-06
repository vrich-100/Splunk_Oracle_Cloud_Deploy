# Overview

This repository is for a rapid deployment of a basic [Splunk Validated Architecture](https://www.splunk.com/pdfs/technical-briefs/splunk-validated-architectures.pdf) on a new [Oracle Cloud Infrastructure](https://www.oracle.com/cloud/) deployment.

This repository provisions Oracle Cloud Infrastructure components and 3 [Splunk](https://www.splunk.com) compute instances that are ready to perform as a Heavy Forwarder, Cluster Manager, Indexer with the Cluster Manager also serving as a Search Head.

In this repository, the Heavy Forwarder instance is ready for installation of the Oracle/Splunk Technical Add-on/ plugin. Contact Oracle support for the latest version.

The Cluster Manager is ready for the installation of the [OCI (Oracle Cloud Infrastructure) App for Splunk](https://splunkbase.splunk.com/app/5289). Use of this app with the TA installed on the heavy forwarder gives you monitoring of your Oracle Cloud Infrastructure in Splunk Enterprise.

For production enviroments, you will need to bring your Splunk License to ensure persistant performance.

## Getting Started

### 1. Plan architecture:
  * Indexer cluster, y/n?  
  * Search Head cluster, y/n?  
  * Deployer on Cluster_Manager, y/n?  
  * Multi-site, y/n?  
  

### 2. In OCI
Create config file in your OCI deployment [for necessary variables for TA and app]

Create your required reserved IPs (think 1 for cluster master and 1 for search head cluster captain)

### 3. In your local copy of this repository

Replace the "XXXX" in the bash scripts with your reserved IP or desired ip for your Cluster Manager:
  * boostrap1.sh line 250.  
  * bootstrap2.sh lines 248, 252, 255.  
  * indexers.sh line 246.  
  

Confirm desired ports listed [bash scripts]

### 4. Deploying your local copy of this repository

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
