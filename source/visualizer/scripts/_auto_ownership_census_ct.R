auto_ownership_census_ct <- function(census_dir, zones_dir, zone_shp, wd, alternative_sample_rate,
                                     hh) {
print("Building Census Comparisons...")

# Setup
CensusData  <- "ACS_2019_5YR_DC_MD_VA_WV_Vehicles_Available.csv"
ct_shp_file <- "tl_2019_11_24_51_54_tract.shp"

setwd(census_dir)
census <- read.csv(CensusData, stringsAsFactors = F)
ct_shp <- shapefile(ct_shp_file)

setwd(zones_dir)
taz_shp <- shapefile(zone_shp)

setwd(wd) # output dir

# Need Geographic crosswalk between taz and census tract
taz_shp <- spTransform(taz_shp, CRS("+proj=longlat +ellps=GRS80"))
ct_shp <- spTransform(ct_shp, CRS("+proj=longlat +ellps=GRS80"))

taz_centroids <- gCentroid(taz_shp, byid=TRUE, id=taz_shp$OBJECTID)

overlay <- function(points, polygon){
  proj4string(points) <- proj4string(polygon) # use same projection
  pointsDF <- over(points,polygon)
  return(pointsDF)
}

tazXWalk <- dplyr::select(taz_shp@data, TAZ) %>%
  mutate(TAZSEQ = TAZ)
tazTemp1 <- overlay(taz_centroids, ct_shp)
tazXWalk <- tazXWalk %>%
  mutate(COUNTYFP = tazTemp1$COUNTYFP) %>%
  mutate(CTIDFP = tazTemp1$GEOID)

hh <- hh[hh$TYPE == 1,]
hh$TAZ = hh$home_zone_id #added ASR 7/7/23 to attempt to fix the map
# Calculating auto availability and merging Census Track ID
hh$finalweight <- 1/as.numeric(alternative_sample_rate)
hh$hasZeroAutos <- ifelse(hh$auto_ownership==0, 1, 0)
hh$hasZeroAutosWeighted <- hh$hasZeroAutos * hh$finalweight
num_hh_per_taz <- aggregate(hh$finalweight, by=list(Category=hh$TAZ), FUN=sum)
zero_auto_hh_by_taz <- aggregate(hh$hasZeroAutosWeighted, by=list(Category=hh$TAZ), FUN=sum)
names(zero_auto_hh_by_taz)[names(zero_auto_hh_by_taz)=="Category"] <- "TAZ"
names(zero_auto_hh_by_taz)[names(zero_auto_hh_by_taz)=="x"] <- "ZeroAutoHH"

zero_auto_hh_by_taz$HH <- num_hh_per_taz$x
zero_auto_hh_by_taz$CTIDFP <- tazXWalk$CTIDFP[match(zero_auto_hh_by_taz$TAZ, tazXWalk$TAZSEQ)]
zero_auto_hh_by_taz$CTIDFP <- as.numeric(zero_auto_hh_by_taz$CTIDFP)
zero_auto_hh_by_taz$COUNTYFP <- tazXWalk$COUNTYFP[match(zero_auto_hh_by_taz$TAZ, tazXWalk$TAZSEQ)]

COUNTYFPs <- unique(zero_auto_hh_by_taz$COUNTYFP)
COUNTYFPs <- COUNTYFPs[!is.na(COUNTYFPs)]

zero_auto_hh_by_CT <- zero_auto_hh_by_taz %>%
  group_by(CTIDFP) %>%
  summarise_at(vars(HH, ZeroAutoHH), funs(sum))

zero_auto_hh_by_CT <- zero_auto_hh_by_CT[!is.na(zero_auto_hh_by_CT$CTIDFP),]

model <- zero_auto_hh_by_CT

ct_shp <- ct_shp[ct_shp$COUNTYFP %in% COUNTYFPs,]
ct_shp$GEOID <- as.numeric(ct_shp$GEOID)

# Create DF
names(model)[names(model)=="HH"] <- "Model_HH"
names(model)[names(model)=="ZeroAutoHH"] <- "Model_A0"

census$Census_Auto0Prop <- (census$Census_A0/census$Census_HH)*100
census[is.na(census)] <- 0

model$Model_Auto0Prop <- (model$Model_A0/model$Model_HH)*100
model[is.na(model)] <- 0

setDT(census)[, paste0("geoid", 1:2) := tstrsplit(geoid, "US")]
colnames(census)[which(names(census) == "geoid2")] <- "TractID"
census$TractID <- as.numeric(census$TractID)

df <- census %>%
  left_join(model, by = c("TractID"="CTIDFP")) %>%
  mutate(Diff_ZeroAuto = Model_Auto0Prop - Census_Auto0Prop)
df[is.na(df)] <- 0

#Copy plot variable to SHP
ct_shp@data <- ct_shp@data %>%
  left_join(df, by = c("GEOID"="TractID"))
ct_shp@data[is.na(ct_shp@data)] <- 0

# Create Map
ct_shp <- ct_shp[!is.na(ct_shp@data$Diff_ZeroAuto),]
ct_shp@data$textComment1 <- paste("Total Census HH: ", ct_shp$Census_HH, sep = "")
ct_shp@data$textComment2 <- ifelse(ct_shp@data$Diff_ZeroAuto<0,'Model under predicts by',
                                     ifelse(ct_shp@data$Diff_ZeroAuto==0,"Model correct",'Model over predicts by'))

ct_shp_sf = st_as_sf(ct_shp) %>% dplyr::select("NAMELSAD", "Diff_ZeroAuto", "textComment1", "textComment2")

ct_shp_sf <- st_transform(ct_shp_sf, CRS("+proj=longlat +datum=WGS84"))
st_write(ct_shp_sf, paste0(ABM_SUMMARY_DIR, "/", CT_ZERO_AUTO_FILE_NAME), driver="ESRI Shapefile", quiet=TRUE, delete_layer=TRUE)

# finish
}
