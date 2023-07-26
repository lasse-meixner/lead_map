# This script will compute neighbours variables and densities corresponding to the MSOA pollution variables computed in scripts 11 and 12

library(tidyverse)
library(sf)

# check that emissions_polluter_counts_msoa (result file form 12_) is already in memory, otherwise prompt user to run previous script
if (exists("emissions_polluter_counts_msoa")) {
  print("emissions_polluter_counts_msoa already in memory")
} else {
  stop("Please run 12_england_pollution_counts.R before running this script")
}

# if 12 has been run, then sf_msoa should already be in memory
sf_msoa <- sf_msoa %>%
  rename("msoa11cd" = "code",
         "msoa_name" = "name") %>%
  dplyr::select(-label)

# Read in MSOA land areas to compute densities
land_area_msoa <- drop_read_csv(paste0(drop_box_base_url,"shapefiles/msoa_land_area/SAM_MSOA_DEC_2011_EW.csv")) %>%
  rename("msoa11cd" = "MSOA11CD",
         "msoa_name" = "MSOA11NM",
         "area" = "AREALHECT") %>%
  filter(substr(msoa11cd, 1, 1) == "E") %>%
  dplyr::select(msoa11cd, msoa_name, area)

pollution_land_area_msoa_study_area_sf <- emissions_polluter_counts_msoa %>%
  left_join(., land_area_msoa) %>%
  left_join(., sf_msoa) %>%
  st_as_sf()
  
# Identify each MSOA's neighbours (by their index numbers in the pollution_land_area_msoa_sf sf object)
neighbours_msoa <- st_intersects(pollution_land_area_msoa_study_area_sf, pollution_land_area_msoa_study_area_sf)

# Sum emissions amounts and counts of polluters across each MSOA and its neighbours and take densities 
# Select out non-density columns, but keep area denominator

pollution_msoa <- pollution_land_area_msoa_study_area_sf %>%
  mutate(across(.cols = c(emissions_total_yearly_1993:polluter_count_2008,
                          area), 
                .fns = ~sapply(neighbours_msoa, function(n){sum(.x[n], na.rm = TRUE)}),
                .names = "{.col}_neighbours")) %>%
  # Take densities, making sure to divide greater MSOA variables by the greater MSOA area
  mutate(across(.cols = emissions_total_yearly_1993:polluter_count_2008, 
                .fns = ~./area, 
                .names = "{.col}_density"),
         across(.cols = emissions_total_yearly_1993_neighbours:polluter_count_2008_neighbours, 
                .fns = ~./area_neighbours, 
                .names = "{.col}_density")) %>%
  st_drop_geometry() %>%
  dplyr::select(-c(emissions_total_yearly_1993:polluter_count_2008, emissions_total_yearly_1993_neighbours:polluter_count_2008_neighbours)) %>%
  # Select out area columns because we'll get these from the roads_msoa dataframe
  dplyr::select(-contains("area"))

pollution_msoa %>%
  write_csv("data_processed/pollution_msoa.csv")
