#!/bin/bash
#SBATCH --job-name=lionel
#SBATCH --partition=geo
#SBATCH --output=slurm_messages/slurm-%j.out
#SBATCH --error=slurm_messages/slurm-%j.err
#SBATCH --mail-user=moylanhm@nih.gov
#SBATCH --mail-type=ALL

# usage: build_apptainer_image.sh [full file path]
# where full file path ends with .sif, with full directory path to save the image
# after the image is built, group write/execution privileges are given

# Recommended to run this script interactively via `sh build_dl_calc.sh`
apptainer build --fakeroot Lionel.sif Lionel.def