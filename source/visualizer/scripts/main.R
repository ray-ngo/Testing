# Top-level visualizer summary script

### Read Command Line Arguments
args                <- commandArgs(trailingOnly = TRUE)
Parameters_File     <- args[1]

### Load libraries
SYSTEM_REPORT_PKGS <- c(
    "data.table", "plyr", "weights", "reshape", "stringr", "foreign", "sf"
)
lib_sink <- suppressWarnings(suppressMessages(lapply(SYSTEM_REPORT_PKGS, library, character.only = TRUE)))

### Read parameters from Parameters_File
parameters              <- read.csv(Parameters_File, header = TRUE)
ABM_DIR                 <- trimws(paste(parameters$Value[parameters$Key=="ABM_DIR"]))
ABM_SUMMARY_DIR         <- trimws(paste(parameters$Value[parameters$Key=="ABM_SUMMARY_DIR"]))
BASELINE_SUMMARY_DIR    <- trimws(paste(parameters$Value[parameters$Key=="BASELINE_SUMMARY_DIR"]))
CENSUS_DIR              <- trimws(paste(parameters$Value[parameters$Key=="CENSUS_DIR"]))
SCRIPTS_DIR             <- trimws(paste(parameters$Value[parameters$Key=="SCRIPTS_DIR"]))
SKIMS_DIR               <- trimws(paste(parameters$Value[parameters$Key=="SKIMS_DIR"]))
ZONES_DIR               <- trimws(paste(parameters$Value[parameters$Key=="ZONES_DIR"]))
LAND_USE_DIR            <- trimws(paste(parameters$Value[parameters$Key=="LAND_USE_DIR"]))
R_LIBRARY               <- trimws(paste(parameters$Value[parameters$Key=="R_LIBRARY"]))
ZONE_SHP                <- trimws(paste(parameters$Value[parameters$Key=="SHP_FILE_NAME"]))
ALTERNATIVE_SAMPLE_RATE <- trimws(paste(parameters$Value[parameters$Key=="ALTERNATIVE_SAMPLE_RATE"]))
ASIM_CONFIG_DIR         <- trimws(paste(parameters$Value[parameters$Key=="ASIM_CONFIG_DIR"]))
CT_ZERO_AUTO_FILE_NAME  <- trimws(paste(parameters$Value[parameters$Key=="CT_ZERO_AUTO_FILE_NAME"]))
IS_BASE_SURVEY          <- trimws(paste(parameters$Value[parameters$Key=="IS_BASE_SURVEY"]))

RM_GQ <- FALSE
if(nrow(parameters[parameters$Key=="RM_GQ",] > 0)){
  RM_GQ <- trimws(paste(parameters$Value[parameters$Key=="RM_GQ"]))
  cat("ActivitySim Output Processing Script will REMOVE Group Quarters from Visualizer!\n\n")
}

.libPaths(R_LIBRARY)
library(omxr)
WD <- ABM_SUMMARY_DIR

### Load common data

setwd(ABM_DIR)
hh                 <- read.csv("final_households.csv", header = TRUE)
per                <- read.csv("final_persons.csv", header = TRUE)
all_tours          <- read.csv("final_tours.csv", header = TRUE)
all_trips          <- read.csv("final_trips.csv", header = TRUE)
jtour_participants <- read.csv("final_joint_tour_participants.csv", header = TRUE)

if(RM_GQ){
  hh = hh[hh$TYPE == 1,]
  per = per[per$household_id %in% hh$household_id,]
  all_tours = all_tours[all_tours$household_id %in% hh$household_id,]
  all_trips = all_trips[all_trips$household_id %in% hh$household_id,]
  jtour_participants = jtour_participants[jtour_participants$household_id %in% hh$household_id,]
}

### Define function to print elapsed time
print_elapsed_time <- function(fun, st, et) {
    cat(sprintf("\n %s finished, run time: %.2f mins\n\n", fun, difftime(et, st, unit="mins")))
}

### Set WD
setwd(WD)

## summarize_abm
source(paste(SCRIPTS_DIR, "_summarize_asim_mwcog.R", sep="/"))
start_time <- Sys.time()
summarize_asim_mwcog(ZONES_DIR, ZONE_SHP, SKIMS_DIR, BASELINE_SUMMARY_DIR, WD,
                     hh, per, all_tours, all_trips, jtour_participants)
end_time <- Sys.time()
print_elapsed_time("summarize_asim_mwcog", start_time, end_time)

## workers_by_TAZ

### Detach unused libraries and load new ones
#### Keep reshape and foreign
libs_to_detach <- c("data.table", "plyr", "weights", "stringr", "sf")
libs_to_detach <- sapply(1:length(libs_to_detach), function(i) {
    sprintf("package:%s", libs_to_detach[i])
})
det_sink <- suppressWarnings(suppressMessages(lapply(libs_to_detach, detach, character.only = TRUE)))

SYSTEM_REPORT_PKGS <- c("dplyr", "ggplot2", "plotly")
lib_sink <- suppressWarnings(suppressMessages(lapply(SYSTEM_REPORT_PKGS, library, character.only = TRUE)))

### run workers_by_taz
source(paste(SCRIPTS_DIR, "_workers_by_taz.R", sep="/"))
start_time <- Sys.time()
workers_by_taz(LAND_USE_DIR, ASIM_CONFIG_DIR, ZONES_DIR, WD, ALTERNATIVE_SAMPLE_RATE, hh, per)
end_time <- Sys.time()
print_elapsed_time("workers_by_taz", start_time, end_time)

## auto_ownership_census_ct

### Detach unused libraries and load new ones
#### Keep dplyr
libs_to_detach <- c("reshape", "foreign", "plotly", "ggplot2")
libs_to_detach <- sapply(1:length(libs_to_detach), function(i) {
    sprintf("package:%s", libs_to_detach[i])
})
det_sink <- suppressWarnings(suppressMessages(
    lapply(libs_to_detach, detach, character.only = TRUE, unload = TRUE, force = TRUE)
))

SYSTEM_REPORT_PKGS <- c("leaflet", "htmlwidgets", "rgdal", "rgeos", "raster", "data.table", "sf")
lib_sink <- suppressWarnings(suppressMessages(lapply(SYSTEM_REPORT_PKGS, library, character.only = TRUE)))

### run auto_ownership_census_ct
source(paste(SCRIPTS_DIR, "_auto_ownership_census_ct.R", sep="/"))
start_time <- Sys.time()
auto_ownership_census_ct(CENSUS_DIR, ZONES_DIR, ZONE_SHP, WD, ALTERNATIVE_SAMPLE_RATE, hh)
end_time <- Sys.time()
print_elapsed_time("auto_ownership_census_ct", start_time, end_time)
