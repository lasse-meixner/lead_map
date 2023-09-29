# this file pulls and simplifies tract geometries for the entire US for plotting purposes

library(tidyverse)
library(tigris)
library(sf)
library(rmapshaper)

us_tracts  <- tigris::tracts(cb = TRUE) |> # get tracts for all states in US
  ms_simplify(keep = 0.02) |> # simplify geometry
  select(GEOID, STATE_NAME, NAMELSADCO, geometry) |> 
  rename(TRACT = GEOID,
         STATE = STATE_NAME,
         COUNTY = NAMELSADCO)

# if no shapefiles subfolder exists in processed_data, create it
if (!dir.exists("../predictors/raw_data/shapefiles")) {
    dir.create("../predictors/raw_data/shapefiles")
}
  
# save shapefiles
us_tracts |>
  st_write("../predictors/raw_data/shapefiles/us_tracts.shp", append = FALSE)