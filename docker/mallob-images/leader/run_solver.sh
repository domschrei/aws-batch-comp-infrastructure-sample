#!/bin/bash

MAX_N_SOLVERS_PER_PROCESS=32

export MALLOC_CONF="thp:always"
export PATH=.:$PATH
export OMPI_MCA_btl_vader_single_copy_mechanism=none
export RDMAV_FORK_SAFE=1

function log_stdout_and_stderr() {
    echo "$@"
    echo "$@" 1>&2
}

# Number of threads per MPI process: Set to available hardware threads,
# but at most $MAX_N_SOLVERS_PER_PROCESS.
n_threads_per_process=$(nproc)
if [ $n_threads_per_process -gt $MAX_N_SOLVERS_PER_PROCESS ]; then
    n_threads_per_process=$MAX_N_SOLVERS_PER_PROCESS
fi

sharingspersec=3 # integer!!
nglobalprocs=$(cat $1|wc -l)
log_stdout_and_stderr "Running Mallob with $n_threads_per_process threads on $(hostname) as leader and with $nglobalprocs MPI processes in total"
bufferbasesize=$((400 * $n_threads_per_process / $sharingspersec))
log_stdout_and_stderr "Buffer base size: $bufferbasesize"

if [[ $nglobalprocs -ge 100 ]]; then
    # cloud setup
    bufferdiscount=0.9
    portfolio=kkkccl
    log_stdout_and_stderr "CLOUD SETUP (portfolio: $portfolio)"
else
    # parallel setup
    bufferdiscount=1
    portfolio=k
    log_stdout_and_stderr "PARALLEL SETUP with $n_threads_per_process cores (portfolio: $portfolio)"
fi

options="-mono=$2 \
-pre-cleanup=1 -seed=110519 `#-zero-only-logging` -v=3 -t=${n_threads_per_process} -max-lits-per-thread=100000000 \
-buffered-imported-cls-generations=10 -clause-buffer-base-size=$bufferbasesize -clause-buffer-discount=$bufferdiscount \
-clause-filter-clear-interval=60 -strict-clause-length-limit=20 -strict-lbd-limit=20 -satsolver=$portfolio \
-extmem-disk-dir='' -processes-per-host=1 -regular-process-allocation=1 -sleep=1000 -trace-dir=/tmp -mlbdps=6"

command="mpirun --mca btl_tcp_if_include eth0 --allow-run-as-root --hostfile $1 --bind-to none \
-x MALLOC_CONF=thp:always -x PATH=.:$PATH -x OMPI_MCA_btl_vader_single_copy_mechanism=none -x RDMAV_FORK_SAFE=1 \
mallob $options"

log_stdout_and_stderr "EXECUTING: $command"
$command
