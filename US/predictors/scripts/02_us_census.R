library(tidycensus)
library(tigris)
library(tidyverse)
library(naniar)
library(stringr)
library(sf)

source("00_US_census_API.R")

# See 00_US_census_API for how the function is set up 
# Remember to add API key to environment using census_api_key() before running the below

# LEGACY CODE FOR ZCTA: 
# acs_dec_zcta <- get_census_data_us("zcta")

# In order to get it at the tract level, the API requires a state be specified, too. 
# Hence we map over all 51 states

us_states <- unique(fips_codes$state)[1:51]

acs_dec_tract <- map_df(us_states, \(x) {
  get_census_data_us("tract", state_str = x)
}) |>
  rename(TRACT = GEOID)

# save to disk
acs_dec_tract |>
  write_csv("../processed_data/acs_dec_tract.csv")

# save to Gdrive
source("00_gdrive_utils.R")
drive_upload_w_tstamp("acs_dec_tract")
