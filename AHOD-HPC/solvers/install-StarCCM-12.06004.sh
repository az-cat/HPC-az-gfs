#!/bin/bash
USER=$1
LICIP=$2
HOST=`hostname`
DOWN=$3
echo $USER,$LICIP,$HOST,$DOWN

export SHARE_DATA=/mnt/resource/scratch
export SHARE_HOME=/home/$USER


wget -q http://azbenchmarkstorage.blob.core.windows.net/cdadapcobenchmarkstorage/runAndRecord.java -O $SHARE_DATA/benchmark/runAndRecord.java
wget -q http://azbenchmarkstorage.blob.core.windows.net/cdadapcobenchmarkstorage/STAR-CCM+12.06.004_01_linux-x86_64.tar.gz -O $SHARE_DATA/INSTALLERS/STAR-CCM+12.06.004_01_linux-x86_64.tar.gz
wget -q http://azbenchmarkstorage.blob.core.windows.net/cdadapcobenchmarkstorage/$DOWN -O $SHARE_DATA/benchmark/$DOWN

tar -xf $SHARE_DATA/benchmark/$DOWN -C $SHARE_DATA/benchmark
tar -xzf $SHARE_DATA/INSTALLERS/STAR-CCM+12.06.004_01_linux-x86_64.tar.gz -C $SHARE_DATA/INSTALLERS/

cd $SHARE_DATA/INSTALLERS/starccm+_12.06.004/

echo export PODKey=$LICIP >> $SHARE_HOME/.bashrc
echo export CDLMD_LICENSE_FILE=1999@flex.cd-adapco.com >> $SHARE_HOME/.bashrc
echo export HOSTS=$SHARE_HOME/bin/nodenames.txt
echo export INTELMPI_ROOT=/opt/intel/impi/5.1.3.181 >> $SHARE_HOME/.bashrc
echo export I_MPI_FABRICS=shm:dapl >> $SHARE_HOME/.bashrc
echo export I_MPI_DAPL_PROVIDER=ofa-v2-ib0 >> $SHARE_HOME/.bashrc
echo export I_MPI_ROOT=/opt/intel/compilers_and_libraries_2016.2.181/linux/mpi >> $SHARE_HOME/.bashrc
echo export PATH=$SHARE_DATA/applications/12.06.004/STAR-CCM+12.06.004/star/bin:/opt/intel/impi/5.1.3.181/bin64:$PATH >> $SHARE_HOME/.bashrc
echo export I_MPI_DYNAMIC_CONNECTION=0 >> $SHARE_HOME/.bashrc

echo '$SHARE_DATA/applications/12.06.004/STAR-CCM+12.06.004/star/bin/starccm+ -np 8 -machinefile $HOSTS -power -podkey '$PODKey' -rsh ssh -mpi intel -cpubind bandwidth,v -mppflags " -ppn 8 -genv I_MPI_DAPL_PROVIDER=ofa-v2-ib0 -genv I_MPI_PIN_PROCESSOR=8 -genv I_MPI_DAPL_UD=0 -genv I_MPI_DYNAMIC_CONNECTION=0" -batch runAndRecord.java $SHARE_DATA/benchmark/*.sim' >> $SHARE_DATA/benchmark/runccm_example.sh

sh $SHARE_DATA/INSTALLERS/starccm+_12.06.004/STAR-CCM+12.06.004_01_linux-x86_64-2.5_gnu4.8.bin -i silent -DINSTALLDIR=$SHARE_DATA/applications -DNODOC=true -DINSTALLFLEX=false

#rm -rf $SHARE_DATA/INSTALLERS/STAR-CCM+12.06.004_01_linux-x86_64.tar.gz
#rm $SHARE_DATA/*.tgz

chown -R $USER:$USER /mnt/resource/scratch/*
chown -R $USER:$USER /mnt/nfsshare
