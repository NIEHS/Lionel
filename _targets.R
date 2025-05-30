# Created by use_targets().
# Pipeline created by Kyle P Messier for analyzing pesticide data for PrestoGP demonstration

# Created by use_targets().
# Main targets file for the project.
# Created by Kyle P Messier

# Load packages required to define the pipeline:
library(targets)
library(tarchetypes)
library(geotargets)
library(PrestoGP)
library(tibble)
library(stringr)
library(sf)
library(terra)
library(qs2)
library(tidyverse)
library(skimr)
library(rsample)
library(stats)
library(parsnip)
library(fastDummies)
library(scales)
library(ggridges)
library(broom)
library(data.table)
library(exactextractr)
library(amadeus)
library(crew)
library(crew.cluster)
library(chopin)
library(dataRetrieval)
library(ggplot2)
library(gt)
library(webshot2)
library(lubridate)
sf::sf_use_s2(FALSE)
terra::terraOptions(memfrac = 0.1)


tar_config_set(
  store = "/opt/_targets"
)


################################################################################
#############################      CONTROLLER      #############################
# Get the value of SLURM_CPUS_PER_TASK environment variable
cpus_per_task <- as.integer(Sys.getenv("SLURM_CPUS_PER_TASK", "30"))

# Define the controller with dynamic workers based on cpus-per-task
default_controller <- crew::crew_controller_local(
  name = "default_controller",
  workers = cpus_per_task,
  seconds_idle = 30
)

### `controller_gpu` uses 4 GPU workers (undefined memory allocation).
scriptlines_apptainer <- "apptainer"
scriptlines_basedir <- "$PWD"
scriptlines_targetdir <- "/ddn/gs1/home/messierkp/projects/pipeline_PrestoGP"
scriptlines_inputdir <- "/ddn/gs1/home/messierkp/projects/pipeline_PrestoGP/input"
scriptlines_container <- "prestoGP.sif"
scriptlines_gpu <- glue::glue(
  "#SBATCH --job-name=prestogp_gpu \
  #SBATCH --mail-user=kyle.messier@nih.gov
  #SBATCH --partition=geo \
  #SBATCH --gres=gpu:1 \
  #SBATCH --error=slurm/targets_gpu_%j.out \
  {scriptlines_apptainer} exec --nv --env ",
  "CUDA_VISIBLE_DEVICES=${{GPU_DEVICE_ORDINAL}} ",
  "--bind {scriptlines_basedir}:/mnt ",
  "--bind {scriptlines_basedir}/inst:/inst ",
  "--bind {scriptlines_inputdir}:/input ",
  "--bind {scriptlines_targetdir}/targets:/opt/_targets ",
  "{scriptlines_container} \\"
)
controller_gpu <- crew.cluster::crew_controller_slurm(
  name = "controller_gpu",
  workers = 4,
  options_cluster = crew.cluster::crew_options_slurm(
    verbose = TRUE,
    script_lines = scriptlines_gpu
  )
)

scriptlines_cpu <- glue::glue(
  "#SBATCH --job-name=prestogp_cpu \
  #SBATCH --mail-user=kyle.messier@nih.gov
  #SBATCH --partition=highmem \
  #SBATCH --cpus-per-task=1
  #SBATCH --ntasks-per-node=1
  #SBATCH --mem=64G
  #SBATCH --nodes=1  
  #SBATCH --error=slurm/prestogp_cpu_%j.out \
  #SBATCH --error=slurm/prestogp_cpu_%j.err \
  {scriptlines_apptainer} exec --nv --env ",
  "--bind {scriptlines_basedir}:/mnt ",
  "--bind {scriptlines_basedir}/inst:/inst ",
  "--bind {scriptlines_inputdir}:/input ",
  "--bind {scriptlines_targetdir}/targets:/opt/_targets ",
  "{scriptlines_container} \\"
)
controller_cpu <- crew.cluster::crew_controller_slurm(
  name = "controller_cpu",
  workers = 4,
  options_cluster = crew.cluster::crew_options_slurm(
    verbose = TRUE,
    script_lines = scriptlines_cpu
  )
)

tar_option_set(
  packages = c(
    "PrestoGP",
    "tibble",
    "sf",
    "terra",
    "qs2",
    "tidyverse",
    "skimr",
    "rsample",
    "stats",
    "ggplot2",
    "tarchetypes",
    "geotargets",
    "parsnip",
    "fastDummies",
    "stringr",
    "amadeus",
    "chopin",
    "scales",
    "ggridges",
    "spatialsample",
    "broom",
    "yardstick",
    "data.table",
    "gt",
    "webshot2",
    "ggplot2",
    "nhdplusTools",
    "exactextractr",
    "dataRetrieval",
    "lubridate",
    "chopin",
    "lubridate",
    "psych",
    "crew",
    "crew.cluster"
  ),
  format = "qs",
  controller = crew::crew_controller_group(
    default_controller,
    controller_cpu,
    controller_gpu
  ),
  resources = tar_resources(
    crew = tar_resources_crew(
      controller = "default_controller"
    )
  ),
  garbage_collection = 100,
  storage = "worker",
  retrieval = "worker",
  error = "abridge"
)


# Run the R scripts in the R/ folder with your custom functions:
tar_source("inst/targets/targets_nwis.R")
tar_source("inst/targets/targets_tox.R")
tar_source("inst/targets/targets_huc.R")
tar_source("inst/targets/targets_exploratory.R")
tar_source("inst/targets/targets_covariates.R")
tar_source("inst/targets/targets_cov_process.R")
tar_source("inst/targets/targets_enviroatlas.R")
tar_source("inst/targets/targets_cov_modis.R")
tar_source("inst/targets/targets_fit_prestogp.R")
tar_source("inst/targets/targets_simulations.R")
tar_source() # R/ supporting functions

#  The TARGET LIST
list(
  targets_nwis,
  targets_tox,
  targets_huc,
  targets_exploratory,
  targets_covariates,
  targets_cov_process,
  targets_enviroatlas,
  targets_cov_modis,
  targets_simulations,
  targets_fit_prestogp
)

# 3. Run PrestoGP model on local machine for small test case
# 3a. Target for the model results 3b. Target for the model metrics
# 4. Run PrestoGP on local machine
# 5. Run PrestoGP on HPC-GEO
# 6. Compare with penalized Tobit regression for single variables (https://github.com/TateJacobson/tobitnet)
