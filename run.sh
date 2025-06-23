#!/bin/bash
#SBATCH --job-name=lionel
#SBATCH --partition=highmem
#SBATCH --mem=100G
#SBATCH --cpus-per-task=2
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --output=slurm_messages/slurm-%j.out
#SBATCH --error=slurm_messages/slurm-%j.err
#SBATCH --mail-user=${USER}@nih.gov
#SBATCH --mail-type=ALL

############################      CERTIFICATES      ############################
# Export CURL_CA_BUNDLE and SSL_CERT_FILE environmental variables to vertify
# servers' SSL certificates during download.
export CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

# Run the container
apptainer exec \
  --bind $PWD/inst:/inst \
  --bind $PWD/inst/input:/input \
  --bind $PWD/_targets:/opt/_targets \
  --bind $PWD:/mnt \
  Lionel.sif \
  Rscript /mnt/run.R

