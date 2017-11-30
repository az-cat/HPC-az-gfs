#!/bin/bash
#set -x
#set +e

SOLVER=$1
USER=$2
PASS=$3
DOWN=$4
LICIP=$5
GFSIP=$6

IP=`ifconfig eth0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'`
localip=`echo $IP | cut --delimiter='.' -f -3`
myhost=`hostname`

echo User is: $USER
echo Pass is: $PASS
echo License IP is: $LICIP
echo Model is: $DOWN

cat << EOF >> /etc/security/limits.conf
*               hard    memlock         unlimited
*               soft    memlock         unlimited
*               hard    nofile          65535
*               soft    nofile          65535
EOF

#Create directories needed for configuration
mkdir -p /home/$USER/.ssh
mkdir -p /home/$USER/bin
mkdir -p /mnt/scratch/applications
mkdir -p /mnt/scratch/INSTALLERS
mkdir -p /mnt/scratch/benchmark
mkdir -p /mnt/lts1
mkdir -p /mnt/lts2
mkdir -p /mnt/lts3
mkdir -p /mnt/gfs

ln -s /mnt/scratch/ /home/$USER/scratch
ln -s /mnt/gfs /home/$USER/gfs
ln -s /mnt/lts /home/$USER/lts

#Following lines are only needed if the head node is an RDMA connected VM
#impi_version=`ls /opt/intel/impi`
#source /opt/intel/impi/${impi_version}/bin64/mpivars.sh
#ln -s /opt/intel/impi/${impi_version}/intel64/bin/ /opt/intel/impi/${impi_version}/bin
#ln -s /opt/intel/impi/${impi_version}/lib64/ /opt/intel/impi/${impi_version}/lib

#Install needed packages
yum check-update
yum install -y -q nfs-utils pdsh epel-release sshpass nmap htop pdsh screen git psmisc glusterfs glusterfs-fuse attr cifs-utils
yum install -y -q gcc libffi-devel python-devel openssl-devel --disableexcludes=all
yum groupinstall -y -q "X Window System"

#Use ganglia install script to install ganglia, this is downloaded via the ARM template
chmod +x install_ganglia.sh
./install_ganglia.sh $myhost azure 8649

#sudo mount -t cifs //myStorageAccount.file.core.windows.net/mystorageshare /mnt/mymountdirectory -o vers=3.0,username=mystorageaccount,password=mystorageaccountkey,dir_mode=0777,file_mode=0777
#Setup the NFS server, mount the gluster, get Long Term Storage Keys
echo "/mnt/scratch $localip.*(rw,sync,no_root_squash,no_all_squash)" | tee -a /etc/exports
echo "$GFSIP:/gv0       /mnt/gfs  glusterfs   defaults,_netdev  0  0" | tee -a /etc/fstab

systemctl enable rpcbind
systemctl enable nfs-server
systemctl enable nfs-lock
systemctl enable nfs-idmap
systemctl start rpcbind
systemctl start nfs-server
systemctl start nfs-lock
systemctl start nfs-idmap
systemctl restart nfs-server
mount -a

mv clusRun.sh cn-setup_gfs.sh /home/$USER/bin
chmod +x /home/$USER/bin/*.sh
chown $USER:$USER /home/$USER/bin
nmap -sn $localip.* | grep $localip. | awk '{print $5}' > /home/$USER/bin/hostips
export WCOLL=/home/$USER/bin/hostips

sed -i '/\<'$IP'\>/d' /home/$USER/bin/hostips
sed -i '/\<10.0.0.1\>/d' /home/$USER/bin/hostips

echo -e  'y\n' | ssh-keygen -f /home/$USER/.ssh/id_rsa -t rsa -N ''
echo 'Host *' >> /home/$USER/.ssh/config
echo 'StrictHostKeyChecking no' >> /home/$USER/.ssh/config

chmod 400 /home/$USER/.ssh/config
chown $USER:$USER /home/$USER/.ssh/config

mkdir -p ~/.ssh
echo 'Host *' >> ~/.ssh/config
echo 'StrictHostKeyChecking no' >> ~/.ssh/config
chmod 400 ~/.ssh/config

for NAME in `cat /home/$USER/bin/hostips`; do sshpass -p $PASS ssh -o ConnectTimeout=2 $USER@$NAME 'hostname' >> /home/$USER/bin/hosts;done
NAMES=`cat /home/$USER/bin/hostips` #names from names.txt file

for name in `cat /home/$USER/bin/hostips`; do
        sshpass -p "$PASS" ssh $USER@$name "mkdir -p .ssh"
        cat /home/$USER/.ssh/config | sshpass -p "$PASS" ssh $USER@$name "cat >> .ssh/config"
        cat /home/$USER/.ssh/id_rsa | sshpass -p "$PASS" ssh $USER@$name "cat >> .ssh/id_rsa"
        cat /home/$USER/.ssh/id_rsa.pub | sshpass -p "$PASS" ssh $USER@$name "cat >> .ssh/authorized_keys"
        sshpass -p "$PASS" ssh $USER@$name "chmod 700 .ssh; chmod 640 .ssh/authorized_keys; chmod 400 .ssh/config; chmod 400 .ssh/id_rsa"
        cat /home/$USER/bin/hostips | sshpass -p "$PASS" ssh $USER@$name "cat >> /home/$USER/hostips"
        cat /home/$USER/bin/hosts | sshpass -p "$PASS" ssh $USER@$name "cat >> /home/$USER/hosts"
        cat /home/$USER/bin/cn-setup_gfs.sh | sshpass -p "$PASS" ssh $USER@$name "cat >> /home/$USER/cn-setup_gfs.sh"
        sshpass -p $PASS ssh -t -t -o ConnectTimeout=2 $USER@$name 'echo "'$PASS'" | sudo -S sh /home/'$USER'/cn-setup_gfs.sh '$IP $USER $myhost $GFSIP & > /dev/null 2>&1
done

cp /home/$USER/bin/hosts /mnt/scratch/hosts
chown -R $USER:$USER /home/
chown -R $USER:$USER /mnt/

chmod -R 744 /mnt/scratch/

# Don't require password for HPC user sudo
echo "$USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    
# Disable tty requirement for sudo
sed -i 's/^Defaults[ ]*requiretty/# Defaults requiretty/g' /etc/sudoers

name=`head -1 /home/$USER/bin/hostips`
cat install-$SOLVER.sh | sshpass -p "$PASS" ssh $USER@$name "cat >> /home/$USER/install-$SOLVER.sh"
sshpass -p $PASS ssh -t -t -o ConnectTimeout=2 $USER@$name source install-$SOLVER.sh $USER $LICIP $DOWN > script_output


