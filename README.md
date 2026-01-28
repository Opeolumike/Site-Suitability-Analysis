# Project Title: Site Suitability Analysis for Sustainable Housing Developments in Exeter, Devon

For any housing development to be termed "sustainable", it must be environmentally fit (i.e., safe from flooding and terrain risks) and socially accessible (i.e., within proximity to existing infrastructural developments).

This study focused on Exeter, a city in Devon, South-West England with a population of 130,700 in 2021 as at the 2021 Census. In 2021, Exeter was home to around 19.8 people per football pitch-sized (approximately 7,140sqm) piece of land, compared with 17.9 in 2011. This area was among the top 25% most densely populated English local authority areas at the last census (How life has changed in Exeter: Census 2021). 

Exeter is a perfect case study for the need to create balance between housing needs and environmental protection. It is well-known for complex topography that ranges from the low-lying and flood-prone valley of the River Exeter to the steep gradients of the northern hills such as Pennsylvania and Exwick

This repository contains the R code, spatial data, and outputs for a site suitability analysis assessing potential locations for sustainable housing developments in Exeter, Devon, United Kingdom.

## Files
# Script
- The "Site_Suitability_Analysis" is the R script used for data processing, analysis, and map generation.

# Data
- Exeter_DTM_1m.tif – LiDAR Composite Digital Terrain Model (DTM), 1 m resolution (2022)
- rofrs_4band_Exeter.shp – Risk of Flooding from Rivers and Sea shapefile  
	The two datasets were sourced from https://environment.data.gov.uk
- Data of road network, supermarkets, hospitals, and schools were retrieved from the OpenStreetMap through the API using the osmdata R package 

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

## Results
The constraint analysis successfully identified No-Build zones. The Slope Analysis (Figures 2 and 10) highlight the steep topography surrounding the Exe valley, specifically the hills to the northwest (Exwick) and the ridges to the east. When compared with the with the flood risk analysis (Figures 1 and 9), these constraints significantly reduce the available land for sustainable housing developments in Exeter.

The final outputs aggregated the factors considered into single suitability map. The dark green areas represent sites that meet all four amenity criteria while avoiding all constraints. These prime locations are notably clustered around the Heavitree and Wonford (294,000E, 92,000N) areas. This score is driven largely by their score on the slope and flood analysis, including the hospital proximity which also overlaps with the dense road network and proximity to schools and supermarkets. 

Unsurprisingly, most part of River Exe floodplain/Trew's Weir area (Approximately 291,500E, 91,000N) are marked unsuitable with a score of 0. However, small isolated clusters of suitable (green) pixels appear within this channel (see figures 8 and 15). These likely correspond to elevated embankments or islands between the river and the ship canal which fall outside the specific Defra flood risk vector used. Technically, these areas are safe for sustainable housing developments safe due to the model used for this analysis. However, a human planner would likely reject these sites due to lack of physical access, risk perception, and zoning. This highlights the limitation of a purely automated workflow.

## This analysis successfully demonstrated that R can be used to build an effective and automated site suitability model for sustainable housing developments. Performing this task using a traditional GIS software such as QGIS or ArcGIS Pro would have taken twice the amount of time. Not only that, this model can be used for future analysis by just changing some values and variables and my results would be ready in minutes compared to spending several hours on desktop GIS software.

## How to Run the Analysis
Ensure the script and the data are located in the same working directory.  
Run the script from the project root using relative file paths.

## References
Department for Environment, Food & Rural Affairs (2024) Survey Data Download (LiDAR) and Risk of Flooding from Rivers and Sea (RoFRS). Available at: https://environment.data.gov.uk/ (Accessed: 28 November 2025).

Hijmans, R. J. (2024) terra: Spatial Data Analysis. R package version 1.7-71. Available at: https://cran.r-project.org/package=terra (Accessed: 28 November 2025).

Nash, A. (2019) National population projections: 2018-based. Office for National Statistics. Available at: https://www.ons.gov.uk/peoplepopulationandcommunity/populationandmigration/populationprojections/bulletins/nationalpopulationprojections/2018based/previous/v2 (Accessed: 30 November 2025).

Office for National Statistics (2021) How life has changed in Exeter: Census 2021. Available at: https://www.ons.gov.uk/visualisations/censusareachanges/E07000041/ (Accessed: 30 November 2025).

OpenStreetMap Contributors (2025) Planet dump. Available at: https://planet.osm.org (Accessed: 25 November 2025).

Padgham, M., Rudis, B., Lovelace, R. and Salmon, M. (2024) osmdata: Import 'OpenStreetMap' Data as Simple Features or Spatial Objects. R package version 0.2.5. Available at: https://cran.r-project.org/package=osmdata (Accessed: 25 November 2025).

Pebesma, E. (2018) 'Simple Features for R: Standardized Support for Spatial Vector Data', The R Journal, 10(1), pp. 439-446.

Prochorskaite, A., Couch, C., Malys, N. and Maliene, V. (2016) 'Housing stakeholder preferences for the “Soft” features of sustainable and healthy housing design in the UK', International Journal of Environmental Research and Public Health, 13(1), p. 111.

R Core Team (2024) R: A Language and Environment for Statistical Computing. Vienna, Austria: R Foundation for Statistical Computing. Available at: https://www.R-project.org/ (Accessed: 28 November 2025).
Savills (2025) English Housing Supply Update Q2 2025. Available at: https://www.savills.co.uk/research_articles/229130/380149-0 (Accessed: 30 November 2025).

Tennekes, M. (2018) 'tmap: Thematic Maps in R', Journal of Statistical Software, 84(6), pp. 1-39.

Wickham, H. et al. (2019) 'Welcome to the Tidyverse', Journal of Open Source Software, 4(43), p. 1686.
