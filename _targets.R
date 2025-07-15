# Created by use_targets().
# Pipeline created by Kyle P Messier for analyzing pesticide data for PrestoGP demonstration

# Created by use_targets().
# Main targets file for the project.
# Created by Kyle P Messier

# Load packages required to define the pipeline:
library(targets)
library(tarchetypes)
library(nhdplusTools)
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
library(tigris)
library(jsonlite)
library(glue)
library(sbtools)
library(archive)
sf::sf_use_s2(FALSE)
terra::terraOptions(memfrac = 0.1)


tar_config_set(
  store = "/opt/_targets/"
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
scriptlines_targetdir <- "/ddn/gs1/home/messierkp/projects/Lionel"
scriptlines_inputdir <- "/ddn/gs1/home/messierkp/projects/Lionel/inst/input"
scriptlines_container <- "Lionel.sif"
scriptlines_gpu <- glue::glue(
  "#SBATCH --job-name=lionel_gpu \
  #SBATCH --mail-user=kyle.messier@nih.gov
  #SBATCH --partition=geo \
  #SBATCH --gres=gpu:1 \
  #SBATCH --error=slurm/targets_gpu_%j.out \
  {scriptlines_apptainer} exec --nv --env ",
  "CUDA_VISIBLE_DEVICES=${{GPU_DEVICE_ORDINAL}} ",
  "--bind {scriptlines_basedir}:/mnt ",
  "--bind {scriptlines_basedir}/inst:/inst ",
  "--bind {scriptlines_inputdir}:/inst/input ",
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
    "crew.cluster",
    "tigris",
    "targets",
    "jsonlite",
    "glue",
    "sbtools",
    "archive"
  ),
  format = "qs",
  controller = crew::crew_controller_group(
    default_controller,
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
  error = "continue"
)


# Run the R scripts in the R/ folder with your custom functions:
tar_source("inst/targets/targets_data.R")
tar_source()

#  The TARGET LIST
list(
  targets_data
)
