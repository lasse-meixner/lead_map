library(googledrive)
library(tidyverse)
library(tigris)

# NOTE: Use drive_ls(path) to get list of available files. 

# read tri data straight from source
tri <- drive_get("lasse-frank-test-dir/TRI_Lead_1987-2022.csv") |> 
  drive_read_string() |> 
  read_csv()

# auxiliary function to get tract based on lat/lon: to be applied on each state
get_tract <- function(tri_state, state_name){
  # get tracts for state at lower resolution
  state_tracts <- tracts(state = state_name, cb = TRUE)
  
  tri_state_w_tract <- tri_state |>
    st_as_sf(coords = c("LONGITUDE", "LATITUDE"), crs = 4326) |>
    st_transform(st_crs(state_tracts)) |>
    st_join(state_tracts) |>
    rename(TRACT = GEOID) |>
    as_tibble() # transform back into tibble (drop Geometry)
  
  tri_state_w_tract
}


# clean file, including tract matching
tri_w_tract <- tri |> 
  group_by(STATE_ABBR) |>
  nest() |>
  mutate(data = map2(data, unique(STATE_ABBR), function(x, y) {
    tryCatch(get_tract(x, y), error = function(e) {
      message(paste0("Error in state ", y))
      NULL
    })
  })) |> # apply get_tract on each state
  unnest()

tri_cleaned <- tri_w_tract |> 
  select(REPORTING_YEAR, TRACT, TRI_FACILITY_ID, STATE_ABBR, COUNTYFP, ALAND, starts_with("TOTAL")) |>
  # group by year and tract and take sums of TOTAL cols, also keep constant STATE_ABBR and COUNTYFP
  group_by(REPORTING_YEAR, TRACT) |>
  summarize(STATE_ABBR = first(STATE_ABBR), 
            COUNTYFP = first(COUNTYFP),
            ALAND = first(ALAND),
            across(starts_with("TOTAL"), \(x) sum(x, na.rm = TRUE))) |> 
  ungroup() |>
  # create additional columns with a "_density" suffix for densitites: divide all TOTALs by ALAND
  mutate(across(starts_with("TOTAL"), ~ . / ALAND, .names = "{.col}_density")) |>
  # create cumulative columns with a "_cumulative" suffix for cumulative totals: for each year, the sum of all previous years in that tract
  group_by(TRACT) |>
  mutate(across(starts_with("TOTAL"), ~ cumsum(.), .names = "{.col}_cumulative"))

# write to .csv in processed_data
write_csv(tri_cleaned, "../processed_data/tri_cleaned.csv")
# TODO: Write to googledrive!
