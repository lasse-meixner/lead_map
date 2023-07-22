# Auxiliary function to merge MSOA geography to the predictors data

library(tidyverse)
library(rdrop2)
library(sf)

# import dropbox access token
source("../scripts/00_drop_box_access.R")

# check if data_msoa is in memory, otherwise read from processed_data directory
if (exists("data_msoa")) {
  print("data_msoa already in memory")
} else {
  data_msoa <- read_csv("../processed_data/combined_msoa.csv")
}

# load MSOA shapefile
drop_get_from_root("shapefiles/msoa/england_msoa_2011.shp")
sf_msoa <- read_sf("../raw_data/england_msoa_2011.shp") %>%
  rename("msoa11cd" = "code",
         "msoa_name" = "name",
         "geometry_msoa" = "geometry") %>%
  dplyr::select(-label)

# merge with data_msoa and convert to shapefile
data_msoa_sf <- sf_msoa %>%
  left_join(., data_msoa) %>%
  st_as_sf()

# write to file
data_msoa_sf %>%
  write_sf("../processed_data/combined_msoa.shp")

# clear environment
rm(list = ls())
