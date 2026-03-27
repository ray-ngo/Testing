#############################################################################################################################
# Master script to render final HTML file from R Markdown file
# Loads all required packages from the dependencies folder
#
# Make sure the 'plyr' is not loaded after 'dplyr' library in the same R session
# Under such case, the group_by features of dplyr library does not work. Restart RStudio and make sure
# plyr library is not loaded while generating dashboard
# For more info on this issue:
# https://stackoverflow.com/questions/26923862/why-are-my-dplyr-group-by-summarize-not-working-properly-name-collision-with
#
#############################################################################################################################

### Read Command Line Arguments
args                <- commandArgs(trailingOnly = TRUE)
if(length(args) > 0){
	Parameters_File     <- args[1]
}else{
	Parameters_File <- "E:/Gen3_Model/source/visualizer/runtime/parameters.csv"
}


### Read parameters from Parameters_File
parameters          <- read.csv(Parameters_File, header = TRUE)
PARENT_DIR         <- trimws(paste(parameters$Value[parameters$Key=="PARENT_DIR"]))
WORKING_DIR         <- trimws(paste(parameters$Value[parameters$Key=="PROJECT_DIR"]))
SCRIPTS_DIR         <- trimws(paste(parameters$Value[parameters$Key=="SCRIPTS_DIR"]))
BASELINE_SUMMARY_DIR    <- trimws(paste(parameters$Value[parameters$Key=="BASELINE_SUMMARY_DIR"]))
CENSUS_SUMMARY_DIR  <- trimws(paste(parameters$Value[parameters$Key=="CENSUS_SUMMARY_DIR"]))
CALIBRATION_DIR     <- trimws(paste(parameters$Value[parameters$Key=="CALIBRATION_DIR"]))
BASELINE_SCENARIO_NAME  <- trimws(paste(parameters$Value[parameters$Key=="BASELINE_SCENARIO_NAME"]))
ALTERNATIVE_SCENARIO_NAME <- trimws(paste(parameters$Value[parameters$Key=="ALTERNATIVE_SCENARIO_NAME"]))
BASELINE_SAMPLE_RATE    <- as.numeric(trimws(paste(parameters$Value[parameters$Key=="BASELINE_SAMPLE_RATE"])))
ALTERNATIVE_SAMPLE_RATE   <- as.numeric(trimws(paste(parameters$Value[parameters$Key=="ALTERNATIVE_SAMPLE_RATE"])))
R_LIBRARY           <- trimws(paste(parameters$Value[parameters$Key=="R_LIBRARY"]))
RSTUDIO_PANDOC_path      <- trimws(paste(parameters$Value[parameters$Key=="RSTUDIO_PANDOC"]))
HTML_OUTPUT_DIR      <- trimws(paste(parameters$Value[parameters$Key=="HTML_OUTPUT_DIR"]))
SUBSET_HTML_NAME    <- trimws(paste(parameters$Value[parameters$Key=="SUBSET_HTML_NAME"]))
FULL_HTML_NAME      <- trimws(paste(parameters$Value[parameters$Key=="FULL_HTML_NAME"]))
SHP_FILE_NAME       <- trimws(paste(parameters$Value[parameters$Key=="SHP_FILE_NAME"]))
CT_ZERO_AUTO_FILE_NAME       <- trimws(paste(parameters$Value[parameters$Key=="CT_ZERO_AUTO_FILE_NAME"]))
IS_BASE_SURVEY      <- trimws(paste(parameters$Value[parameters$Key=="IS_BASE_SURVEY"]))
ALTERNATIVE_SUMMARY_DIR      <- trimws(paste(parameters$Value[parameters$Key=="ALTERNATIVE_SUMMARY_DIR"]))
# ALTERNATIVE_SUMMARY_DIR   <- ifelse(Run_switch=="SN",
#                               file.path(CALIBRATION_DIR, "ABM_Summaries_subset"),
#                               file.path(CALIBRATION_DIR, "ABM_Summaries"))
ZONES_DIR           <- trimws(paste(parameters$Value[parameters$Key=="ZONES_DIR"]))
OUTPUT_HTML_NAME    <- FULL_HTML_NAME
ASIM_CONFIG_DIR     <- trimws(paste(parameters$Value[parameters$Key=="ASIM_CONFIG_DIR"]))

SYSTEM_APP_PATH       <- trimws(paste(parameters$Value[parameters$Key=="SYSTEM_APP_PATH"]))
SYSTEM_TEMPLATES_PATH <- trimws(paste(parameters$Value[parameters$Key=="SYSTEM_TEMPLATES_PATH"]))
RUNTIME_PATH          <- trimws(paste(parameters$Value[parameters$Key=="RUNTIME_PATH"]))

# Set RM_GQ
currDir <- getwd()

setwd(ALTERNATIVE_SUMMARY_DIR)
RM_GQ <- FALSE
if (file.exists("rm_gq.csv")) {
    build_rm_gq_f <- read.csv("rm_gq.csv", header = TRUE)
    build_rm_gq_s <- trimws(paste(build_rm_gq_f$Value[build_rm_gq_f$Key=="RM_GQ"]))
    if (build_rm_gq_s == "TRUE") { RM_GQ <- TRUE }
} else {
    RM_GQ <- TRUE
}
setwd(currDir)


### Initialization
# Load global variables
.libPaths(R_LIBRARY)
Sys.getenv("RSTUDIO_PANDOC")
Sys.setenv(RSTUDIO_PANDOC=RSTUDIO_PANDOC_path)
cat("Using the R packages found in ", .libPaths(), "\n")
# cat("Pandoc version: ", pandoc_available())
# cat(installed.packages())
source(paste(SCRIPTS_DIR, "_SYSTEM_VARIABLES.R", sep = "/"))

### Load required libraries
SYSTEM_REPORT_PKGS <- c("DT", "flexdashboard", "leaflet", "geojsonio", "htmltools", "htmlwidgets", "kableExtra", "shiny",
                        "knitr", "mapview", "plotly", "RColorBrewer", "rgdal", "rgeos", "crosstalk","treemap", "htmlTable",
                        "rmarkdown", "scales", "stringr", "jsonlite", "pander", "ggplot2", "reshape", "raster", "dplyr", "sf")

lib_sink <- suppressWarnings(suppressMessages(lapply(SYSTEM_REPORT_PKGS, library, character.only = TRUE)))

### Read Target and Output Summary files
setwd(BASELINE_SUMMARY_DIR)
base_csv = list.files(pattern="*.csv")
base_data <- lapply(base_csv, function(x){
  read.csv(x)})
base_csv_names <- unlist(lapply(base_csv, function (x) {gsub(".csv", "", x)}))

#### If this is not the base survey, load in the rm_gq.csv file
BASE_RM_GQ <- FALSE
if (IS_BASE_SURVEY!="Yes" && file.exists("rm_gq.csv")) {
    base_rm_gq_f <- read.csv("rm_gq.csv", header = TRUE)
    base_rm_gq_s <- trimws(paste(base_rm_gq_f$Value[base_rm_gq_f$Key=="RM_GQ"]))
    if (base_rm_gq_s == "TRUE") { BASE_RM_GQ <- TRUE }
} else {
    BASE_RM_GQ <- TRUE
}

#### Read in the rest of the files
if (IS_BASE_SURVEY=="Yes") {
    setwd(CENSUS_SUMMARY_DIR)
    census_csv = list.files(pattern="*.csv")
    census_data <- lapply(census_csv, function(x){
      read.csv(x)})
    census_csv_names <- unlist(lapply(census_csv, function (x) {gsub(".csv", "", x)}))
}

setwd(ALTERNATIVE_SUMMARY_DIR)
build_csv = list.files(pattern="*.csv")
build_data <- lapply(build_csv, read.csv)
build_csv_names <- unlist(lapply(build_csv, function (x) {gsub(".csv", "", x)}))

### Read SHP files
setwd(ZONES_DIR)
zone_shp <- st_read(SHP_FILE_NAME, quiet=TRUE)
zone_shp <- st_transform(zone_shp, CRS("+proj=longlat +datum=WGS84"))

setwd(ALTERNATIVE_SUMMARY_DIR)
ct_zero_auto_shp <- st_read(CT_ZERO_AUTO_FILE_NAME, quiet=TRUE)

setwd(currDir)
print("Read specified csv files, now loading visualizer.")
### Generate dashboard
rmarkdown::render(file.path(SYSTEM_TEMPLATES_PATH, "template.Rmd"),
                  output_dir = RUNTIME_PATH,
                  intermediates_dir = RUNTIME_PATH, quiet = TRUE)
template.html <- readLines(file.path(RUNTIME_PATH, "template.html"))
idx <- which(template.html == "window.FlexDashboardComponents = [];")[1]
template.html <- append(template.html, "L_PREFER_CANVAS = true;", after = idx)
writeLines(template.html, file.path(OUTPUT_PATH, paste(OUTPUT_HTML_NAME, ".html", sep = "")))





# finish
