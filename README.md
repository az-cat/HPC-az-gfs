# [DRAFT] Azure HPC Cluster with GFS attached
The purpose of this repository is for a simple configuration of an HPC cluster inside of Azure with a Gluster File System configured and mounted. Gluster is deployed via Batch Shipyard.

## Quickstart
To deploy an Infiniband enabled compute cluster with a Gluster File Server attached and mounted:
1. Make sure you have quota for H-series (compute cluster) and F-series (jumpbox and storage cluster)
2. Open the cloud shell from the Azure portal
3. Clone the repository, `git clone https://github.com/tanewill/azhpc_gfs`
4. Update the Batch Shipyard RemoteFS credentials file with Service Principal Auth, [required entries](https://github.com/tanewill/azhpc_gfs/blob/master/credentials.yaml)
5. From inside of the cloned repository folder, run `./create_cluster [Resource Group name] [Compute nodes]`
   - Example: `./create_cluster.sh my-test-rg01 3`

6. At the completion of deployment you will be given an SSH string to access your cluster, change directories into the folder that was created for your Resource Group name and run the string.
   - Example: `ssh -i id_rsa_batchshipyardkey azureuser@23.45.67.89`

7. Once logged onto the jumpbox, run the command `df -h` to see the storage available on the jumpbox. To see the compute node ip addresses run, `cat bin/hostips`. SSH into the first IP address listed, replace 10.0.0.6 in the followind command with the first IP address listed from the output of the previous command `ssh 10.0.0.6`. The compute nodes are H16r's that are connected via Infiniband for low latency communication.

## Purpose
The purpose of this article is to provide an introduction to IaaS HPC and HPC storage in the cloud and to provide some useful tools and information to quickly setup an HPC cluster with four different types of storage.

## Introduction
High Performance Computing and storage in the cloud can be very confusing and it can be difficult to determine where to start. This repository is designed to be a first step in expoloring a cloud based HPC storage and compute architecture. There are many different configuration that could be used, but this repository focuses on an RDMA connected compute cluster and a Gluster file system that is attached. Three different deployment strategies are used, a Bash script for orchastration, an Azure Resource Manager (ARM) template for the compute cluster, and Azure Batch Shipyard for the file server deployment. After deployment fully independant and functioning IaaS HPC compute and storage cluster has been deployed based on the architecture below.

### Example Architecture
![alt text](https://github.com/tanewill/azhpc_gfs/blob/master/support/azhpc_gfs_arch.png)

### Estimated Monthly Cost for North Central US
Estimates calculated from [Azure Pricing Calculator](https://azure.microsoft.com/en-us/pricing/calculator/)
 - Compute, 80 H16r cores
   - 5 H16 compute nodes @ 75% utilization, $5,459.81/month 
 - Storage, 27 TB
   - 2 F8 File Servers, $582.67/month
   - 12 Premium, P30 Managed Disks. 12 TB, $1,622.04/month
   - 15 TB Azure Files, $912.63/month

Total Cost about $8,577.15/month (~$5,952.42/month with 3 year commit)

### HPC in the Cloud
- HPC in the cloud continues to gain momentum. 
[Inside HPC Article](https://insidehpc.com/2017/03/long-rise-hpc-cloud/)
[The Cloud is Great for HPC](https://www.theregister.co.uk/2017/06/16/the_cloud_is_great_for_hpc_discuss/)
		
- Azure's play in the HPC space has been significant
  * Infiniband enabled hardware
  * [H-Series](https://azure.microsoft.com/en-us/blog/availability-of-h-series-vms-in-microsoft-azure/)
  * [Massive HPC deals at financial services institutions, Oil and Gas companies, etc](https://www.forbes.com/sites/alexkonrad/2017/10/30/chevron-partners-with-microsoft-in-cloud/)
  * [Cray offering](https://www.cray.com/solutions/supercomputing-as-a-service/cray-in-azure)
		
- Unlike traditional HPC environments, cloud HPC environments can be created and destroyed quickly, completely, and easily in an Ad-Hoc and On Demand fashon. With large physical disks, many storage requirments can be satisified using the attached physical disks.
	
- Now with Azure enabling over 4,000 cores for a single Infiniband enabled MPI job the dataset size can potential exceed the 2TB attached Solid State Disks. With these large datasets a simple and flexible storage solution is needed.

## Process
  The architecture, credentials, and tooling for creatig
### Architecture
#### Storage Deployment
There are four different types of storage that will be used for this HPC cluster. Using the default configuration there is over 29TB available for this compute cluster.
- Physically Attached Storage as a *burst buffer*, located at `/mnt/resource` on each node
- NFS shared from the jumpbox and located at `/mnt/scratch`, created in the hn-setup script here: [hn-setup_gfs.sh](https://github.com/tanewill/azhpc_gfs/blob/master/script/hn-setup_gfs.sh#L58-L72)
- GFS shared from the storage cluster mounted at `/mnt/gfs`, created using Batch Shipyard, [link](http://batch-shipyard.readthedocs.io/en/latest/65-batch-shipyard-remote-fs/), here in [create_cluster.sh](https://github.com/tanewill/azhpc_gfs/blob/master/create_cluster.sh#L34-L39)
- Three 5TB Azure Files shares mounted to the jumpbox at `/mnt/lts1`,`/mnt/lts2`,`/mnt/lts3`. This is a CIFS share and can be mounted to both the Windows and Linux operating systems. These Azure File shares are subject to performance limits specified [here](https://docs.microsoft.com/en-us/azure/azure-subscription-service-limits#azure-files-limits). The size can be altered by increasing the quota here: [create_cluster.sh](https://github.com/tanewill/azhpc_gfs/blob/master/create_cluster.sh#L66)

Below is an image that attempts to visualize the needed storage structure for an example workload. The Physically attached storage is the temporary storage, the GFS is for the 'campaign' data that supports multiple workloads, finally the Azure Files share is for long term data retention.

![alt text](https://github.com/tanewill/azhpc_gfs/blob/master/support/workload_storage_movement.png)

In the deployment process the GFS file server is created first using Batch Shipyard. The latest Batch Shipyard binary is downloaded and the file server is created based on the credentials in credentials.yaml and the configuration definitions in fs.yaml and configuration.yaml. Please refer to the Batch Shipyard documentation for more information about these files. For the deployment of the file server a resource group is created and then the managed disks that are defined in fs.yaml are created. The next step creates the virtual network, subnet, and nodes that are used for the file server. The managed disks are then attached to the file server nodes. By default an F8 VM is used as the file server with 12 p30 managed disks for 12 TB of storage using a distributed, RAID 0 configuration, that can be altered in the fs.yaml file. You can refer to [this Azure website](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/sizes-compute) for information about how many disks can be attached to different VM sizes.

#### Compute Deployment
Inside of Azure the architecture is simple. For the compute cluster use an A9 or H16r/H16mr Virtual Machine Scale Set (VMSS). The nodes are automatically deployed in a single placement group and are connected via Infiniband hardware. VMSS do not have external or public-ips, so if you are creating a new VNET when you create your HPC cluster you will also need to add a 'jumpbox' this box is not the cluster headnode or rank 0, it is simply a way to access your VMSS. A small VM SKU will suffice.

After the file server is created the compute cluster is created in a seperate subnet. The compute cluster is based on the raw compute cluster found in the [AHOD-HPC Github repository](https://github.com/tanewill/AHOD-HPC/). Currently an independant azuredeploy.json is used in this repository, the application configuration scripts that are used are the ones found in the AHOD-HPC repository. For this deployment a [Virtual Machine Scale Set is created](https://github.com/tanewill/azhpc_gfs/blob/master/azuredeploy.json#L298-L350), [a jumpbox is created](https://github.com/tanewill/azhpc_gfs/blob/master/azuredeploy.json#L231-L260) and an [extension is run on the jumpbox](https://github.com/tanewill/azhpc_gfs/blob/master/azuredeploy.json#L261-L288). The extension downloads and calls the [hn-setup_gfs.sh script](https://github.com/tanewill/azhpc_gfs/blob/master/scripts/hn-setup_gfs.sh) which configures the headnode, installs and starts the NFS server, and then launches the [cn-setup_gfs.sh script](https://github.com/tanewill/azhpc_gfs/blob/master/scripts/hn-setup_gfs.sh) which mounts the GFS and NFS file server on all of the compute nodes.

Finally the azuredeploy.json template creates an Azure Files Storage Account which will be used for long term storage. After the ARM template has been fully deployed the create_cluster.sh script is used to get the storage account keys and then mount the storage account to the jumpbox.

### Credential Configuration
Batch Shipyard requires a [Service Principal](https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli?toc=%2Fazure%2Fazure-resource-manager%2Ftoc.json&view=azure-cli-latest) and an authentication key to deploy without any security prompts. In order to generate this enter follow the instructions [here](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-create-service-principal-portal?#create-an-azure-active-directory-application).

![alt text](https://github.com/tanewill/azhpc_gfs/blob/master/support/credentials.png) 

### Tools
#### Scripts
  Three scripts are used for the deployment of this repository, unlike many ARM templates, this template is not designed to be run independantly. It has been designed to be deployed in connection with other features called in the `create_cluster.sh` script. `create_cluster.sh` is the master script, it downloads Batch Shipyard, deploys a storage file server, a compute cluster, and then mounts Azure Files.

  The `azuredeploy.json` ARM template calls the two scripts that are located in the `scripts` directory. These scripts are used for the configuration of the head node [hn-setup_gfs.sh](https://github.com/tanewill/azhpc_gfs/blob/master/scripts/hn-setup_gfs.sh) and the compute nodes [cn-setup_gfs.sh](https://github.com/tanewill/azhpc_gfs/blob/master/scripts/cn-setup_gfs.sh). They are designed to be used when there is a Gluster File Server inside of the VNET that the template is deployed in.

  `hn-setup_gfs.sh` performs a number of basic node configuration commands. Installing needed packages and starting the NFS server. [Passwordless authentication](https://github.com/tanewill/azhpc_gfs/blob/master/scripts/hn-setup_gfs.sh#L99-L109) is setup in such a way to allow seperate home directory on each of the nodes,this protects connectivity from being lost in the event that the NFS server locks up. An additional reason that this step was taken is because the jumpbox is not necessarily the same VM type as the compute nodes. The [host list is populated through an nmap](https://github.com/tanewill/azhpc_gfs/blob/master/scripts/hn-setup_gfs.sh#L99-L109) instead of relying on a response from the Azure CLI. [Ganglia is installed](https://github.com/tanewill/azhpc_gfs/blob/master/scripts/hn-setup_gfs.sh#L55-L57) on the jumpbox and all the compute nodes as well. Finally the script installs the selected application on the share, this installation is actually done from the first node in the hostlist.

  `cn-setup_gfs.sh` is a simple script that installs a few packages, ganglia, and configures the environment for mpi execution of applications.

#### ARM Template
  - `azuredeploy.json` is the primary deployment script, it was taken from the [AHOD-HPC deployment example](https://github.com/tanewill/AHOD-HPC) because there are a number of changes it is a standalone fork. It creates all of the resources needed for this example. This template does not affect the file server at all, that deployment is completely managed by Batch Shipyard.
  - `Parameters.json` specifies the parameters for the `azuredeploy.json` template.
  
#### Data transfer tools
  There are three different tools that are recommended to transfer data to the file server, the compute cluster, or the storage blob.
  
  - Fast Data Transfer Tool (FDT), FDT is a tool for fast ingestion of data into Azure – up to 4 terabytes per hour from a single client machine. It can be used to load data into Storage, to a clustered file system, or anything else that can be mounted into a VM’s file system (e.g. via a FUSE driver).  The FDT client is a command-line application. It requires a server-side component that runs on your own Azure VM(s).

    [Installation instructions for FDT](https://fdtreleases.blob.core.windows.net/beta/FDT%20Instructions-beta.pdf)

  - Blobxfer, blobxfer is an advanced data movement tool and library for Azure Storage Blob and Files. With blobxfer you can copy your files into or out of Azure Storage *with the CLI* or integrate the blobxfer data movement library into your own Python scripts.

    [Installation binaries for blobxfer](https://github.com/Azure/blobxfer/releases)
  
  - Secure Copy (SCP), is a protocol based on SSH (Secure Shell) that provides secure file transfers between two computers. With SCP, you can quickly transfer files using the command line, which is often faster and easier. Additionally, you can use this command-line functionality in your own batch files and scripts to automate file transfers.

#### Batch Shipyard
  Batch Shipyard is used for the configuration of the [stand alone remote file system](http://batch-shipyard.readthedocs.io/en/latest/65-batch-shipyard-remote-fs/).

#### Gluster 
  Batch Shipyard includes support for automatically provisioning a GlusterFS storage cluster for both scale up and scale out scenarios. [Gluster](https://www.gluster.org/) is a free and open source scalable network filesystem, it is a scalable network filesystem. You can create large, distributed storage solutions for media streaming, data analysis, and other data- and bandwidth-intensive tasks. Gluster is free.
	
## Conclusion
  This repository removes the complexity from creating an HPC cluster with an attached and mounted File Server. 
