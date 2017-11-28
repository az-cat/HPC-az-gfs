#!/bin/bash
#set -x
#set +e

echo ##################################################
echo ############# Compute Node Setup #################
echo ##################################################
IPPRE=$1
USER=$2
GANG_HOST=$3
GFSIP=$4

HOST=`hostname`
if grep -q $IPPRE /etc/fstab; then FLAG=MOUNTED; else FLAG=NOTMOUNTED; fi


if [ $FLAG = NOTMOUNTED ] ; then 
    echo $FLAG
    echo installing NFS and mounting
    yum install -y -q nfs-utils pdsh epel-release sshpass nmap htop pdsh screen git psmisc glusterfs glusterfs-fuse attr
    yum groupinstall -y -q "X Window System"

    mkdir -p /mnt/nfsshare
    mkdir -p /mnt/scratch
    mkdir -p /mnt/gfs/
    mkdir -p /mnt/lts/

    #CREATE AND MOUNT SHARES
    chmod 777 /mnt/nfsshare
    systemctl enable rpcbind
    systemctl enable nfs-server
    systemctl enable nfs-lock
    systemctl enable nfs-idmap
    systemctl start rpcbind
    systemctl start nfs-server
    systemctl start nfs-lock
    systemctl start nfs-idmap
    localip=`hostname -i | cut --delimiter='.' -f -3`
    echo "$IPPRE:/mnt/nfsshare    /mnt/nfsshare   nfs defaults 0 0" | tee -a /etc/fstab
    echo "$IPPRE:/mnt/scratch    /mnt/scratch   nfs defaults 0 0" | tee -a /etc/fstab
    echo "$GFSIP:/gv0       /mnt/gfs  glusterfs   defaults,_netdev  0  0" | tee -a /etc/fstab

    mount -a
    df -h


    cat << EOF >> /home/$USER/.bashrc
        if [ -d "/opt/intel/impi" ]; then
            source /opt/intel/impi/*/bin64/mpivars.sh
        fi
        export FLUENT_HOSTNAME=$HOST
        export PATH=/home/$USER/bin:\$PATH
        export INTELMPI_ROOT=/opt/intel/impi/${impi_version}
        export I_MPI_FABRICS=shm:dapl
        export I_MPI_DAPL_PROVIDER=ofa-v2-ib0
        export I_MPI_DYNAMIC_CONNECTION=0
EOF
        #SET ENV VARS
#    echo e xport FLUENT_HOSTNAME=$HOST >> /home/$USER/.bashrc
#    echo  >> /home/$USER/.bashrc
#    echo export I_MPI_FABRICS=shm:dapl >> /home/$USER/.bashrc
#    echo export I_MPI_DAPL_PROVIDER=ofa-v2-ib0 >> /home/$USER/.bashrc
#    echo export I_MPI_ROOT=/opt/intel/compilers_and_libraries_2016.2.181/linux/mpi >> /home/$USER/.bashrc
#    echo export MPI_ROOT=$I_MPI_ROOT >> /home/$USER/.bashrc
#    echo export PATH=/opt/intel/impi/${impi_version}/bin64:$PATH >> /home/$USER/.bashrc

#    echo #export I_MPI_PIN_PROCESSOR=8 >> /home/$USER/.bashrc
#    echo #export I_MPI_DAPL_TRANSLATION_CACHE=0 only un comment if you are having application stability issues >> /home/$USER/.bashrc
    
    #chown -R $USER:$USER /mnt/
    wget -q https://raw.githubusercontent.com/tanewill/AHOD-HPC/master/scripts/full-pingpong.sh -O /home/$USER/full-pingpong.sh
    wget -q https://raw.githubusercontent.com/tanewill/AHOD-HPC/master/scripts/install_ganglia.sh -O /home/$USER/install_ganglia.sh
    chmod +x /home/$USER/install_ganglia.sh
    sh /home/$USER/install_ganglia.sh $GANG_HOST azure 8649


    chmod +x /home/$USER/full-pingpong.sh
    chown $USER:$USER /home/$USER/full-pingpong.sh

    ln -s /mnt/scratch/ /home/$USER/scratch
    ln -s /mnt/gfs/ /home/$USER/gfs
    ln -s /mnt/lts/ /home/$USER/lts

    # Don't require password for HPC user sudo
    echo "$USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    
    # Disable tty requirement for sudo
    sed -i 's/^Defaults[ ]*requiretty/# Defaults requiretty/g' /etc/sudoers 

else
    echo already mounted
    df | grep $IPPRE
fi
