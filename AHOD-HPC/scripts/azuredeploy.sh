#!/bin/bash

set -x

if [[ $(id -u) -ne 0 ]] ; then
    echo "Must be run as root"
    exit 1
fi

if [ $# != 8 ]; then
    echo "Usage: $0 <MasterHostname> <WorkerHostnamePrefix> <WorkerNodeCount> <HPCUserName> <TemplateBaseUrl> <solver> <model>"
    exit 1
fi

# Set user args
MASTER_HOSTNAME=$1
WORKER_HOSTNAME_PREFIX=$2
WORKER_COUNT=$3
SOLVER=$6
DOWN=$7
LICIP=$8
TEMPLATE_BASE_URL="$5"
LAST_WORKER_INDEX=$(($WORKER_COUNT - 1))

# Shares
SHARE_HOME=/mnt/resource/home
SHARE_DATA=/mnt/resource/scratch

# Hpc User
HPC_USER=$4
HPC_UID=7007
HPC_GROUP=hpc
HPC_GID=7007


# Returns 0 if this node is the master node.
#
is_master()
{
    hostname | grep "$MASTER_HOSTNAME"
    return $?
}


# Installs all required packages.
#
install_pkgs()
{
    yum -y install epel-release
    #yum -y install zlib zlib-devel bzip2 bzip2-devel bzip2-libs openssl openssl-devel openssl-libs gcc gcc-c++ nfs-utils rpcbind mdadm wget python-pip
    yum -y install nfs-utils sshpass nmap htop npm
    yum groupinstall -y "X Window System"
}

# Creates and exports two shares on the master nodes:
#
# /share/home (for HPC user)
# /share/data
#
# These shares are mounted on all worker nodes.
#
setup_shares()
{
    mkdir -p $SHARE_HOME
    mkdir -p $SHARE_DATA
    mkdir -p $SHARE_DATA/applications
    mkdir -p $SHARE_DATA/INSTALLERS
    mkdir -p $SHARE_DATA/benchmark

    if is_master; then
        #setup_data_disks $SHARE_DATA
        echo Setting up Master Share
        echo "$SHARE_HOME    *(rw,sync,no_root_squash,no_all_squash)" | tee -a /etc/exports
        echo "$SHARE_DATA    *(rw,sync,no_root_squash,no_all_squash)" | tee -a /etc/exports
        chmod -R 777 $SHARE_DATA

        systemctl enable rpcbind || echo "Already enabled"
        systemctl enable nfs-server || echo "Already enabled"
        systemctl enable nfs-lock
        systemctl enable nfs-idmap
        systemctl start rpcbind || echo "Already enabled"
        systemctl start nfs-server || echo "Already enabled"
        systemctl start nfs-lock
        systemctl start nfs-idmap
        systemctl restart nfs-server

        wget https://raw.githubusercontent.com/tanewill/AHOD-HPC/master/full-pingpong.sh -O $SHARE_DATA/full-pingpong.sh
    
    else
        echo mounting
        echo "$MASTER_HOSTNAME:$SHARE_HOME $SHARE_HOME    nfs     defaults 0 0" | tee -a /etc/fstab
        echo "$MASTER_HOSTNAME:$SHARE_DATA $SHARE_DATA    nfs     defaults 0 0" | tee -a /etc/fstab

        mount -a
        mount | grep "^master:$SHARE_HOME"
        mount | grep "^master:$SHARE_DATA"
    fi
}


# Adds a common HPC user to the node and configures public key SSh auth.
# The HPC user has a shared home directory (NFS share on master) and access
# to the data share.
#
setup_hpc_user()
{
    # disable selinux
    sed -i 's/enforcing/disabled/g' /etc/selinux/config
    setenforce permissive
    
    groupadd -g $HPC_GID $HPC_GROUP

    # Don't require password for HPC user sudo
    echo "$HPC_USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    
    # Disable tty requirement for sudo
    sed -i 's/^Defaults[ ]*requiretty/# Defaults requiretty/g' /etc/sudoers

    if is_master; then
    
        useradd -c "HPC User" -g $HPC_GROUP -m -d $SHARE_HOME/$HPC_USER -s /bin/bash -u $HPC_UID $HPC_USER

        mkdir -p $SHARE_HOME/$HPC_USER/.ssh
        
        # Configure public key auth for the HPC user
        ssh-keygen -t rsa -f $SHARE_HOME/$HPC_USER/.ssh/id_rsa -q -P ""
        cat $SHARE_HOME/$HPC_USER/.ssh/id_rsa.pub > $SHARE_HOME/$HPC_USER/.ssh/authorized_keys

        echo "Host *" > $SHARE_HOME/$HPC_USER/.ssh/config
        echo "    StrictHostKeyChecking no" >> $SHARE_HOME/$HPC_USER/.ssh/config
        echo "    UserKnownHostsFile /dev/null" >> $SHARE_HOME/$HPC_USER/.ssh/config
        echo "    PasswordAuthentication no" >> $SHARE_HOME/$HPC_USER/.ssh/config

        # Fix .ssh folder ownership
        chown -R $HPC_USER:$HPC_GROUP $SHARE_HOME/$HPC_USER

        # Fix permissions
        chmod 700 $SHARE_HOME/$HPC_USER/.ssh
        chmod 644 $SHARE_HOME/$HPC_USER/.ssh/config
        chmod 644 $SHARE_HOME/$HPC_USER/.ssh/authorized_keys
        chmod 600 $SHARE_HOME/$HPC_USER/.ssh/id_rsa
        chmod 644 $SHARE_HOME/$HPC_USER/.ssh/id_rsa.pub
        
        # Give hpc user access to data share
        chown $HPC_USER:$HPC_GROUP $SHARE_DATA
    else
        useradd -c "HPC User" -g $HPC_GROUP -d $SHARE_HOME/$HPC_USER -s /bin/bash -u $HPC_UID $HPC_USER
    fi
}

# Sets all common environment variables and system parameters.
#
setup_env()
{
    # Set unlimited mem lock
    echo "$HPC_USER hard memlock unlimited" >> /etc/security/limits.conf
    echo "$HPC_USER soft memlock unlimited" >> /etc/security/limits.conf

    # symbolic linking of directories
    ln -s /opt/intel/impi/5.1.3.181/intel64/bin/ /opt/intel/impi/5.1.3.181/bin
    ln -s /opt/intel/impi/5.1.3.181/lib64/ /opt/intel/impi/5.1.3.181/lib
    
    if is_master; then
        # Intel MPI config for IB
        echo "# IB Config for MPI" >> $SHARE_HOME/$HPC_USER/.bashrc
        echo export INTELMPI_ROOT=/opt/intel/impi/5.1.3.181 >> $SHARE_HOME/$HPC_USER/.bashrc
        echo export I_MPI_FABRICS=shm:dapl >> $SHARE_HOME/$HPC_USER/.bashrc
        echo export I_MPI_DAPL_PROVIDER=ofa-v2-ib0 >> $SHARE_HOME/$HPC_USER/.bashrc
        echo export I_MPI_ROOT=/opt/intel/compilers_and_libraries_2016.2.181/linux/mpi >> $SHARE_HOME/$HPC_USER/.bashrc
        echo export PATH=/opt/intel/impi/5.1.3.181/bin64:$PATH >> $SHARE_HOME/$HPC_USER/.bashrc
        echo export I_MPI_DYNAMIC_CONNECTION=0 >> $SHARE_HOME/$HPC_USER/.bashrc
        echo export I_MPI_PIN_PROCESSOR=8 >> $SHARE_HOME/$HPC_USER/.bashrc
        echo export I_MPI_DAPL_TRANSLATION_CACHE=0 >> $SHARE_HOME/$HPC_USER/.bashrc
    else
        echo 'already Set'
    fi
}

get_cluster()
{
    IP=`ifconfig eth0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'`
    localip=`echo $IP | cut --delimiter='.' -f -3`
    #nmap -sn $localip.* | grep $localip. | awk '{print $5}' > $SHARE_HOME/$HPC_USER/nodeips.txt
    #for NAME in `cat $SHARE_HOME/$HPC_USER/nodeips.txt`; do ssh -o ConnectTimeout=2 $NAME 'hostname' >> $SHARE_HOME/$HPC_USER/nodenames.txt;done
    hostname >> $SHARE_DATA/nodenames.txt
    echo $IP >> $SHARE_DATA/nodeips.txt
}

install_ganglia(){
    chmod +x install_ganglia.sh
    ./install_ganglia.sh $MASTER_HOSTNAME azure 8649
}

install_solver()
{
    if is_master; then
        chmod +x install-$SOLVER.sh
        source install-$SOLVER.sh $SHARE_HOME/$HPC_USER $LICIP $DOWN $SHARE_DATA
    else
        echo 'not master'
    fi
}

install_pkgs
setup_shares
setup_hpc_user
setup_env
get_cluster
install_ganglia
install_solver