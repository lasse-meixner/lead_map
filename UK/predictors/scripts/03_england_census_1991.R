# CALL DATA FROM 1991 CENSUS AT ED LEVEL
# INCLUDES CROSSWALK TO MSOA LEVEL - SO NEVER STORES THE ED-LEVEL OBJECT OUTSIDE OF THE PIPELINE

require(nomisr)
require(tidyverse)

# PREP WORK FOR ED CROSSWALKING TO MSOA

# Read  in look-up file to get us from Nomis's unique ED codes to the universally used ED (short) codes
# "Short" code in that they exclude the two-digit county prefix

nomis_ed91code_lookup <- nomis_get_metadata(id = "NM_38_1", concept = "GEOGRAPHY", type = "TYPE7") %>%
  select(id, label.en) %>%
  rename("GEOGRAPHY_CODE_1991" = "id",
         "ed91code_short" = "label.en") %>%
  mutate(ed91code_short = substr(ed91code_short, 1, 6),
         GEOGRAPHY_CODE_1991 = as.numeric(GEOGRAPHY_CODE_1991))

# Read in crosswalk file to crosswalk ED counts to 2011 MSOA counts (from dropbox)

ed_msoa_lookup <- drop_read_csv(paste0(drop_box_base_url,"ed_msoa_lookup.csv")) %>%
  select(-4) %>%
  rename("ed91code" = 1,
         "propotion_of_ed_in_msoa" = 2,
         "msoa11cd" = 3) %>%
  mutate(ed91code_short = substr(ed91code, 3, 8))

# API CALL

census_data_1991_msoa <- get_census_data_england_1991() # only uses ED, so no geography_type arg
  

rm(nomis_ed91code_lookup, ed_msoa_lookup)
  
census_data_1991_msoa %>%
  write_csv("..processed_data/census_data_1991_msoa.csv")

