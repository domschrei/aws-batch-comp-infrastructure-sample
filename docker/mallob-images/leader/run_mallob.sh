#!/bin/bash

# Old sample command
#mpirun --mca btl_tcp_if_include eth0 --allow-run-as-root -np 2 \
#  --hostfile $1 --use-hwthread-cpus --map-by node:PE=2 --bind-to none --report-bindings \
#  mallob -mono=$2 -satsolver="c" -cbbs=1500 -cbdf="1.0" \
#  -shufinp=0.03 -shufshcls=1 -slpp=$((50000000 * 4)) \
#  -cfhl=300 -ihlbd=8 -islbd=8 -fhlbd=8 -fslbd=8 -smcl=30 -hmcl=30 \
#  -s=1 -sleep=1000 -t=2 -appmode=thread -nolog "-v=2 -0o=1"

n_threads_per_process=$(nproc)
export RDMAV_FORK_SAFE=1
export MALLOC_CONF="thp:always"
export PATH=.:$PATH

echo "Running Mallob with $n_threads_per_process threads on $(hostname)"

mpirun --mca btl_tcp_if_include eth0 --allow-run-as-root --hostfile $1 --bind-to none mallob \
-t=$n_threads_per_process -mono=$2 -v=3 -satsolver=k -cbdf=1 -rlbd=1 -pph=1 -rpa=1 -sleep=1000 \
-mlbdps=2 -cbbs=4000 -s=0.33 -scsd=1 -mlpt=100000000 -cfci=300 -scll=20
