# The code in this script obtains data from the US Census Bureau API and processes it

library(tidycensus)
library(tigris)
library(tidyverse)
library(stringr)
library(sf)
library(naniar)

# See 01 script for how the function is set up 

# Remember to add API key to environment using census_api_key() before running the below

acs_dec_zcta <- get_census_data_us("zcta")

acs_dec_county <- get_census_data_us("county")

acs_dec_state <- get_census_data_us("state")









