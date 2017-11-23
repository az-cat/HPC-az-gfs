#!/bin/bash
USER=$1
LICIP=$2
DOWN=$3
HOST=`hostname`
echo $USER,$LICIP,$HOST

yum install -y redhat-lsb-core
yum install -y compat-libstdc++-33.i686
yum install -y ksh

mkdir /mnt/resource/scratch/applications
mkdir /mnt/resource/scratch/INSTALLERS
mkdir /mnt/resource/scratch/benchmark

wget -q http://azbenchmarkstorage.blob.core.windows.net/abaqusbenchmarkstorage/2016.AM_SIM_Abaqus.AllOS.1-3.tar -O /mnt/resource/scratch/2016.AM_SIM_Abaqus.AllOS.1-3.tar
wget -q http://azbenchmarkstorage.blob.core.windows.net/abaqusbenchmarkstorage/2016.AM_SIM_Abaqus.AllOS.2-3.tar -O /mnt/resource/scratch/2016.AM_SIM_Abaqus.AllOS.2-3.tar
wget -q http://azbenchmarkstorage.blob.core.windows.net/abaqusbenchmarkstorage/2016.AM_SIM_Abaqus.AllOS.3-3.tar -O /mnt/resource/scratch/2016.AM_SIM_Abaqus.AllOS.3-3.tar
wget -q http://azbenchmarkstorage.blob.core.windows.net/abaqusbenchmarkstorage/$DOWN -O /mnt/resource/scratch/benchmark/$DOWN

tar -xf /mnt/resource/scratch/2016.AM_SIM_Abaqus.AllOS.1-3.tar -C /mnt/resource/scratch/INSTALLERS/
tar -xf /mnt/resource/scratch/2016.AM_SIM_Abaqus.AllOS.2-3.tar -C /mnt/resource/scratch/INSTALLERS/
tar -xf /mnt/resource/scratch/2016.AM_SIM_Abaqus.AllOS.3-3.tar -C /mnt/resource/scratch/INSTALLERS/
tar -xf /mnt/resource/scratch/benchmark/$DOWN -C /mnt/resource/scratch/benchmark

echo USE THE BELOW COMMANDS AND PATHS FOR EACH STEP IN THE INSTALLATION PROCESS > /mnt/resource/scratch/INSTALLERS/install_abq.txt
echo ksh /mnt/resource/scratch/INSTALLERS/AM_SIM_Abaqus.AllOS/1/3DEXPERIENCE_AbaqusSolver/Linux64/1/StartTUI.sh >> /mnt/resource/scratch/INSTALLERS/install_abq.txt
echo	/mnt/resource/scratch/applications/DassaultSystemes/SimulationServices/V6R2016x >>  /mnt/resource/scratch/INSTALLERS/install_abq.txt
echo  >>  /mnt/resource/scratch/INSTALLERS/install_abq.txt
echo ksh /mnt/resource/scratch/INSTALLERS/AM_SIM_Abaqus.AllOS/1/SIMULIA_Abaqus_CAE/Linux64/1/StartTUI.sh >>  /mnt/resource/scratch/INSTALLERS/install_abq.txt
echo	/mnt/resource/scratch/applications/SIMULIA/CAE/2016 >>  /mnt/resource/scratch/INSTALLERS/install_abq.txt
echo	/mnt/resource/scratch/applications/DassaultSystemes/SimulationServices/V6R2016x >>  /mnt/resource/scratch/INSTALLERS/install_abq.txt
echo	/mnt/resource/scratch/applications/DassaultSystemes/SIMULIA/Commands >>  /mnt/resource/scratch/INSTALLERS/install_abq.txt
echo /mnt/resource/scratch/temp >>  /mnt/resource/scratch/INSTALLERS/install_abq.txt
echo  >>  /mnt/resource/scratch/INSTALLERS/install_abq.txt
echo LICENSE IS AT $LICIP >>  /mnt/resource/scratch/INSTALLERS/install_abq.txt

echo export HOSTS=/home/$USER/bin/nodenames.txt
echo export INTELMPI_ROOT=/opt/intel/impi/5.1.3.181 >> /home/$USER/.bashrc
echo export I_MPI_FABRICS=shm:dapl >> /home/$USER/.bashrc
echo export I_MPI_DAPL_PROVIDER=ofa-v2-ib0 >> /home/$USER/.bashrc
echo export I_MPI_ROOT=/opt/intel/compilers_and_libraries_2016.2.181/linux/mpi >> /home/$USER/.bashrc
echo export PATH=/mnt/resource/scratch/applications/DassaultSystemes/SIMULIA/Commands:$PATH >> /home/$USER/.bashrc
echo export I_MPI_DYNAMIC_CONNECTION=0 >> /home/$USER/.bashrc

chown -R $USER:$USER /mnt/resource/scratch/*
chown -R $USER:$USER /mnt/nfsshare

