#!/bin/bash
#set -x

RG=$1
COMPNODES=$2
NEWID=`dbus-uuidgen | cut -c 1-5`
LOC=northcentralus
RUNDIR=`date +%Y%m%d_%H%M%S`_$RG
user=azureuser

#Size of GFS in TB
GFSSIZE=4
#GET SHIPYARD
wget -O https://github.com/Azure/batch-shipyard/releases/download/3.0.1/batch-shipyard-3.0.1-cli-linux-x86_64.gz shipyard
chmod +x shipyard

mkdir -p $RUNDIR
cp -r scripts $RUNDIR/
cp *.yaml $RUNDIR/
cp *.json $RUNDIR/
cp create_cluster.sh $RUNDIR/
cd $RUNDIR
############################################

cp fs.yaml .fs.yaml.orig
echo ------------------------- `date +%F" "%T` Creating $RG using $NEWID 
sed -i "s/_RGNAME/$RG/g" fs.yaml
sed -i "s/_clustername/storage$NEWID/g" fs.yaml
sed -i "s/_LOCACTION/$LOC/g" fs.yaml
#sed -i "s/_privatekeyloc/$KEY/g" credentials.yaml
start_time=`date +%F" "%T`

#BATCH SHIPYARD COMMANDS
echo ------------------------- `date +%F" "%T` Adding disks 
SHIPYARD_CONFIGDIR=. shipyard fs disks add
az group update -n $RG --set tags.Type=Compute_with_GFS tags.LaunchTime=`date +%F_%T`
echo ------------------------- `date +%F" "%T` Creating servers 
SHIPYARD_CONFIGDIR=. shipyard fs cluster add -y mystoragecluster 

#DOWNLOAD BLOBXFER AND GET SOME SAMPLE DATA
#echo ------------------------- `date +%F" "%T` Downloading data 
#shipyard fs cluster ssh mystoragecluster 'wget -q https://github.com/Azure/blobxfer/releases/download/1.0.0/blobxfer-1.0.0-linux-x86_64 -O blobxfer && ls -all && chmod +x blobxfer && ./blobxfer download --mode file --storage-account btnglusterfiletest --sas "JdSoMKt8/IfUiKlnWTPb0CEJp269JspIbUYbgTZkrB+kkruhYOicbV5mx4azznuYEp7Xgm1fzZs3uJB0ysJY4g==" --remote-path datahydrate --local-path . --file-attributes && ls -all'

#GET THE PRIVATE IP ADDRESS OF THE FIRST GFS NODE TO BE USED FOR THE JUMPBOX GLUSTER MOUNT
nicname=`az network nic list -g $RG --query "[?contains(name,'-ni0')].{ name: name }" -o tsv`
nicprivip=`az network nic show -g $RG -n $nicname --query [ipConfigurations[0].privateIpAddress] -o tsv`

#CREATE COMPUTE CLUSTER USING THE TEMPLATES
echo ------------------------- `date +%F" "%T` Creating Compute Cluster
cp parameters.json .parameters.json.orig
rsakey=`cat id_rsa_shipyard_remotefs.pub`
sed -i "s/_VMSSNAME/comp$NEWID/g" parameters.json
sed -i "s/_COMPNODES/$COMPNODES/g" parameters.json
sed -i "s/_RGNAME/$RG/g" parameters.json
sed -i "s/_GFSIP/$nicprivip/g" parameters.json
sed -i "s%_RSAKEY%$rsakey%g" parameters.json
az group deployment create --name computedeployment --resource-group $RG --template-file azuredeploy.json --parameters @parameters.json #> /dev/null 2>&1

#GET IP AND SETUP LONGTERM STORAGE ON REMOTE HOST
jbnicname=`az network nic list -g $RG --query "[?contains(name,'-nic')].{ name: name }" -o tsv`
jbpipid=`az network nic show -g $RG -n $jbnicname --query [ipConfigurations[0].publicIpAddress.id] -o tsv`
jbpip=`az resource show --ids $jbpipid --query [properties.ipAddress] -o tsv`
ltsName=`az storage account list --resource-group $RG --query [0].[name] -o tsv`
ltsKey=`az storage account keys list --resource-group $RG --account-name $ltsName --query '[0].{Key:value}' --output tsv`
az storage share create --name longtermstorage --quota 500 --account-name $ltsName --account-key $ltsKey
ssh -T -i id_rsa_shipyard_remotefs $user@$jbpip << EOSSH
sudo sh -c "echo //$ltsName.file.core.windows.net/longtermstorage /mnt/lts cifs vers=3.0,username=$ltsName,password=$ltsKey,dir_mode=0777,file_mode=0777 | tee -a /etc/fstab && mount -a"
EOSSH

#REPORT OUT COMPUTEJB PUBLIC IP
echo ------------------------- connect to jumpbox ssh -i id_rsa_shipyard_remotefs azureuser@$jbpip
echo ------------------------- start time $start_time
echo -------------------------   end time `date +%F" "%T`
