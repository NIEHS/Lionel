#!/bin/bash
#SBATCH --job-name=lionel
#SBATCH --partition=gpu
#SBATCH --mem=100G
#SBATCH --cpus-per-task=2
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --output=slurm_messages/slurm-%j.out
#SBATCH --error=slurm_messages/slurm-%j.err
#SBATCH --mail-user=${USER}@nih.gov
#SBATCH --mail-type=ALL


# Run the container
apptainer exec \
  --bind $PWD/inst:/inst \
  --bind $PWD/inst/input:/input \
  --bind $PWD/_targets:/opt/_targets \
  --bind $PWD:/mnt \
  Lionel.sif \
  Rscript /mnt/run.R

