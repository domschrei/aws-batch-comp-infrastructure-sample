#!/bin/bash

export MALLOC_CONF="thp:always"
export PATH=.:$PATH
export OMPI_MCA_btl_vader_single_copy_mechanism=none
export RDMAV_FORK_SAFE=1

n_threads_per_process=$(nproc)
sharingspersec=3 # integer!!
nglobalprocs=$(cat $1|wc -l)
echo "Running Mallob with $n_threads_per_process threads on $(hostname) as leader and with $nglobalprocs MPI processes in total"
bufferbasesize=$((375 * $n_threads_per_process / $sharingspersec))
echo "Buffer base size: $bufferbasesize"

if [[ $nglobalprocs -ge 100 ]]; then
    # cloud setup
    bufferdiscount=0.9
    portfolio=kkkccl
    echo "Cloud setup (portfolio: $portfolio)"
else
    # parallel setup
    bufferdiscount=1
    portfolio=k
    echo "Parallel setup (portfolio: $portfolio)"
fi

options="-mono=$2 \
-pre-cleanup=1 -seed=110519 `#-zero-only-logging` -v=3 -t=${n_threads_per_process} -max-lits-per-thread=100000000 \
-buffered-imported-cls-generations=10 -clause-buffer-base-size=$bufferbasesize -clause-buffer-discount=$bufferdiscount \
-clause-filter-clear-interval=300 -strict-clause-length-limit=64 -strict-lbd-limit=64 -satsolver=$portfolio \
-extmem-disk-dir='' -processes-per-host=1 -regular-process-allocation=1 -sleep=1000 -trace-dir=/tmp"

command="mpirun --mca btl_tcp_if_include eth0 --allow-run-as-root --hostfile $1 --bind-to none \
-x MALLOC_CONF=thp:always -x PATH=.:$PATH -x OMPI_MCA_btl_vader_single_copy_mechanism=none -x RDMAV_FORK_SAFE=1 \
mallob $options"

echo "EXECUTING: $command"
$command
