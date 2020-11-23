#!/bin/bash

######## THOUGHTS ##########
#This script should take the domain dim and the block dims as parameters.
#This is because it is the python script who has generated the optimal parameters, and therefore the script will provide them.

if [[ $# -lt 5 ]] ; then
    echo 'arg: (base/smem/coop/coop_smem) NGPUS DIM BLOCK_X BLOCK_Y'
    exit 0
fi

#
config=$1.conf
iter=10
[ ! -f solutions/solution\_$3\_$iter ] && ./create_solutions.sh $3
wait
sed -i -re 's/(NGPUS = )[0-9]+/\1'$2'/' $config
sed -i -re 's/(DIM = )[0-9]+/\1'$3'/' $config
sed -i -re 's/(BLOCK_X = )[0-9]+/\1'$4'/' $config
sed -i -re 's/(BLOCK_Y = )[0-9]+/\1'$5'/' $config
# Extract all numerical results from run
stdbuf -o 0 -e 0 python ${PWD}/Autotuning/tuner/tune.py $config | tee /dev/tty | awk '/rms error/{x=NR+1}(NR<=x){print}' | awk '$0==($0+0)'
#awk '/rms error/{x=NR+1}(NR<=x){print}' gen.txt | awk '$0==($0+0)'


# Forstår ikke helt resultatene mine.. Alle er jo smem wtf. Hvorfor er de forskjellige?
