#!/bin/bash
project_folder=$(echo ${PWD} | sed 's/thesis.*/thesis/')
sed -i -re 's/(CUDA_VISIBLE_DEVICES=)[0-9]+/\13/' $project_folder/constants.sh
sed -i -re 's/(scripts\/).+(\.py)/\1autotune_configuration\2/' $project_folder/Dockerfile
bash $project_folder/scripts/heid/heid_docker.sh autotune
