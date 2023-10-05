## read in shapefile
required_packages  <- c("googledrive", "tidyverse", "tigris", "sf","rmapshaper")
lapply(required_packages, require, character.only = TRUE)

# requires 00_gdrive_utils.R to be run

gdrive_get_folder("Lead_Map_Project/US/raw_data/roads")

# get all us tract geographies for matching
us_tracts  <- tigris::tracts(cb = TRUE) |> # get tracts for all states in US
  ms_simplify(keep = 0.03) # simplify geometry

# get roads 
roads <- st_read("../raw_data/roads/tl_2021_us_primaryroads.shp") |>
  st_simplify(dTolerance = 100) |> # simplify LINESTRING geometry
  st_join(us_tracts, join = st_intersects) # match road LINESTRING sections to tracts

# get length by type in each tract (runs for a while)
roads_clean  <- roads |> 
  rename(TRACT = GEOID,
         TYPE = RTTYP) |> # rename GEOID to TRACT
  group_by(TRACT, TYPE) |>
  summarize(LENGTH = sum(st_length(geometry)),
            ALAND = first(ALAND),
            .groups = "keep") |>
  # drop unit and round to nearest integer
  mutate(LENGTH = as.integer(LENGTH)) |>
  ungroup() |>
  pivot_wider(names_from = "TYPE", values_from = "LENGTH", values_fill = 0, id_cols = c("TRACT", "ALAND"), names_prefix = "TYPE_") |> # road types to columns
  mutate(across(starts_with("TYPE"), ~ . / ALAND, .names = "{.col}_density")) # create density


# write to .csv in processed_data
write_csv(roads_clean, "../processed_data/roads_clean.csv")

# Write to googledrive
source("00_gdrive_utils.R")
drive_upload_w_tstamp("roads_clean")

