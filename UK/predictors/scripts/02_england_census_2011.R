library(nomisr)
library(tidyverse)

# The code below computes area-level predictors from the UK census

# The process for determining the parameters for your calls is 
# Use nomis_search() along with the table from the variable_categories spreadsheet to find the relevant table id
# Use nomis_get_metadata(id = id) to see the different concepts for the table
# Use nomis_get_metadata(id = id, concept = concept) or nomis_codelist(id = id, concept = concept) to find the code(s) for the concepts
# Use nomis_overview(id = id, select = c("units")) to check the units (e.g., persons, families, households) you're dealing with
# The code for doing this for each variable is in "98_uk_census_tables_metadata"

# Note, you haven't done the census data for LAs (which would be nice for mapping purposes)
# The API only allows you to call the LA data for pre-April 2015 LAs
# So, the fastest way to get the LA census data with the May 2020 LAs you use elsewhere is probably to 
# cross-walk from the MSOA census data - for the most part you can average across proportions, but the majority_urban variable is trickier

# Note, at the bottom of this script there is a test API call to check whether the API is working or not

# Begin

# Because for some reason the NomisR API won't return urban population data at the LSOA and MSOA level
# We need to instead call it at the OA level and then sum to get the LSOA and MSOA urban populations 
# The summing is done in the get_census_data_england_2011 function, but prior to running the function we 

# need to get the urban population data at the OA level and a look-up file to match OAs to LSOAs and MSOAs
urban_ppl_oa <- nomis_get_data(id = "NM_143_1", time = "latest", RURAL_URBAN = "100", geography = "TYPE299", measures = "20100",
                               select = c("geography_code", "OBS_VALUE"), CELL = "0") %>%
  rename("urban_ppl" = "OBS_VALUE",
         "oa11cd" = "GEOGRAPHY_CODE") %>%
  filter(substr(oa11cd, 1, 1) == "E")


# As described in downloads script, because May 2020 look-up is missing some OAs,
# we use a different look-up here to the one used in "04_uk_cleaning_merging" (here we use the December 2011 look-up)

oa_lsoa_msoa_lookup_Dec_2011 <- drive_get("Lead_Map_Project/UK/predictors/raw_data/geography_lookup_Dec_2011.csv") |>
  drive_read_string() |>
  read_csv() |>
  select(OA11CD, LSOA11CD, MSOA11CD) |>
  distinct(OA11CD, .keep_all = TRUE) |>
  filter(substr(OA11CD, 1, 1) == "E") |>
  rename("oa11cd" = "OA11CD",
         "lsoa11cd" = "LSOA11CD",
         "msoa11cd" = "MSOA11CD")

# Run function to get census data for the desired geographies (MSOA, here)

census_data_2011_msoa <- get_census_data_england_2011("TYPE297")

# Remove objects we no longer need

rm(oa_lsoa_msoa_lookup_Dec_2011, urban_ppl_oa)

census_data_2011_msoa %>%
  write_csv("../processed_data/census_data_2011_msoa.csv")



######################### TEST THAT YOU KNOW WORKS, TO SEE IF API IS WORKING OR NOT

# eth <- nomis_get_data(id = "NM_608_1", time = "latest", rural_urban = 0, geography = geography_type_code, measures = 20301,
#                      select = c("geography_code", "OBS_VALUE"), CELL = 300)





