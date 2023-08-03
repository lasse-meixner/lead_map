library(tidycensus)
library(tigris)
library(tidyverse)
library(stringr)
library(sf)
library(naniar)

# See 00_US_census_API for how the function is set up 
# Remember to add API key to environment using census_api_key() before running the below

# LEGACY CODE FOR ZCTA: 
# acs_dec_zcta <- get_census_data_us("zcta")

# In order to get it at the tract level, the API requires a state be specified, too. 
# Hence we map over all 51 states

us_states <- unique(fips_codes$state)[1:51]

acs_dec_tract <- map_df(us_states, \(x) {
  get_census_data_us("tract", state_str = x)
})

write_csv(acs_dec_state,"../processed_data/acs_dec_tract.csv")

