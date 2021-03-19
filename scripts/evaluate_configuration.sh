#!/bin/bash

if [[ $# -lt 9 ]] ; then
    echo 'arg: (base/smem/coop/coop_smem) NGPUS DIM DIMENSIONS BLOCK_X BLOCK_Y BLOCK_Z STENCIL_DEPTH REPEAT UNROLL_X'
    exit 0
fi

project_folder=$(echo ${PWD} | sed 's/thesis.*/thesis/')

config=$project_folder/configs/yme/general.conf
constants=$project_folder/constants.sh

bash $project_folder/scripts/set_run_configuration.sh $1 $2 $8
sed -i -re 's/(DIM=)[0-9]+/\1'$3'/' $constants
[ ! -z "$9" ] && sed -i -re 's/(UNROLL_X=)[0-9]+/\1'${10}'/' $constants

source $project_folder/constants.sh # Required for $REPEAT # But this overrides SMEM, COOP etc..

sed -i -re 's/(BLOCK_X = )[0-9|,| ]+/\1'$5'/' $config
sed -i -re 's/(BLOCK_Y = )[0-9|,| ]+/\1'$6'/' $config
sed -i -re 's/(BLOCK_Z = )[0-9|,| ]+/\1'$7'/' $config
sed -i -re 's/(repeat = )[0-9]+,/\1'$9',/'    $config

# Extract all numerical results from run
# This output is used in in scripts/find_halo_depth.py

# Use when running on yme
#stdbuf -o 0 -e 0 python -u $project_folder/Autotuning/tuner/tune.py $config | tee /dev/tty | awk '/Version/{x=NR+1}(NR<=x){print}' | awk '$0==($0+0)'

# Use when running in Docker container on heid
stdbuf -o 0 -e 0 python2 -u $project_folder/Autotuning/tuner/tune.py $config | tee /dev/pts/0 | awk '/Version/{x=NR+1}(NR<=x){print}' | awk '$0==($0+0)'