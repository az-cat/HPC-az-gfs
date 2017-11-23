#!/bin/bash
USER=$1
LICIP=$2
DOWN=$3
HOST=`hostname`
echo $USER,$LICIP,$HOST,$DOWN

mkdir -p /mnt/resource/scratch/INSTALLERS/ANSYS

wget -q http://azbenchmarkstorage.blob.core.windows.net/ansysbenchmarkstorage/$DOWN -O /mnt/resource/scratch/benchmark/$DOWN
wget -q https://raw.githubusercontent.com/tanewill/5clickTemplates/master/RawANSYSCluster/runme.jou -O /mnt/resource/scratch/benchmark/runme.jou
wget -q http://azbenchmarkstorage.blob.core.windows.net/ansysbenchmarkstorage/ANSYS.tgz -O /mnt/resource/scratch/ANSYS.tgz
tar -xzf /mnt/resource/scratch/ANSYS.tgz -C /mnt/resource/scratch/INSTALLERS
tar -xvf /mnt/resource/scratch/benchmark/$DOWN -C /mnt/resource/scratch/benchmark
mv /mnt/resource/scratch/benchmark/*.dat.gz /mnt/resource/scratch/benchmark/benchmark.dat.gz
mv /mnt/resource/scratch/benchmark/*.cas.gz /mnt/resource/scratch/benchmark/benchmark.cas.gz

cd /mnt/resource/scratch/INSTALLERS/ANSYS/
mkdir -p /mnt/resource/scratch/applications/ansys_inc/shared_files/licensing/

echo SERVER=1055@$LICIP > /mnt/resource/scratch/applications/ansys_inc/shared_files/licensing/ansyslmd.ini
echo ANSYSLI_SERVERS=2325@$LICIP >> /mnt/resource/scratch/applications/ansys_inc/shared_files/licensing/ansyslmd.ini

echo export FLUENT_HOSTNAME=$HOST >> /home/$USER/.bashrc
echo export INTELMPI_ROOT=/opt/intel/impi/5.1.3.181 >> /home/$USER/.bashrc
echo export I_MPI_FABRICS=shm:dapl >> /home/$USER/.bashrc
echo export I_MPI_DAPL_PROVIDER=ofa-v2-ib0 >> /home/$USER/.bashrc
echo export I_MPI_ROOT=/opt/intel/compilers_and_libraries_2016.2.181/linux/mpi >> /home/$USER/.bashrc
echo export PATH=/mnt/resource/scratch/applications/ansys_inc/v172/fluent/bin:/opt/intel/impi/5.1.3.181/bin64:$PATH >> /home/$USER/.bashrc
echo export I_MPI_DYNAMIC_CONNECTION=0 >> /home/$USER/.bashrc

chown -R $1:$1 /mnt/resource/scratch

source /mnt/resource/scratch/INSTALLERS/ANSYS/INSTALL -silent -install_dir "/mnt/resource/scratch/applications/ansys_inc/" -fluent
#source /mnt/resource/scratch/INSTALLERS/ANSYS/INSTALL -silent -install_dir "/mnt/resource/scratch/applications/ansys_inc/" -cfx




