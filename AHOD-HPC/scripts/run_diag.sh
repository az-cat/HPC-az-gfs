sudo yum -yq install gnuplot
wget http://azbenchmarkstorage.blob.core.windows.net/testingsuite/20170501_testsuite.tgz -O /mnt/resource/scratch/diag.tgz
cd /mnt/resource/scratch/
tar -xzf /mnt/resource/scratch/diag.tgz
cd mpitestsuite-1.5