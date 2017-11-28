# [DRAFT] Azure HPC Cluster with GFS attached
The purpose of this repository is for a simple configuration of an HPC cluster inside of Azure with a Gluster File System configured and mounted. Gluster is deployed via Batch Shipyard.
![alt text](https://github.com/tanewill/azhpc_gfs/blob/master/support/azhpc_gfs_arch.png)

## Quickstart
To deploy an Infiniband enabled compute cluster with a Gluster File Server attached and mounted:
1. Make sure you have quota for H-series (compute cluster) and F-series (jumpbox and storage cluster)
2. Open the cloud shell from the Azure portal
3. Clone the repository, `git clone https://github.com/tanewill/azhpc_gfs`
4. Update the Batch Shipyard RemoteFS credentials file with Service Principal Auth, link
    Minimum required information link
5. From inside of the cloned repository folder, run 
```shell
./create_cluster [Resource Group name] [Compute nodes]
```
* Example: `./create_cluster.sh BTN-TEST-RG01 3`

6. At the completion of deployment you will be given an SSH string to access your cluster, change directories into the folder that was created for your Resource Group name and run the string.
* Example: `ssh -i id_rsa_batchshipyardkey azureuser@23.45.67.89`

## Purpose
The purpose of this article is to provide an introduction to IaaS HPC and HPC storage in the cloud and to provide some useful tools and information to quickly setup an HPC cluster with four different types of storage.

## Introduction
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
### Architecture
#### Storage Deployment
There are four different types of storage that will be used for this HPC cluster. 
- Physically Attached Storage as a *burst buffer*, located at /mnt/resource on each node
- NFS Share from the jumpbox, created in the hn-setup script here: [hn-setup_gfs.sh](https://github.com/tanewill/azhpc_gfs/blob/master/script/hn-setup_gfs.sh#L58-L72)
- GFS Share from the storage cluster, created using Batch Shipyard, [link](http://batch-shipyard.readthedocs.io/en/latest/65-batch-shipyard-remote-fs/), here in [create_cluster.sh](https://github.com/tanewill/azhpc_gfs/blob/master/create_cluster.sh#L34-L39)
- Azure Files share mounted to the jumpbox, the size can be altered by increasing the quota here: [create_cluster.sh](https://github.com/tanewill/azhpc_gfs/blob/master/create_cluster.sh#L66)

In the deployment process the GFS file server is created first using Batch Shipyard. The latest Batch Shipyard binary is downloaded and the file server is created based on the credentials in credentials.yaml and the configuration definitions in fs.yaml and configuration.yaml. Please refer to the Batch Shipyard documentation for more information about these files. For the deployment of the file server a resource group is created and then the managed disks that are defined in fs.yaml are created. The next step creates the virtual network, subnet, and nodes that are used for the file server. The managed disks are then attached to the file server nodes. By default an F8 VM is used as the file server with 12 p30 managed disks for 12 TB of storage using a distributed, RAID 0 configuration, that can be altered in the fs.yaml file. You can refer to [this Azure website](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/sizes-compute) for information about how many disks can be attached to different VM sizes.

#### Compute Deployment
Inside of Azure the architecture is simple. For the compute cluster use an A9 or H16r/H16mr Virtual Machine Scale Set (VMSS). The nodes are automatically deployed in a single placement group and are connected via Infiniband hardware. VMSS do not have external or public-ips, so if you are creating a new VNET when you create your HPC cluster you will also need to add a 'jumpbox' this box is not the cluster headnode or rank 0, it is simply a way to access your VMSS. A small VM SKU will suffice.

After the file server is created the compute cluster is created in a seperate subnet. The compute cluster is based on the raw compute cluster found in the [AHOD-HPC Github repository](https://github.com/tanewill/AHOD-HPC/). Currently an independant azuredeploy.json is used in this repository, the application configuration scripts that are used are the ones found in the AHOD-HPC repository. For this deployment a [Virtual Machine Scale Set is created](https://github.com/tanewill/azhpc_gfs/blob/master/azuredeploy.json#L298-L350), [a jumpbox is created](https://github.com/tanewill/azhpc_gfs/blob/master/azuredeploy.json#L231-L260) and an [extension is run on the jumpbox](https://github.com/tanewill/azhpc_gfs/blob/master/azuredeploy.json#L261-L288). The extension downloads and calls the [hn-setup_gfs.sh script](https://github.com/tanewill/azhpc_gfs/blob/master/scripts/hn-setup_gfs.sh) which configures the headnode, installs and starts the NFS server, and then launches the [cn-setup_gfs.sh script](https://github.com/tanewill/azhpc_gfs/blob/master/scripts/hn-setup_gfs.sh) which mounts the GFS and NFS file server on all of the compute nodes.

Finally the azuredeploy.json template creates an Azure Files Storage Account which will be used for long term storage. After the ARM template has been fully deployed the create_cluster.sh script is used to get the storage account keys and then mount the storage account to the jumpbox.
    
### Tools
- ARM Template
⋅⋅ Parameters.json
⋅⋅* Placement Groups
* Data transfer tools
..* Fast Data Transfer Tool
..* Blobxfer
..* SCP
* Batch Shipyard
..* Remote File Server
* Gluster
* Scripts
..* Create Cluster script
..* Head node setup script
..* Compute node setup script  

### Configuration
Credentials
File Server Configuration
    
### Execution
	
## Performance
Standard MD's
Premium MD's
Different Servers

## Cost
Compute
MD's
	
## Conclusion

