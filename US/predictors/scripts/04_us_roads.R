## read in shapefile
required_packages  <- c("googledrive", "tidyverse", "tigris", "sf")
lapply(required_packages, require, character.only = TRUE)

# check if tl_2021_us_primaryroads.shp exists in "../raw_data/roads", otherwise download all required files from google drive folder

if (!file.exists("../raw_data/roads/tl_2021_us_primaryroads.shp")) {
  # create directory if it does not exist
  dir.create("../raw_data/roads", recursive = TRUE)
  # iterate over files and download
  drive_ls("lasse-frank-test-dir/tl_2021_us_primaryroads") |> 
    # filter name that end with .shp, .shx, .dbf, .prj
    filter(str_detect(name, ".shp$|.shx$|.dbf$|.prj$")) |>
    pull(name) |> 
    map(~ drive_download(paste0("lasse-frank-test-dir/tl_2021_us_primaryroads/", .x), 
                         path = paste0("../raw_data/roads/", .x), 
                         overwrite = TRUE))
}

# get all us tract geographies for matching
us_tracts  <- tigris::tracts(cb = TRUE) # get tracts for all states in US

# read in shapefile
roads <- st_read("../raw_data/roads/tl_2021_us_primaryroads.shp") |>
  st_simplify(dTolerance = 100) |> # simplify geometry
  st_join(us_tracts, join = st_intersects) # match road LINESTRING sections to tracts

# get length by type in each tract
roads_clean  <- roads |> 
  sample_n(1000) |> # sample 1000 rows (otherwise too slow
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
# TODO: Write to googledrive!
