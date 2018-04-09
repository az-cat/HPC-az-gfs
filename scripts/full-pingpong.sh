#!/bin/bash
# Example usage: ./full-pingpong.sh | grep -e ' 512 ' -e NODES -e usec

declare -A matrix
mpiversion=`ls /opt/intel/impi/`
source /opt/intel/impi/$mpiversion/bin64/mpivars.sh
for NODE in `cat ~/hosts`; \
    do for NODE2 in `cat ~/hosts`; \
        do matrix[$NODE,$NODE2]=`/opt/intel/impi/$mpiversion/bin64/mpirun \
            -hosts $NODE,$NODE2 -ppn 1 -n 2 \
            -env I_MPI_FABRICS=shm:dapl \
            -env I_MPI_DAPL_PROVIDER=ofa-v2-ib0 \
            -env I_MPI_DYNAMIC_CONNECTION=0 /opt/intel/impi/$mpiversion/bin64/IMB-MPI1 pingpong \
            | grep -e ' 512 ' |  awk '{ print $3 }'` && \
            echo '##################################################' && \
            echo NODES: $NODE, $NODE2, ${matrix[$NODE,$NODE2]} && \
            echo '##################################################'; \
        done; \
    done


f1="%$((${#num_rows}+1))s"
f2=" %9s"

printf "$f1" ' '
for NODE in `cat ~/hosts`;\
    do printf "$f2" $NODE
done
echo

for NODE in `cat ~/hosts`; \
    do printf $f1 $NODE
    for NODE2 in `cat ~/hosts`; \
        do printf "$f2" ${matrix[$NODE,$NODE2]}
    done
    echo
done