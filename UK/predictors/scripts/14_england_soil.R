# This script computes MSOA-level variables using the soil data

# Mean across soil squares with centroids in MSOA, and IDW mean based on distance of square centroid from MSOA centroid
# Mean across soil squares intersecting MSOA, and IDW mean based on distance of intersecting square centroid from MSOA centroid

require(tidyverse)
library(raster)
library(sp)
library(sf)

gdrive_get_file("Pb_grid.txt")
soil_sf <- raster("../raw_data/Pb_grid.txt") %>%
  as(.,'SpatialPolygonsDataFrame') %>%
  st_as_sf() %>%
  rename("geometry_soil_cell" = "geometry",
         "soil_lead" = "Pb_grid") %>%
  mutate(geometry_soil_centroid = st_centroid(geometry_soil_cell))

gdrive_get_folder("Lead_Map_Project/UK/predictors/raw_data/shapefiles/msoa") # downloads all files in case folder doesnt exist
sf_msoa <- read_sf("../raw_data/shapefiles/msoa/england_msoa_2011.shp") %>%
  rename("msoa11cd" = "code",
         "msoa_name" = "name",
         "geometry_msoa" = "geometry") %>%
  dplyr::select(-label)

st_crs(soil_sf) <- st_crs(sf_msoa)

# read directly from Gdrive
centroids_population_msoa <- drive_get("Lead_Map_Project/UK/predictors/raw_data/msoa_population_centroids.csv") |>
  drive_read_string() |>
  read_csv() |>
  dplyr::select(-objectid) %>%
  filter(substr(msoa11cd, 1, 1) == "E") %>%
  st_as_sf(coords = c("X", "Y"),
           crs = 27700) %>%
  as_tibble() %>%
  rename("geometry_msoa_centroid" = "geometry")


# Spatial join soil grid cells to MSOAs
# For each MSOA, you will have all of the soil squares which intersect it (and vice versa)
# And left join to MSOA centroids
st_geometry(soil_sf) <- "geometry_soil_cell"
soil_grid_msoa_w_centroids_overlap_join <- st_join(sf_msoa, soil_sf) %>%
  as_tibble() %>%
  left_join(., centroids_population_msoa) %>%
  mutate(centroid_distance = as.numeric(st_distance(st_geometry(geometry_msoa_centroid) %>% st_set_crs(27700),
                                                    st_geometry(geometry_soil_centroid) %>% st_set_crs(27700),
                                                    by_element = TRUE)), 
         inverse_centroid_distance = 1 / centroid_distance)

soil_msoa <- soil_grid_msoa_w_centroids_overlap_join %>%
  group_by(msoa11cd) %>%
  summarise(soil_lead_mean = mean(soil_lead),
            soil_lead_mean_idw = weighted.mean(soil_lead, inverse_centroid_distance), 
            n_soil_grid_cells = sum(!is.na(soil_lead)))

soil_msoa %>%
  write_csv("../processed_data/soil_msoa.csv")

rm(soil_sf, centroids_population_msoa, soil_grid_msoa_w_centroids_overlap_join)

