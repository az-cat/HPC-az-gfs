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
chmod +x create_cluster.sh`
./create_cluster [Resource Group name] [Compute nodes] [TB in GFS File Server]
```
My example: `./create_cluster.sh BTN-TEST-RG01 3 16`
6. At the completion of deployment you will be given an SSH string to access your cluster, change directories into the folder that was created for your Resource Group name and run the string.
* My example: `ssh -i id_rsa_batchshipyardkey azureuser@23.45.67.89`


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
#### Compute Architecture
Inside of Azure the architecture is simple. For the compute cluster use an A9 or H16r/H16mr Virtual Machine Scale Set (VMSS). The nodes are automatically deployed in a single placement group and are connected via Infiniband hardware. VMSS do not have external or public-ips, so if you are creating a new VNET when you create your HPC cluster you will also need to add a 'jumpbox' this box is not the cluster headnode or rank 0, it is simply a way to access your VMSS. A small VM SKU will suffice.
		
#### Storage Architecture
There are four different types of storage that will be used for this HPC cluster.
Physically Attached Storage
NFS Share from the jumpbox
GFS Share from the storage cluster
Azure Files share on the jumpbox
    
### Tools
Create Cluster script
ARM Template
Parameters.json
Placement Groups
Batch Shipyard Remote File Server
Gluster
Scripts
    
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

