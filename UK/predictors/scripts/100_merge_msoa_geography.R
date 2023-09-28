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
gdrive_get_folder("Lead_Map_Project/UK/predictors/raw_data/shapefiles/msoa") # downloads all files in case folder doesnt exist
sf_msoa <- read_sf("../raw_data/shapefiles/msoa/england_msoa_2011.shp") %>%
  rename("msoa11cd" = "code",
         "msoa_name" = "name",
         "geometry_msoa" = "geometry") %>%
  dplyr::select(-label)

# merge with data_msoa and convert to shapefile
data_msoa_sf <- data_msoa %>%
  left_join(., sf_msoa) %>%
  st_as_sf()

# clear environment except data_msoa_sf
rm(list = ls() %>% setdiff("data_msoa_sf"))
