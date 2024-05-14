#!/bin/bash

MAX_N_SOLVERS_PER_PROCESS=64
MALLOB_IMPCHECK=true # enable to use "ImpCheck" with on-the-fly LRAT checking

export MALLOC_CONF="thp:always"
export PATH=.:$PATH
export OMPI_MCA_btl_vader_single_copy_mechanism=none
export RDMAV_FORK_SAFE=1

function log_stdout_and_stderr() {
    echo "$@"
    echo "$@" 1>&2
}

sharingspersec=2 # integer!!
nglobalprocs=$(cat $1|wc -l)
nprocspernode=$(cat $1|head -1|grep -oE "slots=[0-9]+"|grep -oE "[0-9]+")
if [ "$nprocspernode" -ne "1" ]; then
    log_stdout_and_stderr "ERROR: # slots != 1"
    exit 1
fi

# Number of threads per MPI process: Set to available hardware threads,
# but at most $MAX_N_SOLVERS_PER_PROCESS.
n_threads_per_process=$(nproc)
if [ $n_threads_per_process -gt $MAX_N_SOLVERS_PER_PROCESS ]; then
    n_threads_per_process=$MAX_N_SOLVERS_PER_PROCESS
fi

portfolio="k" # default portfolio
if [[ "$nglobalprocs" -ge 100 ]]; then
    # cloud setup
    portfolio=kkkccl
    log_stdout_and_stderr "CLOUD SETUP (portfolio: $portfolio)"
fi
if $MALLOB_IMPCHECK; then
    # TRUSTED setup with ImpCheck (with reduced number of threads where necessary)
    n_threads_per_process=$(printf "%.0f" $(echo "(11/12) * $n_threads_per_process - (2/3)"|bc -l))
    portfolio='c!k+(c!){'$(($n_threads_per_process-2))'}(c!l+(c!){'$(($n_threads_per_process-2))'}){7}'
    otfcopts="-rspaa=0 -otfc=1 -max-lits-per-thread=30000000"
    log_stdout_and_stderr "TRUSTED SETUP (portfolio: $portfolio)"
else
    # Usual setup
    otfcopts="-rspaa=1 -otfc=0 -max-lits-per-thread=60000000"
    log_stdout_and_stderr "DEFAULT SETUP (portfolio: $portfolio)"
fi

log_stdout_and_stderr "Running Mallob with $n_threads_per_process threads on $(hostname) as leader and with $nglobalprocs MPI processes in total"
bufferbasesize=$((400 * $n_threads_per_process / $sharingspersec))
log_stdout_and_stderr "Buffer base size: $bufferbasesize"

options="-mono=$2 -pre-cleanup=1 -seed=110519 -zero-only-logging=1 -v=3 -t=${n_threads_per_process} \
-clause-buffer-base-size=$bufferbasesize -satsolver=$portfolio \
-processes-per-host=1 -regular-process-allocation=1 -sleep=1000 -trace-dir=/tmp $otfcopts"

command="mpirun --mca btl_tcp_if_include eth0 --allow-run-as-root --hostfile $1 --bind-to none \
-x MALLOC_CONF=thp:always -x PATH=.:$PATH -x OMPI_MCA_btl_vader_single_copy_mechanism=none -x RDMAV_FORK_SAFE=1 \
mallob $options"

log_stdout_and_stderr "EXECUTING: $command"
$command
