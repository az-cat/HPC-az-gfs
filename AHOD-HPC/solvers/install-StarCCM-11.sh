#!/bin/bash
USER=$1
LICIP=$2
HOST=`hostname`
DOWN=$3
echo $USER,$LICIP,$HOST,$DOWN

wget -q http://azbenchmarkstorage.blob.core.windows.net/cdadapcobenchmarkstorage/runAndRecord.java -O /mnt/resource/scratch/benchmark/runAndRecord.java
wget -q http://azbenchmarkstorage.blob.core.windows.net/cdadapcobenchmarkstorage/STAR-CCM+11.06.011_01_linux-x86_64.tar.gz -O /mnt/resource/scratch/INSTALLERS/STAR-CCM+11.06.011_01_linux-x86_64.tar.gz
wget -q http://azbenchmarkstorage.blob.core.windows.net/cdadapcobenchmarkstorage/$DOWN -O /mnt/resource/scratch/benchmark/$DOWN

tar -xf /mnt/resource/scratch/benchmark/$DOWN -C /mnt/resource/scratch/benchmark
tar -xzf /mnt/resource/scratch/INSTALLERS/STAR-CCM+11.06.011_01_linux-x86_64.tar.gz -C /mnt/resource/scratch/INSTALLERS/

cd /mnt/resource/scratch/INSTALLERS/starccm+_11.06.011/

echo export PODKey=$LICIP >> /home/$USER/.bashrc
echo export CDLMD_LICENSE_FILE=1999@flex.cd-adapco.com >> /home/$USER/.bashrc
echo export HOSTS=/home/$USER/bin/hosts
echo #export I_MPI_DAPL_TRANSLATION_CACHE=0 >> /home/$USER/.bashrc
echo '/mnt/resource/scratch/applications/STAR-CCM+11.04.012-R8/star/bin/starccm+ -np 8 -machinefile '$HOSTS' -power -podkey '$PODKey' -rsh ssh -mpi intel -cpubind bandwidth,v -mppflags " -ppn 8 -genv I_MPI_DAPL_PROVIDER=ofa-v2-ib0 -genv I_MPI_PIN_PROCESSOR=8 -genv I_MPI_DAPL_UD=0 -genv I_MPI_DYNAMIC_CONNECTION=0" -batch runAndRecord.java /mnt/resource/scratch/benchmark/*.sim' >> /mnt/resource/scratch/benchmark/runccm_example.sh

sh /mnt/resource/scratch/INSTALLERS/starccm+_11.06.011/STAR-CCM+11.06.011_01_linux-x86_64-2.5_gnu4.8.bin -i silent -DINSTALLDIR=/mnt/resource/scratch/applications -DNODOC=true -DINSTALLFLEX=false
rm -rf /mnt/resource/scratch/INSTALLERS/STAR-CCM+11.06.011_01_linux-x86_64.tar.gz
rm /mnt/resource/scratch/INSTALLERS/*.tgz

chown -R $USER:$USER /mnt/resource/scratch/

