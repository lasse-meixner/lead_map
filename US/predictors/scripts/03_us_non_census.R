# SVI 

# Here we crosswalk the SVI from census tracts to ZCTAs in order to then merge with the ZCTA level census data
# There is also the option to crosswalk the SVI to zip-codes rather than ZCTAs (which is done beneath)
# Since all of the census data is at ZCTA level it seemed more correct to crosswalk to ZCTAs
# but I don't think it really matters a lot(?)

# At the end of the code, we merge the SVI data with the census data from script 07

# First, a few notes on ZCTAs vs Zips, then the code for getting the SVI data at ZCTA level

# Some notes to self on ZCTAs vs Zips:
# HOW ARE ZCTAs FORMED?
# Bottom line is it's okay to allocate zip-code SVI and BLL values directly to ZCTAs. (Although we only need to do this for BLL) 
# This link contains the information you need to understand why:
# https://www.census.gov/programs-surveys/geography/guidance/geo-areas/zctas.html
# In summary, it's okay because every census block which went into making a ZCTA is in that ZCTA because 
# it belongs in some way (either population or geography) to the zip-code which the ZCTA takes its name from
# So, for example, if you wanted to know the population of a zip, using the population of the corresponding ZCTA 
# Would be like very much like using the summed population of all of the census blocks in that zip
# There will be "holes" if you map 2010 ZCTAs because 
# "For the 2010 Census, large water bodies and large unpopulated land areas do not have ZCTAs."
# If there are holes in ZCTAs then probably not ideal for mapping purposes?
# Although if they're just in unpopulated areas could just colour them grey?

# Getting SVI data at ZCTA level

library(readxl)
library(tidyverse)
library(zipcodeR)

# Read in SVI data, keeping only the columns for the tract percentile according to each of the four SVI themes and the overall SVI
# and columns to identify the tract each row describes
# Replace all -999s (missing values) with NA
# Why are there missing values? Are these tracts where (almost) nobody lives?
# There were 73,057 tracts in the 2010 census, why are there 220 fewer in the SVI data?

svi_tract <- read.csv("data_raw/us/svi_tracts.csv") %>%
  rename("ST" = 1,
         "svi_socioeconomic_pctile" = "RPL_THEME1",
         "svi_disability_pctile" = "RPL_THEME2",
         "svi_minority_lang_pctile" = "RPL_THEME3",
         "svi_housing_transprt_pctile" = "RPL_THEME4",
         "svi_pctile" = "RPL_THEMES",
         "tract" = "FIPS") %>%
  select(c(ST:LOCATION, svi_socioeconomic_pctile, svi_disability_pctile, 
           svi_minority_lang_pctile, svi_housing_transprt_pctile, svi_pctile)) %>%
  mutate(across(.cols = svi_socioeconomic_pctile:svi_pctile, .fns = ~ifelse(. == -999, NA, .)),
         tract = as.character(tract))

 
# Read in the relationship file needed for the crosswalk
# This relationship file, from the census bureau, will tell us the percentage of its ZCTA's population each census tract accounts for 
# E.g., if census tract 956300 accounts for 23% ZCTA 00601's population, there will be a row in the relationship file 
# where tract is 956300, ZCTA is 00601 and ZPOPPCT is 23
# Note, because census tracts lie enirely within ZCTAs, the proportion of each census tract which lies in each ZCTA is
# simply 100% for the one ZCTA that each census tract lies entirely within

tract_zcta_lookup <- read_delim("data_raw/us/tract_zcta_lookup.txt") %>%
  select(c(ZCTA5:GEOID, ZPOPPCT))

# Perform the crosswalk
# Within each ZCTA take the weighted mean of the SVI percentiles across the census tracts in that ZCTA 
# (weighted by the population of each census tract)

svi_zcta <- left_join(tract_zcta_lookup, svi_tract, by = c("GEOID" = "tract")) %>%
  group_by(ZCTA5) %>%
  summarise(across(.cols = svi_socioeconomic_pctile:svi_pctile, 
                   .fns = ~weighted.mean(., ZPOPPCT, na.rm = TRUE), 
                   .names = "{.col}_zcta")) %>%
  mutate(across(.cols = everything(), .fns = ~ifelse(is.nan(.), NA, .)))

rm(tract_zcta_lookup, svi_tract)



######################################################### below, if you wanted to crosswalk to zips (no particular reason to do this)
  
# We can also crosswalk the SVI to zip-codes, rather than to ZCTAs (although the result is very similar)
# To do this, we use a different relationship file to the above - 
# i.e., one that gives the proportion of each ZIP-CODE's population accounted for by each census tract, rather than proportion of each ZCTA
# Note, crucially, a census tract can contribute to the population of multiple zip-codes (since census tract can lie in multiple zip-codes)
# whereas a census tract can only contribute to the population of one ZCTA because census tracts lie entirely within their ZCTA 

# This relationship file is the one from the HUD

# Note also that, slightly counter-intuitively, for getting the SVI scores at zip-code level we actually use the 
# zip-to-tract relationship file rather than the tract-to-zip relationship file.
# This is because the zip-to-tract relationship file tells us the proportion of each zip-code that lies in each census tract 
# which is what we need for computing (population-weighted) average SVI percentiles across tracts for each zip-code
# The tract-to-zip relationship file, on the other hand, contains the proportion of each census tract which lies in each zip-code
# This would enable us to aggregate count variables (like population) from the tract level to zip-code level, since there you aren't
# taking a weighted average across tracts in a particular zip-code.
# Rather, you're summing across tracts the number of say people who live in a particular zip-code

# Note also that the number of zips in the HUD crosswalk relationship files is less than the total number of zips nationwide because:
# "HUD is unable to geocode a small number of records that we receive from the USPS. 
# As a result, there may be some 5-digit USPS ZIP codes that will not be included in these crosswalk files. 
# Less than 1% of the total number of active 5-digit ZIP codes in the country are excluded from the current version of the crosswalk files."
# According to: https://www.huduser.gov/portal/datasets/usps_crosswalk.html#codebook

# CODE STARTS BELOW (COMMENTED OUT)

# Download and read in the HUD zip to tract relationship file
# 
# # Read in, filtering out Puerto Rico zip codes and removing leading zeroes from tract FIPS 
# zip_tract_lookup <- read_excel("data_raw/us/zip_tract_lookup.xlsx") %>%
#   filter(usps_zip_pref_state != "PR")  %>%
#   mutate(tract = str_remove(tract, "^0+"))
# 
# # Perform the crosswalk
# # Here, we use resident addresses per census tract as the weighted in the weighted mean calculation
# # (since population isn't an option)
# 
# # Here is the tract to zip crosswalk
# 
# svi_zip <- left_join(zip_tract_lookup, svi_tract, by = c("tract" = "tract")) %>%
#   group_by(zip) %>%
#   summarise(across(.cols = svi_socioeconomic_pctile:svi_pctile, 
#                    .fns = ~weighted.mean(., res_ratio, na.rm = TRUE), 
#                    .names = "{.col}_zcta")) %>%
#   mutate(across(.cols = everything(), .fns = ~ifelse(is.nan(.), NA, .)))
# 
