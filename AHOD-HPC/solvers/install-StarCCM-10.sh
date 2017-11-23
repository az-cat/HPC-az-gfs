#!/bin/bash
USER=$1
LICIP=$2
HOST=`hostname`
DOWN=$3
echo $USER,$LICIP,$HOST,$DOWN
mkdir /mnt/resource/scratch/
mkdir /mnt/resource/scratch/applications
mkdir /mnt/resource/scratch/INSTALLERS
mkdir /mnt/resource/scratch/benchmark

wget -q http://azbenchmarkstorage.blob.core.windows.net/cdadapcobenchmarkstorage/runAndRecord.java -O /mnt/resource/scratch/benchmark/runAndRecord.java
wget -q http://azbenchmarkstorage.blob.core.windows.net/cdadapcobenchmarkstorage/STAR-CCM+10.06.010_01_linux-x86_64.tar.gz -O /mnt/resource/scratch/INSTALLERS/STAR-CCM+10.06.010_01_linux-x86_64.tar.gz
wget -q http://azbenchmarkstorage.blob.core.windows.net/cdadapcobenchmarkstorage/$DOWN -O /mnt/resource/scratch/benchmark/$DOWN

tar -xf /mnt/resource/scratch/benchmark/$DOWN -C /mnt/resource/scratch/benchmark
tar -xzf /mnt/resource/scratch/INSTALLERS/STAR-CCM+10.06.010_01_linux-x86_64.tar.gz -C /mnt/resource/scratch/INSTALLERS/

cd /mnt/resource/scratch/INSTALLERS/starccm+_10.06.010/

echo export PODKey=$LICIP >> /home/$USER/.bashrc
echo export CDLMD_LICENSE_FILE=1999@flex.cd-adapco.com >> /home/$USER/.bashrc
echo export HOSTS=/home/$USER/bin/nodenames.txt
echo export INTELMPI_ROOT=/opt/intel/impi/5.1.3.181 >> /home/$USER/.bashrc
echo export I_MPI_FABRICS=shm:dapl >> /home/$USER/.bashrc
echo export I_MPI_DAPL_PROVIDER=ofa-v2-ib0 >> /home/$USER/.bashrc
echo export I_MPI_ROOT=/opt/intel/compilers_and_libraries_2016.2.181/linux/mpi >> /home/$USER/.bashrc
echo export PATH=/mnt/resource/scratch/applications/STAR-CCM+10.06.010/star/bin:/opt/intel/impi/5.1.3.181/bin64:$PATH >> /home/$USER/.bashrc
echo export I_MPI_DYNAMIC_CONNECTION=0 >> /home/$USER/.bashrc
echo '/mnt/resource/scratch/applications/STAR-CCM+10.06.010/star/bin/starccm+ -np 8 -machinefile '$HOSTS' -power -podkey '$PODKey' -rsh ssh -mpi intel -cpubind bandwidth,v -mppflags " -ppn 8 -genv I_MPI_DAPL_PROVIDER=ofa-v2-ib0 -genv I_MPI_PIN_PROCESSOR=8 -genv I_MPI_DAPL_UD=0 -genv I_MPI_DYNAMIC_CONNECTION=0" -batch runAndRecord.java /mnt/resource/scratch/benchmark/*.sim' >> /mnt/resource/scratch/benchmark/runccm_example.sh

sh /mnt/resource/scratch/INSTALLERS/starccm+_10.06.010/STAR-CCM+10.06.010_01_linux-x86_64-2.5_gnu4.8.bin -i silent -DINSTALLDIR=/mnt/resource/scratch/applications -DNODOC=true -DINSTALLFLEX=false
rm -rf /mnt/resource/scratch/INSTALLERS/STAR-CCM+10.06.010_01_linux-x86_64.tar.gz
rm /mnt/resource/scratch/*.tgz
chown -R $USER:$USER /mnt/resource/scratch/*
chown -R $USER:$USER /mnt/nfsshare

