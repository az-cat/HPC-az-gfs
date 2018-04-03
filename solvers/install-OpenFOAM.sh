#!/bin/bash
set -x

USER=$1
LICIP=$2
HOST=`hostname`
DOWN=$3
echo $USER,$LICIP,$HOST,$DOWN

export SHARE_DATA=/mnt/resource/scratch
export SHARE_HOME=/home/$USER

wget -q http://azbenchmarkstorage.blob.core.windows.net/foambenchmarkstorage/20170524_PE_OpenFOAM.tgz -O ~/OF_IMPI.tgz
tar -xzf ~/OF_IMPI.tgz -C $SHARE_DATA/applications/
#rm $SHARE_DATA/INSTALLERS/*.tgz

echo source $SHARE_DATA/applications/OpenFOAM/OpenFOAM-4.x/etc/bashrc >>  /home/$USER/.bashrc

chown -R $USER:$USER $SHARE_DATA/*
