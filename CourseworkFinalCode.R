# Topic: Site Suitability Analysis for Sustainable Housing Developments in Exeter, Devon
# Date: December 2025

## Automate Data Retrieval and Spatial Processing
# Fetch and transform OSM data
getOSMFeature <- function(bbox, key, value, type = "lines"){
  # Add timeout = 120 to wait 2 minutes for server response. This fixes timing out after 25seconds
  # whenever the Open Street Map API is busy 
  query <- osmdata::opq(bbox = bbox, timeout = 120) %>% 
    osmdata::add_osm_feature(key = key, value = value) %>% 
    osmdata::osmdata_sf()
  if(type == "lines") {
    data <- query$osm_lines
  } else {
    # Combine points and polygons (centroids) for buildings like schools/markets
    poly <- query$osm_polygons
    pts  <- query$osm_points
    if(!is.null(poly) & !is.null(pts)) data <- dplyr::bind_rows(pts, sf::st_centroid(poly))
    else data <- if(!is.null(pts)) pts else sf::st_centroid(poly)
  }
  # Project the OSM data back to British National Grid
  if(!is.null(data)) return(sf::st_transform(data, sf::st_crs(elevationRaster)))
  return(NULL)
}

## Shapefile Export
# Clean and export shapefiles
export_clean_shapefile <- function(data, filename) {
  
  # Keep only the 'name' column
  if("name" %in% names(data)) {
    data_clean <- data[, "name"]
  } else {
    data$name <- "Unknown"
    data_clean <- data[, "name"]
  }
  
  # Write file
  sf::st_write(data_clean, filename, quiet = TRUE, delete_layer = TRUE)
  print(paste("Success: Exported", filename))
}

# Load libraries
library("sf")
library("terra")
library("osmdata")
library("tmap")
library("tidyverse")

# Load the LIDAR Composite DTM for 2022 with 1m resolution 
dtmFilename <- "Exeter_DTM_1m.tif"
if(!file.exists(dtmFilename)) stop("DTM file missing!")
elevationRaster <- rast(dtmFilename)

# Load the "Risk of Flooding from Rivers and Sea" shapefile
floodFilename <- "rofrs_4band_Exeter.shp"
if(!file.exists(floodFilename)) stop("Flood file missing!")
floodVector <- st_read(floodFilename)

## Analyse the slope data
# Calculate slope from elevation. 
slopeMap <- terrain(elevationRaster, v = "slope", unit = "degrees")
# Set Rule: Slopes < 10 degrees are suitable (1), > 10 are unsuitable (0)
slopeSuitability <- ifel(slopeMap < 10, 1, 0)

## Analyse the flood data
# Ensure CRS matches (Project Flood Vector to Raster's British National Grid)
floodVector <- st_transform(floodVector, st_crs(elevationRaster))
# Convert the flood polygons into the DTM binary grid
floodRaster <- rasterize(floodVector, elevationRaster, field = 1, background = 0)
# Apply suitability logic: Safe Areas (1) and Flooded Areas (0)
floodSuitability <- ifel(floodRaster == 0, 1, 0)


## Add the Amenities
# Reproject study area to WGS84 (Lat/Lon) for OpenStreetMap API
studyAreaBox <- st_as_sfc(st_bbox(elevationRaster))
studyAreaLatLon <- st_transform(studyAreaBox, 4326)
bboxObj <- st_bbox(studyAreaLatLon)

# Fetch the Amenities Layers
roadsVector <- getOSMFeature(bboxObj, "highway", c("primary", "secondary", "tertiary"), "lines")

schoolsVector <- getOSMFeature(bboxObj, "amenity", "school", "polygons")
if(!is.null(schoolsVector)) schoolsVector <- schoolsVector %>% filter(!is.na(name))

marketsVector <- getOSMFeature(bboxObj, "shop", "supermarket", "polygons")
if(!is.null(marketsVector)) marketsVector <- marketsVector %>% filter(!is.na(name))

hospitalsVector <- getOSMFeature(bboxObj, "amenity", "hospital", "polygons")
if(!is.null(hospitalsVector)) hospitalsVector <- hospitalsVector %>% filter(!is.na(name))

# Aggregate the DTM from 1m to 10m resolution to speed up processing.
elevationRasterLowRes <- aggregate(elevationRaster, fact = 10, fun = mean)

# Calculate Distances to each amenity
roadDist   <- distance(elevationRasterLowRes, vect(roadsVector))
schoolDist <- distance(elevationRasterLowRes, vect(schoolsVector))
marketDist <- distance(elevationRasterLowRes, vect(marketsVector))
hospDist   <- distance(elevationRasterLowRes, vect(hospitalsVector))

# Classify Distances (1 = Suitable, 0 = Too Far). Set Thresholds: Roads 500m, Schools/Markets 1000m, Hospitals 2000m
scoreRoad   <- ifel(roadDist < 500, 1, 0)
scoreSchool <- ifel(schoolDist < 1000, 1, 0)
scoreMarket <- ifel(marketDist < 1000, 1, 0)
scoreHosp   <- ifel(hospDist < 2000, 1, 0)

# Resample the flood and slope risk to the new 10m DTM
floodSuitability <- resample(floodSuitability, elevationRasterLowRes, method = "near")
slopeSuitability <- resample(slopeSuitability, elevationRasterLowRes, method = "near")

# Calculate Final Score
totalScore <- (scoreRoad + scoreSchool + scoreMarket + scoreHosp) * (floodSuitability * slopeSuitability)

# Mask results to the exact study area shape (remove ocean/edges)
finalPlot <- mask(totalScore, elevationRasterLowRes)

# Set the tmap library to static plotting mode
tmap_mode("plot")

## Generate all output maps 
## Mask the output data to the study area (Exeter DTM 10m) so it looks clean
## Set the layout, grid and legend styles
## Plot and save output as png

# Set the grid style
custom_grid <- tm_grid(
  n.x = 4, n.y = 4,
  labels.inside = FALSE,
  labels.size = 0.7,
  col = "grey40",
  alpha = 0.4,
  labels.format = list(digits = 3, big.mark = ",", scientific = FALSE)
)

# Set the Legend Layout Style
custom_layout <- tm_layout(
  legend.outside = TRUE,
  legend.outside.position = "right",
  legend.outside.size = 0.25,
  inner.margins = c(0.1, 0.1, 0.05, 0.05), 
  main.title.size = 1.1,
  frame = TRUE
)

#  Plot and save roads
mapRoads <- tm_shape(mask(scoreRoad, elevationRasterLowRes)) +
  tm_raster(col.scale = tm_scale_categorical(values = c("grey90", "orange"), 
                                             labels = c("> 500m", "< 500m")),
            col.legend = tm_legend(title = "Road Access")) +
  tm_shape(roadsVector) + 
  tm_lines(col = "black", col_alpha = 0.3) +
  
  custom_grid +
  tm_compass(position = c("left", "top"), size = 2.0) +
  tm_scalebar(position = c("left", "bottom")) + 
  
  tm_title("Public Transport System") +
  custom_layout
  mapRoads
tmap_save(mapRoads, "Exeter_Public_Transport.png", width=10, height=8)

# Plot and save schools
mapSchools <- tm_shape(mask(scoreSchool, elevationRasterLowRes)) +
  tm_raster(col.scale = tm_scale_categorical(values = c("grey90", "blue"), 
                                             labels = c("> 1km", "< 1km")),
            col.legend = tm_legend(title = "School Access")) +
  tm_shape(schoolsVector) + 
  tm_dots(size = 0.5) +
  
  custom_grid +
  tm_compass(position = c("left", "top"), size = 2.0) +
  tm_scalebar(position = c("left", "bottom")) +
  
  tm_title("Schools") +
  custom_layout
mapSchools
tmap_save(mapSchools, "Exeter_Sustainability_Schools.png", width=10, height=8)

# Plot and save markets
mapMarkets <- tm_shape(mask(scoreMarket, elevationRasterLowRes)) +
  tm_raster(col.scale = tm_scale_categorical(values = c("grey90", "purple"), 
                                             labels = c("> 1km", "< 1km")),
            col.legend = tm_legend(title = "Market Access")) +
  tm_shape(marketsVector) + 
  tm_dots(size = 0.5) +
  
  custom_grid +
  tm_compass(position = c("left", "top"), size = 2.0) +
  tm_scalebar(position = c("left", "bottom")) +
  
  tm_title("Supermarkets") +
  custom_layout
  mapMarkets
tmap_save(mapMarkets, "Exeter_Sustainability_Supermarkets.png", width=10, height=8)

# Plot and save hospitals
mapHospitals <- tm_shape(mask(scoreHosp, elevationRasterLowRes)) +
  tm_raster(col.scale = tm_scale_categorical(values = c("grey90", "red"), 
                                             labels = c("> 2km", "< 2km")),
            col.legend = tm_legend(title = "Hospital Access")) +
  tm_shape(hospitalsVector) + 
  tm_dots(size = 0.8, shape = 3) +
  
  custom_grid +
  tm_compass(position = c("left", "top"), size = 2.0) +
  tm_scalebar(position = c("left", "bottom")) +
  
  tm_title("Hospitals") +
  custom_layout
  mapHospitals
tmap_save(mapHospitals, "Exeter_Sustainability_Hospitals.png", width=10, height=8)

# Plot and save Flood Risk Analysis
constraintsMap <- (floodSuitability * slopeSuitability)
mapConstraints <- tm_shape(mask(constraintsMap, elevationRasterLowRes)) +
  tm_raster(col.scale = tm_scale_categorical(values = c("#D95F02", "#1B9E77"), 
                                             labels = c("Flood-Prone", "Safe")),
            col.legend = tm_legend(title = "Flood")) +
  
  custom_grid +
  tm_compass(position = c("left", "top"), size = 2.0) +
  tm_scalebar(position = c("left", "bottom")) +
  
  tm_title("Flood Risk Analysis") +
  custom_layout
  mapConstraints
tmap_save(mapConstraints, "Exeter_FloodRisk_Analysis.png", width=10, height=8)

#Plot and save the slope analysis
slopePlotData <- mask(slopeSuitability, elevationRasterLowRes)
mapSlope <- tm_shape(slopePlotData) +
  tm_raster(col.scale = tm_scale_categorical(
    values = c("#D95F02", "#1B9E77"), 
    labels = c("> 10° (Steep)", "< 10° (Flat)")),
    col.legend = tm_legend(title = "Terrain Suitability")) +
  
  custom_grid +
  tm_compass(position = c("left", "top"), size = 2.0) +
  tm_scalebar(position = c("left", "bottom")) +
  
  tm_title("Slope Analysis (10° Threshold)") +
  custom_layout
  mapSlope
tmap_save(mapSlope, "Exeter_Slope_Analysis.png", width=10, height=8)

# Plot and save the Amenity density
amenitySum <- (scoreRoad + scoreSchool + scoreMarket + scoreHosp)
mapAmenitySum <- tm_shape(mask(amenitySum, elevationRasterLowRes)) +
  tm_raster(col.scale = tm_scale_categorical(values = "Blues"),
            col.legend = tm_legend(title = "Amenity Count")) +
  
  custom_grid +
  tm_compass(position = c("left", "top"), size = 2.0) +
  tm_scalebar(position = c("left", "bottom")) +
  
  tm_title("Amenity Density") +
  custom_layout
  mapAmenitySum
tmap_save(mapAmenitySum, "Exeter_Amenity_Density.png", width=10, height=8)

# Plot and save final sustainability score
mapFinal <- tm_shape(finalPlot) +
  tm_raster(col.scale = tm_scale_categorical(
    values = c("#D95F02", "#FDBF6F", "#FFF7BC", "#A6D96A", "#1A9850"),
    labels = c("Unsuitable", "1 Amenity", "2 Amenities", "3 Amenities", "Fully Sustainable (4)")),
    col.legend = tm_legend(title = "Suitability Score")) +
  
  custom_grid +
  tm_compass(position = c("left", "top"), size = 2.0) +
  tm_scalebar(position = c("left", "bottom")) +
  
  tm_title("Suitability Score for Sustainable Housing Development in Exeter") +
  custom_layout
  mapFinal
tmap_save(mapFinal, "Exeter_Suitability_Score.png", width=10, height=8)

## Export vector data
# Export the shapefiles for Roads, Schools, Markets, hospitals and flood zones
export_clean_shapefile(roadsVector,     "Roads.shp")
export_clean_shapefile(schoolsVector,   "Schools.shp")
export_clean_shapefile(marketsVector,   "Markets.shp")
export_clean_shapefile(hospitalsVector, "Hospitals.shp")
export_clean_shapefile(floodVector,     "FloodZones.shp")


## Export Raster Files
## Mask them to 'elevationRasterLowRes' (The 10m DTM) so they have clean edges like the images.
# Export the calculated Distances (in metres) rasters
writeRaster(mask(roadDist, elevationRasterLowRes),   "Distance_to_Roads.tif",   overwrite = TRUE)
writeRaster(mask(schoolDist, elevationRasterLowRes), "Distance_to_Schools.tif", overwrite = TRUE)
writeRaster(mask(marketDist, elevationRasterLowRes), "Distance_to_Markets.tif", overwrite = TRUE)
writeRaster(mask(hospDist, elevationRasterLowRes),   "Distance_to_Hospitals.tif", overwrite = TRUE)

# Export Constraint (Flood and Slope) raster
writeRaster(mask(floodSuitability, elevationRasterLowRes), "Flood_Analysis.tif", overwrite = TRUE)
writeRaster(mask(slopeSuitability, elevationRasterLowRes), "Slope_Analysis.tif", overwrite = TRUE)

# Export Exeter Sustainability score raster
writeRaster(mask(amenitySum, elevationRasterLowRes), "Amenity_Density.tif", overwrite = TRUE)
writeRaster(finalPlot,                               "Final_Sustainability_Score.tif", overwrite = TRUE)

# Export 10m DTM
writeRaster(elevationRasterLowRes, "Exeter_DTM_10m.tif", overwrite = TRUE)
