# Project Title: Site Suitability Analysis for Sustainable Housing Developments in Exeter, Devon

This repository contains the R code, spatial data, and outputs for a site suitability analysis assessing potential locations for sustainable housing developments in Exeter, Devon, United Kingdom.

## Files
# Script
- The "Site_Suitability_Analysis" is the R script used for data processing, analysis, and map generation.

# Data
- Exeter_DTM_1m.tif – LiDAR Composite Digital Terrain Model (DTM), 1 m resolution (2022)
- rofrs_4band_Exeter.shp – Risk of Flooding from Rivers and Sea shapefile  
	The two datasets were sourced from https://environment.data.gov.uk
- Data of road network, supermarkets, hospitals, and schools were retrieved from the OpenStreetMap through the API (see script)

## Outputs
The "Outputs" folder contains exported raster, vector, and image files, including final map layouts created in QGIS.
The following layouts were designed in QGIS Layout Manager using vector and raster files generated from the analysis:
- EXETER_HOSPITALS_PROXIMITY_LAYOUT
- EXETER_SUPERMARKETS_PROXIMITY_LAYOUT
- EXETER_FLOOD_RISK_LAYOUT
- EXETER_ROADS_PROXIMITY_LAYOUT
- EXETER_SCHOOLS_PROXIMITY_ANALYSIS
- EXETER_SLOPE_ANALYSIS_LAYOUT
- EXETER_SUITABILITY_SCORE_LAYOUT

All remaining images were exported directly from the analysis results in RStudio.

## How to Run
Ensure the script and the data are located in the same working directory.  
Run the script from the project root using relative file paths.
