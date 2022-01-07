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

### 4. Deploying your local copy of this repository in Oracle Cloud

OCI-Resource Manager-Stacks

Create New Stack

Upload your local copy of this repository (with the corrected IP addresses in the bash scripts) as a folder or .zip.

*Make sure to fill in the password variable with your desired Splunk instance password*

After Instances are Created
Get OCID for Heavy Forwarder: __________
Attach the desired reserved ip address to the Cluster_Manager instance
OCI-Instance(cluster-manager)-Attached VNICs, Click on {Name}, IPv4 address, Reserved IP

Confirm the policies for:
- Logging
- Streaming
- Service Connector Hub, make sure to add the Audit logs
- Create Dynamic Group (update with compartment OCID or instance.id of the Heavy Forwarder):
Name of Dynamic Group:______________________ (ex SplunkTest)
Ex: Any {instance.compartment.id ='ocid1.tenancy.oc1..aXXXX'}

Create Policy permissions:
	Allow dynamic-group SplunkTest to use stream-pull in tenancy


### 5. In your Splunk Instances

* This repository will create a cluster with a replication factor of 2 and search factor of 2. More information can be found [here](https://docs.splunk.com/Documentation/Splunk/8.2.2/Indexer/Thereplicationfactor)
  
#### Cluster Manager Instance

- Login to the instance using https://[publicipaddress]:8000
- Your login information will be:
	username: admin
	pw: [set by your password variable]
	
- In Splunk ---> Setting --->Indexer Clustering
	You will see you splunk instances in their respective function (indexer, search head)
	
*The replication factor will not be 'met' until you add your heavy forwarder to the cluster*

-Install [OCI (Oracle Cloud Infrastructure) App for Splunk](https://splunkbase.splunk.com/app/5289/) (optional)
-Follow setup instrucions found in the "Details" tab of the app's page on splunkbase.

#### Heavy Forwarder
- Login to the instance using https://[publicipaddress]:8000
- Your login information will be:
	username: admin
	pw: [set by your password variable]
	
- In Splunk ---> Setting --->Indexer Clustering
- Enable indexer clustering
- Create a 'peer node' and use the [publicip of cluster_manager instance] as the mgmt URI and choose port 8080.

*If you return to the Indexer Clustering screen on the cluster manager, you should see the forwarder and the replication/search factors should be met*

The remaining steps are specific to the OCI TA but the instance can be used as a heavy forwarder for any purpose:

-Create index for OCI events NAME OF INDEX: _____________

-Install OCI TA

-Configure TA with the stream writing to the created index

-confirm forwarding settings


#### Search Head Captain
working

## Adding additional Splunk resources using OCI Resource Manager:

  * Return to OCI Resource Manager --> Stacks
  * Click on the name of the stack you've created
  * Click 'Edit'
  * You should see a similar screen to your initial creation of the stack. Select 'Next' at the bottom of the screen. 
  * On the variables screen, increase the number of indexers to the desired total count. 
  * Applying this job will provision indexer instances.


Result: Splunk, OCI HF, Index Cluster, SHCaptain
