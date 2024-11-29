# The code in this script defines functions created for use in the downloading, cleaning, and merging of UK census data

library(naniar)
library(readr)
library(sf)
require(tidyverse)

# 2011 census data can be called at the level of OA, LSOA, MSOA
# 1991 census data can be called at the level of ED only, and will then be aggregated automatically to MSOA level in a custom fashion

# TODO: Also merge with feature geometry of the given geographical level (cf. US API call script)

get_census_data_england_2011 <- function(geography_type_code) {
  
  census_data_2011 <- 
    
    
    # Get ethnicity data. Percentages of persons White and Black
    nomis_get_data(id = "NM_608_1", time = "latest", rural_urban = 0, geography = geography_type_code, measures = 20301,
                   select = c("geography_code", "OBS_VALUE"), CELL = 100) %>%
    rename("white_ppl_prop" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_608_1", time = "latest", rural_urban = 0, geography = geography_type_code, measures = 20301,
                                select = c("geography_code", "OBS_VALUE"), CELL = 400)) %>%
    rename("black_ppl_prop" = "OBS_VALUE") %>%
    
    
    # Get tenure data. Percentages of persons (social and private) renters
    left_join(., nomis_get_data(id = "NM_535_1", time = "latest", rural_urban = 0, geography = geography_type_code, measures = 20301,
                                select = c("geography_code", "OBS_VALUE"), C_TENHUK11 = 5)) %>%
    rename("social_renter_ppl_prop" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_535_1", time = "latest", rural_urban = 0, geography = geography_type_code, measures = 20301,
                                select = c("geography_code", "OBS_VALUE"), C_TENHUK11 = 8)) %>%
    rename("private_renter_ppl_prop" = "OBS_VALUE") %>%
    mutate(renter_ppl_prop = social_renter_ppl_prop + private_renter_ppl_prop) %>%
    
    
    # Get total population
    left_join(., nomis_get_data(id = "NM_144_1", time = "latest", rural_urban = 0, geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), CELL = 0)) %>%
    rename("total_ppl_census" = "OBS_VALUE") %>%
    
    
    # Get number of families with dependent children with FRP in each FRP age band
    # And express as percentages of all families with dependent children
    # FRP age band count with one dependent child
    
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 1, C_DPCFAMUK11 = 2, C_FMTFAMUK11 = 0)) %>%
    rename("frp_u24_fam_w_kids_0_4_one" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 2, C_DPCFAMUK11 = 2, C_FMTFAMUK11 = 0)) %>%
    rename("frp_25_49_fam_w_kids_0_4_one" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 3, C_DPCFAMUK11 = 2, C_FMTFAMUK11 = 0)) %>%
    rename("frp_50_64_fam_w_kids_0_4_one" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 4, C_DPCFAMUK11 = 2, C_FMTFAMUK11 = 0)) %>%
    rename("frp_65_plus_fam_w_kids_0_4_one" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 1, C_DPCFAMUK11 = 3, C_FMTFAMUK11 = 0)) %>%
    rename("frp_u24_fam_w_kids_5_7_one" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 2, C_DPCFAMUK11 = 3, C_FMTFAMUK11 = 0)) %>%
    rename("frp_25_49_fam_w_kids_5_7_one" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 3, C_DPCFAMUK11 = 3, C_FMTFAMUK11 = 0)) %>%
    rename("frp_50_64_fam_w_kids_5_7_one" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 4, C_DPCFAMUK11 = 3, C_FMTFAMUK11 = 0)) %>%
    rename("frp_65_plus_fam_w_kids_5_7_one" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 1, C_DPCFAMUK11 = 4, C_FMTFAMUK11 = 0)) %>%
    rename("frp_u24_fam_w_kids_8_9_one" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 2, C_DPCFAMUK11 = 4, C_FMTFAMUK11 = 0)) %>%
    rename("frp_25_49_fam_w_kids_8_9_one" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 3, C_DPCFAMUK11 = 4, C_FMTFAMUK11 = 0)) %>%
    rename("frp_50_64_fam_w_kids_8_9_one" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 4, C_DPCFAMUK11 = 4, C_FMTFAMUK11 = 0)) %>%
    rename("frp_65_plus_fam_w_kids_8_9_one" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 1, C_DPCFAMUK11 = 5, C_FMTFAMUK11 = 0)) %>%
    rename("frp_u24_fam_w_kids_10_11_one" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 2, C_DPCFAMUK11 = 5, C_FMTFAMUK11 = 0)) %>%
    rename("frp_25_49_fam_w_kids_10_11_one" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 3, C_DPCFAMUK11 = 5, C_FMTFAMUK11 = 0)) %>%
    rename("frp_50_64_fam_w_kids_10_11_one" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 4, C_DPCFAMUK11 = 5, C_FMTFAMUK11 = 0)) %>%
    rename("frp_65_plus_fam_w_kids_10_11_one" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 1, C_DPCFAMUK11 = 6, C_FMTFAMUK11 = 0)) %>%
    rename("frp_u24_fam_w_kids_12_15_one" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 2, C_DPCFAMUK11 = 6, C_FMTFAMUK11 = 0)) %>%
    rename("frp_25_49_fam_w_kids_12_15_one" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 3, C_DPCFAMUK11 = 6, C_FMTFAMUK11 = 0)) %>%
    rename("frp_50_64_fam_w_kids_12_15_one" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 4, C_DPCFAMUK11 = 6, C_FMTFAMUK11 = 0)) %>%
    rename("frp_65_plus_fam_w_kids_12_15_one" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 1, C_DPCFAMUK11 = 7, C_FMTFAMUK11 = 0)) %>%
    rename("frp_u24_fam_w_kids_16_18_one" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 2, C_DPCFAMUK11 = 7, C_FMTFAMUK11 = 0)) %>%
    rename("frp_25_49_fam_w_kids_16_18_one" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 3, C_DPCFAMUK11 = 7, C_FMTFAMUK11 = 0)) %>%
    rename("frp_50_64_fam_w_kids_16_18_one" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 4, C_DPCFAMUK11 = 7, C_FMTFAMUK11 = 0)) %>%
    rename("frp_65_plus_fam_w_kids_16_18_one" = "OBS_VALUE") %>%
    
    # FRP age band count with two dependent children
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 1, C_DPCFAMUK11 = 8, C_FMTFAMUK11 = 0)) %>%
    rename("frp_u24_fam_w_kids_0_4_two" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 2, C_DPCFAMUK11 = 8, C_FMTFAMUK11 = 0)) %>%
    rename("frp_25_49_fam_w_kids_0_4_two" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 3, C_DPCFAMUK11 = 8, C_FMTFAMUK11 = 0)) %>%
    rename("frp_50_64_fam_w_kids_0_4_two" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 4, C_DPCFAMUK11 = 8, C_FMTFAMUK11 = 0)) %>%
    rename("frp_65_plus_fam_w_kids_0_4_two" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 1, C_DPCFAMUK11 = 9, C_FMTFAMUK11 = 0)) %>%
    rename("frp_u24_fam_w_kids_5_7_two" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 2, C_DPCFAMUK11 = 9, C_FMTFAMUK11 = 0)) %>%
    rename("frp_25_49_fam_w_kids_5_7_two" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 3, C_DPCFAMUK11 = 9, C_FMTFAMUK11 = 0)) %>%
    rename("frp_50_64_fam_w_kids_5_7_two" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 4, C_DPCFAMUK11 = 9, C_FMTFAMUK11 = 0)) %>%
    rename("frp_65_plus_fam_w_kids_5_7_two" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 1, C_DPCFAMUK11 = 10, C_FMTFAMUK11 = 0)) %>%
    rename("frp_u24_fam_w_kids_8_9_two" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 2, C_DPCFAMUK11 = 10, C_FMTFAMUK11 = 0)) %>%
    rename("frp_25_49_fam_w_kids_8_9_two" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 3, C_DPCFAMUK11 = 10, C_FMTFAMUK11 = 0)) %>%
    rename("frp_50_64_fam_w_kids_8_9_two" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 4, C_DPCFAMUK11 = 10, C_FMTFAMUK11 = 0)) %>%
    rename("frp_65_plus_fam_w_kids_8_9_two" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 1, C_DPCFAMUK11 = 11, C_FMTFAMUK11 = 0)) %>%
    rename("frp_u24_fam_w_kids_10_11_two" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 2, C_DPCFAMUK11 = 11, C_FMTFAMUK11 = 0)) %>%
    rename("frp_25_49_fam_w_kids_10_11_two" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 3, C_DPCFAMUK11 = 11, C_FMTFAMUK11 = 0)) %>%
    rename("frp_50_64_fam_w_kids_10_11_two" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 4, C_DPCFAMUK11 = 11, C_FMTFAMUK11 = 0)) %>%
    rename("frp_65_plus_fam_w_kids_10_11_two" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 1, C_DPCFAMUK11 = 12, C_FMTFAMUK11 = 0)) %>%
    rename("frp_u24_fam_w_kids_12_15_two" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 2, C_DPCFAMUK11 = 12, C_FMTFAMUK11 = 0)) %>%
    rename("frp_25_49_fam_w_kids_12_15_two" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 3, C_DPCFAMUK11 = 12, C_FMTFAMUK11 = 0)) %>%
    rename("frp_50_64_fam_w_kids_12_15_two" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 4, C_DPCFAMUK11 = 12, C_FMTFAMUK11 = 0)) %>%
    rename("frp_65_plus_fam_w_kids_12_15_two" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 1, C_DPCFAMUK11 = 13, C_FMTFAMUK11 = 0)) %>%
    rename("frp_u24_fam_w_kids_16_18_two" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 2, C_DPCFAMUK11 = 13, C_FMTFAMUK11 = 0)) %>%
    rename("frp_25_49_fam_w_kids_16_18_two" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 3, C_DPCFAMUK11 = 13, C_FMTFAMUK11 = 0)) %>%
    rename("frp_50_64_fam_w_kids_16_18_two" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 4, C_DPCFAMUK11 = 13, C_FMTFAMUK11 = 0)) %>%
    rename("frp_65_plus_fam_w_kids_16_18_two" = "OBS_VALUE") %>%
    
    # FRP age band count with two dependent children
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 1, C_DPCFAMUK11 = 14, C_FMTFAMUK11 = 0)) %>%
    rename("frp_u24_fam_w_kids_0_4_geq_three" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 2, C_DPCFAMUK11 = 14, C_FMTFAMUK11 = 0)) %>%
    rename("frp_25_49_fam_w_kids_0_4_geq_three" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 3, C_DPCFAMUK11 = 14, C_FMTFAMUK11 = 0)) %>%
    rename("frp_50_64_fam_w_kids_0_4_geq_three" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 4, C_DPCFAMUK11 = 14, C_FMTFAMUK11 = 0)) %>%
    rename("frp_65_plus_fam_w_kids_0_4_geq_three" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 1, C_DPCFAMUK11 = 15, C_FMTFAMUK11 = 0)) %>%
    rename("frp_u24_fam_w_kids_5_7_geq_three" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 2, C_DPCFAMUK11 = 15, C_FMTFAMUK11 = 0)) %>%
    rename("frp_25_49_fam_w_kids_5_7_geq_three" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 3, C_DPCFAMUK11 = 15, C_FMTFAMUK11 = 0)) %>%
    rename("frp_50_64_fam_w_kids_5_7_geq_three" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 4, C_DPCFAMUK11 = 15, C_FMTFAMUK11 = 0)) %>%
    rename("frp_65_plus_fam_w_kids_5_7_geq_three" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 1, C_DPCFAMUK11 = 16, C_FMTFAMUK11 = 0)) %>%
    rename("frp_u24_fam_w_kids_8_9_geq_three" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 2, C_DPCFAMUK11 = 16, C_FMTFAMUK11 = 0)) %>%
    rename("frp_25_49_fam_w_kids_8_9_geq_three" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 3, C_DPCFAMUK11 = 16, C_FMTFAMUK11 = 0)) %>%
    rename("frp_50_64_fam_w_kids_8_9_geq_three" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 4, C_DPCFAMUK11 = 16, C_FMTFAMUK11 = 0)) %>%
    rename("frp_65_plus_fam_w_kids_8_9_geq_three" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 1, C_DPCFAMUK11 = 17, C_FMTFAMUK11 = 0)) %>%
    rename("frp_u24_fam_w_kids_10_11_geq_three" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 2, C_DPCFAMUK11 = 17, C_FMTFAMUK11 = 0)) %>%
    rename("frp_25_49_fam_w_kids_10_11_geq_three" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 3, C_DPCFAMUK11 = 17, C_FMTFAMUK11 = 0)) %>%
    rename("frp_50_64_fam_w_kids_10_11_geq_three" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 4, C_DPCFAMUK11 = 17, C_FMTFAMUK11 = 0)) %>%
    rename("frp_65_plus_fam_w_kids_10_11_geq_three" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 1, C_DPCFAMUK11 = 18, C_FMTFAMUK11 = 0)) %>%
    rename("frp_u24_fam_w_kids_12_15_geq_three" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 2, C_DPCFAMUK11 = 18, C_FMTFAMUK11 = 0)) %>%
    rename("frp_25_49_fam_w_kids_12_15_geq_three" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 3, C_DPCFAMUK11 = 18, C_FMTFAMUK11 = 0)) %>%
    rename("frp_50_64_fam_w_kids_12_15_geq_three" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 4, C_DPCFAMUK11 = 18, C_FMTFAMUK11 = 0)) %>%
    rename("frp_65_plus_fam_w_kids_12_15_geq_three" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 1, C_DPCFAMUK11 = 19, C_FMTFAMUK11 = 0)) %>%
    rename("frp_u24_fam_w_kids_16_18_geq_three" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 2, C_DPCFAMUK11 = 19, C_FMTFAMUK11 = 0)) %>%
    rename("frp_25_49_fam_w_kids_16_18_geq_three" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 3, C_DPCFAMUK11 = 19, C_FMTFAMUK11 = 0)) %>%
    rename("frp_50_64_fam_w_kids_16_18_geq_three" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 4, C_DPCFAMUK11 = 19, C_FMTFAMUK11 = 0)) %>%
    rename("frp_65_plus_fam_w_kids_16_18_geq_three" = "OBS_VALUE") %>% 
    
    
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 0, C_DPCFAMUK11 = 2, C_FMTFAMUK11 = 0)) %>%
    rename("total_fam_w_kids_0_4_one" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 0, C_DPCFAMUK11 = 3, C_FMTFAMUK11 = 0)) %>%
    rename("total_fam_w_kids_5_7_one" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 0, C_DPCFAMUK11 = 4, C_FMTFAMUK11 = 0)) %>%
    rename("total_fam_w_kids_8_9_one" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 0, C_DPCFAMUK11 = 5, C_FMTFAMUK11 = 0)) %>%
    rename("total_fam_w_kids_10_11_one" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 0, C_DPCFAMUK11 = 6, C_FMTFAMUK11 = 0)) %>%
    rename("total_fam_w_kids_12_15_one" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 0, C_DPCFAMUK11 = 7, C_FMTFAMUK11 = 0)) %>%
    rename("total_fam_w_kids_16_18_one" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 0, C_DPCFAMUK11 = 8, C_FMTFAMUK11 = 0)) %>%
    rename("total_fam_w_kids_0_4_two" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 0, C_DPCFAMUK11 = 9, C_FMTFAMUK11 = 0)) %>%
    rename("total_fam_w_kids_5_7_two" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 0, C_DPCFAMUK11 = 10, C_FMTFAMUK11 = 0)) %>%
    rename("total_fam_w_kids_8_9_two" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 0, C_DPCFAMUK11 = 11, C_FMTFAMUK11 = 0)) %>%
    rename("total_fam_w_kids_10_11_two" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 0, C_DPCFAMUK11 = 12, C_FMTFAMUK11 = 0)) %>%
    rename("total_fam_w_kids_12_15_two" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 0, C_DPCFAMUK11 = 13, C_FMTFAMUK11 = 0)) %>%
    rename("total_fam_w_kids_16_18_geq_three" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 0, C_DPCFAMUK11 = 14, C_FMTFAMUK11 = 0)) %>%
    rename("total_fam_w_kids_0_4_geq_three" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 0, C_DPCFAMUK11 = 15, C_FMTFAMUK11 = 0)) %>%
    rename("total_fam_w_kids_5_7_geq_three" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 0, C_DPCFAMUK11 = 16, C_FMTFAMUK11 = 0)) %>%
    rename("total_fam_w_kids_8_9_geq_three" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 0, C_DPCFAMUK11 = 17, C_FMTFAMUK11 = 0)) %>%
    rename("total_fam_w_kids_10_11_geq_three" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 0, C_DPCFAMUK11 = 18, C_FMTFAMUK11 = 0)) %>%
    rename("total_fam_w_kids_12_15_geq_three" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_854_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), AGE_FRPPUK11 = 0, C_DPCFAMUK11 = 19, C_FMTFAMUK11 = 0)) %>%
    rename("total_fam_w_kids_16_18_geq_three" = "OBS_VALUE") %>%
    mutate(across(.cols = frp_u24_fam_w_kids:frp_65_plus_fam_w_kids, .fns = ~. / total_fam_w_kids, .names = "{.col}_prop"),
           frp_u49_fam_w_kids_prop = frp_u24_fam_w_kids_prop + frp_25_49_fam_w_kids_prop,
           frp_50_plus_fam_w_kids_prop =  frp_50_64_fam_w_kids_prop + frp_65_plus_fam_w_kids_prop, 
           # Note, below we make an assumption about the mean age of FRPs under the age of 24 and over the age of 65 
           # We assume it's 24 and 65 respectively
           frp_fam_w_kids_mean_age = (frp_u24_fam_w_kids_prop * 21) + (frp_25_49_fam_w_kids_prop * mean(25, 49)) +
             (frp_50_64_fam_w_kids_prop * mean(50, 64)) + (frp_65_plus_fam_w_kids_prop * 65)) %>%
    
    
    # Get proportion of 16-24 year old male / female persons who are married or in civil partnerships
    # Male
    left_join(., nomis_get_data(id = "NM_847_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_AGE = 1, C_SEX = 1, C_MARSTAT = 2)) %>%
    rename("married_16to24_male_ppl" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_847_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_AGE = 1, C_SEX = 1, C_MARSTAT = 3)) %>%
    rename("cp_16to24_male_ppl" = "OBS_VALUE") %>% 
    # Female
    left_join(., nomis_get_data(id = "NM_847_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_AGE = 1, C_SEX = 2, C_MARSTAT = 2)) %>%
    rename("married_16to24_female_ppl" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_847_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_AGE = 1, C_SEX = 2, C_MARSTAT = 3)) %>%
    rename("cp_16to24_female_ppl" = "OBS_VALUE") %>% 
    # Both
    left_join(., nomis_get_data(id = "NM_847_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_AGE = 1, C_SEX = 0, C_MARSTAT = 2)) %>%
    rename("married_16to24_ppl" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_847_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_AGE = 1, C_SEX = 0, C_MARSTAT = 3)) %>%
    rename("cp_16to24_ppl" = "OBS_VALUE") %>% 
    # Denominators
    left_join(., nomis_get_data(id = "NM_847_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_AGE = 1, C_SEX = 1, C_MARSTAT = 0)) %>%
    rename("total_16to24_male_ppl" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_847_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_AGE = 1, C_SEX = 2, C_MARSTAT = 0)) %>%
    rename("total_16to24_female_ppl" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_847_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_AGE = 1, C_SEX = 0, C_MARSTAT = 0)) %>%
    rename("total_16to24_ppl" = "OBS_VALUE") %>% 
    mutate(married_cp_16to24_male_ppl = married_16to24_male_ppl + cp_16to24_male_ppl,
           married_cp_16to24_female_ppl = married_16to24_female_ppl + cp_16to24_female_ppl,
           married_cp_16to24_ppl = married_16to24_ppl + cp_16to24_ppl,
           married_cp_16to24_male_ppl_prop = married_cp_16to24_male_ppl / total_16to24_male_ppl,
           married_cp_16to24_female_ppl_prop = married_cp_16to24_female_ppl / total_16to24_female_ppl,
           married_cp_16to24_ppl_prop = married_cp_16to24_ppl / total_16to24_ppl) %>%
    
    
    # Get number of persons with dependent children in each education band (sum of persons with 1 and 2+ dependent child in education band)
    # And express as percentages of all persons with dependent children (sum of persons with 1 and 2+ dependent child in all education bands)
    # One dependent child
    left_join(., nomis_get_data(id = "NM_1035_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_HLQPUK11 = 1, DPCFAMUK11_DPCEFAMUK11 = 1)) %>%
    rename("no_qual_ppl_w_1_kid" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1035_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_HLQPUK11 = 2, DPCFAMUK11_DPCEFAMUK11 = 1)) %>%
    rename("l1_qual_ppl_w_1_kid" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1035_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_HLQPUK11 = 3, DPCFAMUK11_DPCEFAMUK11 = 1)) %>%
    rename("l2_qual_ppl_w_1_kid" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1035_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_HLQPUK11 = 4, DPCFAMUK11_DPCEFAMUK11 = 1)) %>%
    rename("l3_qual_ppl_w_1_kid" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_1035_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_HLQPUK11 = 5, DPCFAMUK11_DPCEFAMUK11 = 1)) %>%
    rename("l4_qual_ppl_w_1_kid" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1035_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_HLQPUK11 = 6, DPCFAMUK11_DPCEFAMUK11 = 1)) %>%
    rename("appr_qual_ppl_w_1_kid" = "OBS_VALUE") %>%
    # Two or more dependent children
    left_join(., nomis_get_data(id = "NM_1035_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_HLQPUK11 = 1, DPCFAMUK11_DPCEFAMUK11 = 2)) %>%
    rename("no_qual_ppl_w_2plus_kids" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1035_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_HLQPUK11 = 2, DPCFAMUK11_DPCEFAMUK11 = 2)) %>%
    rename("l1_qual_ppl_w_2plus_kids" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1035_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_HLQPUK11 = 3, DPCFAMUK11_DPCEFAMUK11 = 2)) %>%
    rename("l2_qual_ppl_w_2plus_kids" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1035_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_HLQPUK11 = 4, DPCFAMUK11_DPCEFAMUK11 = 2)) %>%
    rename("l3_qual_ppl_w_2plus_kids" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_1035_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_HLQPUK11 = 5, DPCFAMUK11_DPCEFAMUK11 = 2)) %>%
    rename("l4_qual_ppl_w_2plus_kids" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1035_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_HLQPUK11 = 6, DPCFAMUK11_DPCEFAMUK11 = 2)) %>%
    rename("appr_qual_ppl_w_2plus_kids" = "OBS_VALUE") %>%
    # Totals of people with 1 and 2+ dependent children
    left_join(., nomis_get_data(id = "NM_1035_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_HLQPUK11 = 0, DPCFAMUK11_DPCEFAMUK11 = 1)) %>%
    rename("total_ppl_w_1_kid" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1035_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_HLQPUK11 = 0, DPCFAMUK11_DPCEFAMUK11 = 2)) %>%
    rename("total_ppl_w_2plus_kids" = "OBS_VALUE") %>%
    mutate(total_ppl_w_kids = total_ppl_w_1_kid + total_ppl_w_2plus_kids,
           no_qual_ppl_w_kids_prop = (no_qual_ppl_w_1_kid + no_qual_ppl_w_2plus_kids) / total_ppl_w_kids,
           l1_qual_ppl_w_kids_prop = (l1_qual_ppl_w_1_kid + l1_qual_ppl_w_2plus_kids) / total_ppl_w_kids,
           l2_qual_ppl_w_kids_prop = (l2_qual_ppl_w_1_kid + l2_qual_ppl_w_2plus_kids) / total_ppl_w_kids,
           l3_qual_ppl_w_kids_prop = (l3_qual_ppl_w_1_kid + l3_qual_ppl_w_2plus_kids) / total_ppl_w_kids,
           l4_qual_ppl_w_kids_prop = (l4_qual_ppl_w_1_kid + l4_qual_ppl_w_2plus_kids) / total_ppl_w_kids,
           appr_qual_ppl_w_kids_prop = (appr_qual_ppl_w_1_kid + appr_qual_ppl_w_2plus_kids) / total_ppl_w_kids,
           l3_or_appr_qual_ppl_w_kids_prop = l3_qual_ppl_w_kids_prop + appr_qual_ppl_w_kids_prop) %>%
    
    
    # Get number of male / female persons over age 16 in each education band
    # The benefit of this data relative to the above is that it is sex disaggregated
    # Male
    left_join(., nomis_get_data(id = "NM_1059_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_HLQPUK11 = 1, C_SEX = 1)) %>%
    rename("no_qual_16plus_male_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1059_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_HLQPUK11 = 2, C_SEX = 1)) %>%
    rename("l1_qual_16plus_male_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1059_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_HLQPUK11 = 3, C_SEX = 1)) %>%
    rename("l2_qual_16plus_male_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1059_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_HLQPUK11 = 4, C_SEX = 1)) %>%
    rename("l3_qual_16plus_male_ppl" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_1059_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_HLQPUK11 = 5, C_SEX = 1)) %>%
    rename("l4_qual_16plus_male_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1059_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_HLQPUK11 = 6, C_SEX = 1)) %>%
    rename("appr_qual_16plus_male_ppl" = "OBS_VALUE") %>%
    # Female
    left_join(., nomis_get_data(id = "NM_1059_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_HLQPUK11 = 1, C_SEX = 2)) %>%
    rename("no_qual_16plus_female_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1059_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_HLQPUK11 = 2, C_SEX = 2)) %>%
    rename("l1_qual_16plus_female_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1059_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_HLQPUK11 = 3, C_SEX = 2)) %>%
    rename("l2_qual_16plus_female_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1059_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_HLQPUK11 = 4, C_SEX = 2)) %>%
    rename("l3_qual_16plus_female_ppl" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_1059_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_HLQPUK11 = 5, C_SEX = 2)) %>%
    rename("l4_qual_16plus_female_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1059_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_HLQPUK11 = 6, C_SEX = 2)) %>%
    rename("appr_qual_16plus_female_ppl" = "OBS_VALUE") %>%
    # Both
    left_join(., nomis_get_data(id = "NM_1059_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_HLQPUK11 = 1, C_SEX = 0)) %>%
    rename("no_qual_16plus_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1059_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_HLQPUK11 = 2, C_SEX = 0)) %>%
    rename("l1_qual_16plus_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1059_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_HLQPUK11 = 3, C_SEX = 0)) %>%
    rename("l2_qual_16plus_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1059_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_HLQPUK11 = 4, C_SEX = 0)) %>%
    rename("l3_qual_16plus_ppl" = "OBS_VALUE") %>% 
    left_join(., nomis_get_data(id = "NM_1059_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_HLQPUK11 = 5, C_SEX = 0)) %>%
    rename("l4_qual_16plus_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1059_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_HLQPUK11 = 6, C_SEX = 0)) %>%
    rename("appr_qual_16plus_ppl" = "OBS_VALUE") %>%
    # Denominators
    left_join(., nomis_get_data(id = "NM_1059_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_HLQPUK11 = 0, C_SEX = 1)) %>%
    rename("total_16plus_male_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1059_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_HLQPUK11 = 0, C_SEX = 2)) %>%
    rename("total_16plus_female_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1059_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_HLQPUK11 = 0, C_SEX = 0)) %>%
    rename("total_16plus_ppl" = "OBS_VALUE") %>%
    mutate(across(.cols = no_qual_16plus_male_ppl:appr_qual_16plus_male_ppl, .fns = ~. / total_16plus_male_ppl,  .names = "{.col}_prop"),
           l3_or_appr_qual_16plus_male_ppl_prop = l3_qual_16plus_male_ppl_prop + appr_qual_16plus_male_ppl_prop,
           across(.cols = no_qual_16plus_female_ppl:appr_qual_16plus_female_ppl, .fns = ~. / total_16plus_female_ppl,  .names = "{.col}_prop"),
           l3_or_appr_qual_16plus_female_ppl_prop = l3_qual_16plus_female_ppl_prop + appr_qual_16plus_female_ppl_prop,
           across(.cols = no_qual_16plus_ppl:appr_qual_16plus_ppl, .fns = ~. / total_16plus_ppl,  .names = "{.col}_prop"),
           l3_or_appr_qual_16plus_ppl_prop = l3_qual_16plus_ppl_prop + appr_qual_16plus_ppl_prop) %>%
    
    
    # Get number of households who are one-family households with dependent children with each type of parental status
    # Note, the fact that we're using one-family households instead of all families in the numerator means we're missing some families
    # And express as percentages of all families with dependent children
    left_join(., nomis_get_data(id = "NM_605_1", time = "latest", rural_urban = 0, geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), CELL = 5)) %>%
    rename("married_fam_w_kids" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_605_1", time = "latest", rural_urban = 0, geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), CELL = 8)) %>%
    rename("cohabiting_fam_w_kids" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_605_1", time = "latest", rural_urban = 0, geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), CELL = 10)) %>%
    rename("lone_parent_fam_w_kids" = "OBS_VALUE") %>%
    mutate(across(.cols = married_fam_w_kids:lone_parent_fam_w_kids, .fns = ~. / total_fam_w_kids, .names = "{.col}_prop")) %>%
    
  
    # Get number of female lone parent households
    # And express as a proportion of all families with dependent children
    left_join(., nomis_get_data(id = "NM_607_1", time = "latest", rural_urban = 0, geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), CELL = 8)) %>%
    rename("female_lone_parent_hhd" = "OBS_VALUE") %>%
    mutate(female_lone_parent_fam_w_kids_prop = female_lone_parent_hhd / total_fam_w_kids) %>%
    
    
    # Get language data. Percentage of persons without English as their main language and who don't speak English well
    left_join(., nomis_get_data(id = "NM_526_1", time = "latest", rural_urban = 0, geography = geography_type_code, measures = 20301,
                                select = c("geography_code", "OBS_VALUE"), C_MAINLANGPRF11 = 4)) %>%
    rename("low_english_ppl_prop" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_526_1", time = "latest", rural_urban = 0, geography = geography_type_code, measures = 20301,
                                select = c("geography_code", "OBS_VALUE"), C_MAINLANGPRF11 = 5)) %>%
    rename("no_english_ppl_prop" = "OBS_VALUE") %>%
    mutate(low_or_no_english_ppl_prop = low_english_ppl_prop + no_english_ppl_prop) %>%
    
    
    # Get total number of dependent children
    # And divide by number of families with dependent children to get average number of dependent children in a family
    left_join(., nomis_get_data(id = "NM_518_1", time = "latest", rural_urban = 0, geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), CELL = 11)) %>%
    rename("total_kids" = "OBS_VALUE") %>%
    mutate(avg_siblings = total_kids / total_fam_w_kids) %>%
    
    
    # Get counts of children (all persons under 17) by sex and age
    # Boys
    left_join(., nomis_get_data(id = "NM_1414_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_AGE = 1, C_SEX = 1)) %>%
    rename("under_yo1_male_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1414_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_AGE = 2, C_SEX = 1)) %>%
    rename("yo1_male_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1414_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_AGE = 3, C_SEX = 1)) %>%
    rename("yo2_male_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1414_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_AGE = 4, C_SEX = 1)) %>%
    rename("yo3_male_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1414_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_AGE = 5, C_SEX = 1)) %>%
    rename("yo4_male_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1414_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_AGE = 6, C_SEX = 1)) %>%
    rename("yo5_male_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1414_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_AGE = 7, C_SEX = 1)) %>%
    rename("yo6_male_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1414_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_AGE = 8, C_SEX = 1)) %>%
    rename("yo7_male_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1414_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_AGE = 9, C_SEX = 1)) %>%
    rename("yo8_male_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1414_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_AGE = 10, C_SEX = 1)) %>%
    rename("yo9_male_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1414_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_AGE = 11, C_SEX = 1)) %>%
    rename("yo10_male_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1414_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_AGE = 12, C_SEX = 1)) %>%
    rename("yo11_male_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1414_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_AGE = 13, C_SEX = 1)) %>%
    rename("yo12_male_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1414_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_AGE = 14, C_SEX = 1)) %>%
    rename("yo13_male_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1414_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_AGE = 15, C_SEX = 1)) %>%
    rename("yo14_male_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1414_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_AGE = 16, C_SEX = 1)) %>%
    rename("yo15_male_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1414_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_AGE = 17, C_SEX = 1)) %>%
    rename("yo16_male_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1414_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_AGE = 18, C_SEX = 1)) %>%
    rename("yo17_male_ppl" = "OBS_VALUE") %>%
    # Girls
    left_join(., nomis_get_data(id = "NM_1414_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_AGE = 1, C_SEX = 2)) %>%
    rename("under_yo1_female_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1414_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_AGE = 2, C_SEX = 2)) %>%
    rename("yo1_female_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1414_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_AGE = 3, C_SEX = 2)) %>%
    rename("yo2_female_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1414_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_AGE = 4, C_SEX = 2)) %>%
    rename("yo3_female_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1414_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_AGE = 5, C_SEX = 2)) %>%
    rename("yo4_female_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1414_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_AGE = 6, C_SEX = 2)) %>%
    rename("yo5_female_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1414_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_AGE = 7, C_SEX = 2)) %>%
    rename("yo6_female_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1414_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_AGE = 8, C_SEX = 2)) %>%
    rename("yo7_female_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1414_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_AGE = 9, C_SEX = 2)) %>%
    rename("yo8_female_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1414_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_AGE = 10, C_SEX = 2)) %>%
    rename("yo9_female_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1414_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_AGE = 11, C_SEX = 2)) %>%
    rename("yo10_female_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1414_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_AGE = 12, C_SEX = 2)) %>%
    rename("yo11_female_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1414_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_AGE = 13, C_SEX = 2)) %>%
    rename("yo12_female_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1414_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_AGE = 14, C_SEX = 2)) %>%
    rename("yo13_female_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1414_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_AGE = 15, C_SEX = 2)) %>%
    rename("yo14_female_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1414_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_AGE = 16, C_SEX = 2)) %>%
    rename("yo15_female_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1414_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_AGE = 17, C_SEX = 2)) %>%
    rename("yo16_female_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_1414_1", time = "latest", geography = geography_type_code, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_AGE = 18, C_SEX = 2)) %>%
    rename("yo17_female_ppl" = "OBS_VALUE") %>%
    mutate(under_yo1_ppl = under_yo1_male_ppl + under_yo1_female_ppl,
           yo1_ppl = yo1_male_ppl + yo1_female_ppl, 
           yo2_ppl = yo2_male_ppl + yo2_female_ppl, 
           yo3_ppl = yo3_male_ppl + yo3_female_ppl, 
           yo4_ppl = yo4_male_ppl + yo4_female_ppl, 
           yo5_ppl = yo5_male_ppl + yo5_female_ppl, 
           yo6_ppl = yo6_male_ppl + yo6_female_ppl, 
           yo7_ppl = yo7_male_ppl + yo7_female_ppl, 
           yo8_ppl = yo8_male_ppl + yo8_female_ppl, 
           yo9_ppl = yo9_male_ppl + yo9_female_ppl, 
           yo10_ppl = yo10_male_ppl + yo10_female_ppl, 
           yo11_ppl = yo11_male_ppl + yo11_female_ppl, 
           yo12_ppl = yo12_male_ppl + yo12_female_ppl, 
           yo13_ppl = yo13_male_ppl + yo13_female_ppl, 
           yo14_ppl = yo14_male_ppl + yo14_female_ppl, 
           yo15_ppl = yo15_male_ppl + yo15_female_ppl, 
           yo16_ppl = yo16_male_ppl + yo16_female_ppl, 
           yo17_ppl = yo17_male_ppl + yo17_female_ppl, 
           male_ppl_u17 = rowSums(across(under_yo1_male_ppl:yo17_male_ppl)), 
           female_ppl_u17 = rowSums(across(under_yo1_female_ppl:yo17_female_ppl)), 
           total_ppl_u5 = rowSums(across(under_yo1_ppl:yo5_ppl)),
           total_ppl_u17 = male_ppl_u17 + female_ppl_u17,
           total_ppl_u5_totalpop_prop = total_ppl_u5 / total_ppl_census,
           male_u17_ppl_prop = male_ppl_u17 / total_ppl_u17,
           female_u17_ppl_prop = female_ppl_u17 / total_ppl_u17,
           across(.cols = under_yo1_ppl:yo17_ppl, .fns = ~. / total_ppl_u17, .names = "{.col}_u17_prop"),
           across(.cols = under_yo1_ppl:yo17_ppl, .fns = ~. / total_ppl_census, .names = "{.col}_totalpop_prop")) %>%
    
    
    # Get population industry data
    left_join(., nomis_get_data(id = "NM_560_1", time = "latest", geography = geography_type_code, rural_urban = 0, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_INDGEPUK11 = 2)) %>%
    rename("mining_employees" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_560_1", time = "latest", geography = geography_type_code, rural_urban = 0, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_INDGEPUK11 = 3)) %>%
    rename("manufacturing_employees" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_560_1", time = "latest", geography = geography_type_code, rural_urban = 0, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_INDGEPUK11 = 7)) %>%
    rename("chemical_manufacturing_employees" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_560_1", time = "latest", geography = geography_type_code, rural_urban = 0, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_INDGEPUK11 = 13)) %>%
    rename("construction_employees" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_560_1", time = "latest", geography = geography_type_code, rural_urban = 0, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_INDGEPUK11 = 0)) %>%
    rename("total_employees" = "OBS_VALUE") %>%
    mutate(across(.cols = mining_employees:construction_employees, .fns = ~. / total_employees, .names = "{.col}_prop")) %>%

    
    # Get population occupation data 
    left_join(., nomis_get_data(id = "NM_627_1", time = "latest", geography = geography_type_code, rural_urban = 0, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_SEX = 0, CELL = 8)) %>%
    rename("plant_and_machinery_employees" = "OBS_VALUE") %>%
    mutate(plant_and_machinery_employees_prop = plant_and_machinery_employees / total_employees) %>%
    
    
    # Get population economic activity data 
    left_join(., nomis_get_data(id = "NM_624_1", time = "latest", geography = geography_type_code, rural_urban = 0, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_SEX = 1, CELL = 100)) %>%
    rename("econ_active_16to74_male_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_624_1", time = "latest", geography = geography_type_code, rural_urban = 0, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_SEX = 1, CELL = 4)) %>%
    rename("unemployed_16to74_male_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_624_1", time = "latest", geography = geography_type_code, rural_urban = 0, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_SEX = 1, CELL = 300)) %>%
    rename("econ_inactive_16to74_male_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_624_1", time = "latest", geography = geography_type_code, rural_urban = 0, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_SEX = 1, CELL = 7)) %>%
    rename("student_ei_16to74_male_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_624_1", time = "latest", geography = geography_type_code, rural_urban = 0, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_SEX = 2, CELL = 100)) %>%
    rename("econ_active_16to74_female_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_624_1", time = "latest", geography = geography_type_code, rural_urban = 0, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_SEX = 2, CELL = 4)) %>%
    rename("unemployed_16to74_female_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_624_1", time = "latest", geography = geography_type_code, rural_urban = 0, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_SEX = 2, CELL = 300)) %>%
    rename("econ_inactive_16to74_female_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_624_1", time = "latest", geography = geography_type_code, rural_urban = 0, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_SEX = 2, CELL = 7)) %>%
    rename("student_ei_16to74_female_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_624_1", time = "latest", geography = geography_type_code, rural_urban = 0, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_SEX = 1, CELL = 0)) %>%
    rename("age_16to74_male_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_624_1", time = "latest", geography = geography_type_code, rural_urban = 0, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), C_SEX = 2, CELL = 0)) %>%
    rename("age_16to74_female_ppl" = "OBS_VALUE") %>%
    mutate(econ_active_16to74_ppl = econ_active_16to74_male_ppl + econ_active_16to74_female_ppl,
           unemployed_16to74_ppl = unemployed_16to74_male_ppl + unemployed_16to74_female_ppl,
           econ_inactive_16to74_ppl = econ_inactive_16to74_male_ppl + econ_inactive_16to74_female_ppl,
           student_ei_16to74_ppl = student_ei_16to74_male_ppl + student_ei_16to74_female_ppl,
           age_16to74_ppl = age_16to74_male_ppl + age_16to74_female_ppl,
           across(.cols = econ_active_16to74_male_ppl:student_ei_16to74_male_ppl, .fns = ~. / age_16to74_male_ppl, .names = "{.col}_prop"),
           across(.cols = econ_active_16to74_female_ppl:student_ei_16to74_female_ppl, .fns = ~. / age_16to74_female_ppl, .names = "{.col}_prop"),
           across(.cols = econ_active_16to74_ppl:student_ei_16to74_ppl, .fns = ~. / age_16to74_ppl, .names = "{.col}_prop")) %>%
    
    
    # Get population country of birth data 
    left_join(., nomis_get_data(id = "NM_611_1", time = "latest", geography = geography_type_code, rural_urban = 0, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), CELL = 100)) %>%
    rename("uk_born_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_611_1", time = "latest", geography = geography_type_code, rural_urban = 0, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), CELL = 1)) %>%
    rename("england_born_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_611_1", time = "latest", geography = geography_type_code, rural_urban = 0, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), CELL = 2)) %>%
    rename("ni_born_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_611_1", time = "latest", geography = geography_type_code, rural_urban = 0, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), CELL = 3)) %>%
    rename("scotland_born_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_611_1", time = "latest", geography = geography_type_code, rural_urban = 0, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), CELL = 4)) %>%
    rename("wales_born_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_611_1", time = "latest", geography = geography_type_code, rural_urban = 0, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), CELL = 5)) %>%
    rename("uk_oth_born_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_611_1", time = "latest", geography = geography_type_code, rural_urban = 0, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), CELL = 6)) %>%
    rename("ireland_born_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_611_1", time = "latest", geography = geography_type_code, rural_urban = 0, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), CELL = 200)) %>%
    rename("eu_oth_born_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_611_1", time = "latest", geography = geography_type_code, rural_urban = 0, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), CELL = 7)) %>%
    rename("eu_oth_2001_born_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_611_1", time = "latest", geography = geography_type_code, rural_urban = 0, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), CELL = 8)) %>%
    rename("eu_oth_2001to11_born_ppl" = "OBS_VALUE") %>%
    left_join(., nomis_get_data(id = "NM_611_1", time = "latest", geography = geography_type_code, rural_urban = 0, measures = 20100,
                                select = c("geography_code", "OBS_VALUE"), CELL = 9)) %>%
    rename("oth_born_ppl" = "OBS_VALUE") %>%
    mutate(across(.cols = uk_born_ppl:oth_born_ppl, .fns = ~. / total_ppl_census, .names = "{.col}_prop")) %>%
    
    
    filter(substr(GEOGRAPHY_CODE, 1, 1) == "E")
  
  # Add urban population
  
  if (geography_type_code == "TYPE299") {
    
    census_data_2011 <- left_join(census_data_2011, urban_ppl_oa, by = c("GEOGRAPHY_CODE" = "oa11cd")) %>%
      rename("oa11cd" = "GEOGRAPHY_CODE")
    
  }
  
  if (geography_type_code == "TYPE298") {
    
    census_data_2011 <- left_join(oa_lsoa_msoa_lookup_Dec_2011, urban_ppl_oa) %>%
      group_by(lsoa11cd) %>%
      summarise(urban_ppl = sum(urban_ppl)) %>%
      left_join(census_data_2011, ., by = c("GEOGRAPHY_CODE" = "lsoa11cd")) %>%
      rename("lsoa11cd" = "GEOGRAPHY_CODE")
    
  }
  
  if (geography_type_code == "TYPE297") {
    
    census_data_2011 <- left_join(oa_lsoa_msoa_lookup_Dec_2011, urban_ppl_oa) %>%
      group_by(msoa11cd) %>%
      summarise(urban_ppl = sum(urban_ppl)) %>%
      left_join(census_data_2011, ., by = c("GEOGRAPHY_CODE" = "msoa11cd")) %>%
      rename("msoa11cd" = "GEOGRAPHY_CODE")
    
  } 
  
  # Remaining mutating

    census_data_2011 <- census_data_2011 %>%
    mutate(urban_ppl_prop = urban_ppl / total_ppl_census,
           urban_majority = ifelse(urban_ppl_prop > 0.5, 1, 0),
           across(c(white_ppl_prop, black_ppl_prop,
                    social_renter_ppl_prop, private_renter_ppl_prop, renter_ppl_prop,
                    low_english_ppl_prop, no_english_ppl_prop, low_or_no_english_ppl_prop), 
                  ~./100)) %>%
      
    # Select out all computational variables, but re-add denominators at the end
    select(!c(total_ppl_census, 
              frp_u24_fam_w_kids:total_fam_w_kids,
              married_16to24_male_ppl:married_cp_16to24_ppl,
              no_qual_ppl_w_1_kid:total_ppl_w_kids, 
              no_qual_16plus_male_ppl:total_16plus_ppl,
              married_fam_w_kids:lone_parent_fam_w_kids, 
              female_lone_parent_hhd, 
              total_kids,
              under_yo1_male_ppl:total_ppl_u17,
              mining_employees:total_employees, 
              plant_and_machinery_employees,
              econ_active_16to74_male_ppl:age_16to74_ppl,
              uk_born_ppl:oth_born_ppl,
              urban_ppl),
           total_ppl_census, 
           total_fam_w_kids,
           total_16to24_male_ppl,
           total_16to24_female_ppl,
           total_16to24_ppl,
           total_ppl_w_kids,
           total_16plus_male_ppl,
           total_16plus_female_ppl,
           total_16plus_ppl,
           total_kids,
           total_ppl_u17,
           total_employees,
           age_16to74_male_ppl,
           age_16to74_female_ppl,
           age_16to74_ppl) %>%
      
      # Rename all columns except msoa11cd so that they have a "_2011" suffix
      rename_with(.fn = ~paste(., "_2011", sep = ""),
                  .cols = !msoa11cd)
}




get_census_data_england_1991 <- function() {
  
       # Set geography code for enumeration districts
       geography_type_code <- "TYPE7"

       census_data_1991_msoa <- 
       
       # Get ethnicity data. Percentages of persons White and Black
       nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                     select = c("geography_code", "OBS_VALUE"), CELL = 268828930) %>%
       rename("white_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268828931)) %>%
       rename("black_car_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268828932)) %>%
       rename("black_afr_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268828933)) %>%
       rename("black_oth_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268828929)) %>%
       rename("total_ppl_census" = "OBS_VALUE") %>%
       mutate(black_ppl = black_car_ppl + black_afr_ppl + black_oth_ppl) %>%
       
       
       # Get tenure data. Percentages of persons (social and private) renters
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 269746436)) %>%
       rename("private_renter_furnished_hhd" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 269746437)) %>%
       rename("private_renter_unfurnished_hhd" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 269746438)) %>%
       rename("renter_from_business_hhd" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 269746439)) %>%
       rename("renter_from_ha_hhd" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 269746440)) %>%
       rename("renter_from_la_hhd" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 269746433)) %>%
       rename("total_hhd" = "OBS_VALUE") %>%
       # NOTE, this is total households WITH RESIDENTS ALL PERMANENT. KEEP AN EYE ON THIS IN CASE YOU NEED TO USE 
       # A SIMILAR DENOMINATOR ELSEWHERE
       mutate(private_renter_hhd = private_renter_furnished_hhd + private_renter_unfurnished_hhd,
              social_renter_hhd = renter_from_ha_hhd + renter_from_la_hhd,
              renter_hhd = private_renter_hhd + social_renter_hhd + renter_from_business_hhd) %>%
       
       
       # Get number of household heads in each age band living in a household with children 0-15
       # And express as percentage of total number of households heads living in a household with children 0-15
       # (Requires, roughly, the assumption that every household head living in a household with children 0-15
       # is a parent and vice versa)
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 271909379)) %>%
       rename("age_16to24_kids_present_couple_hhd_head" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 271909632)) %>%
       rename("age_16to24_kids_present_noncouple_hhd_head" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 271909891)) %>%
       rename("age_25to34_kids_0to4_present_couple_hhd_head" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 271910144)) %>%
       rename("age_25to34_kids_0to4_present_noncouple_hhd_head" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 271910147)) %>%
       rename("age_25to34_kids_5to10_present_couple_hhd_head" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 271910400)) %>%
       rename("age_25to34_kids_5to10_present_noncouple_hhd_head" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 271910403)) %>%
       rename("age_25to34_kids_11to15_present_couple_hhd_head" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 271910656)) %>%
       rename("age_25to34_kids_11to15_present_noncouple_hhd_head" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 271910915)) %>%
       rename("age_35to54_kids_0to4_present_couple_hhd_head" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 271911168)) %>%
       rename("age_35to54_kids_0to4_present_noncouple_hhd_head" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 271911171)) %>%
       rename("age_35to54_kids_5to10_present_couple_hhd_head" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 271911424)) %>%
       rename("age_35to54_kids_5to10_present_noncouple_hhd_head" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 271911427)) %>%
       rename("age_35to54_kids_11to15_present_couple_hhd_head" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 271911680)) %>%
       rename("age_35to54_kids_11to15_present_noncouple_hhd_head" = "OBS_VALUE") %>%
       mutate(age_16to24_kids_present_hhd_head = age_16to24_kids_present_couple_hhd_head + age_16to24_kids_present_noncouple_hhd_head,
              age_25to34_kids_present_hhd_head = age_25to34_kids_0to4_present_couple_hhd_head + age_25to34_kids_0to4_present_noncouple_hhd_head +
              age_25to34_kids_5to10_present_couple_hhd_head + age_25to34_kids_5to10_present_noncouple_hhd_head +
              age_25to34_kids_11to15_present_couple_hhd_head + age_25to34_kids_11to15_present_noncouple_hhd_head, 
              age_35to54_kids_present_hhd_head = age_35to54_kids_0to4_present_couple_hhd_head + age_35to54_kids_0to4_present_noncouple_hhd_head +
              age_35to54_kids_5to10_present_couple_hhd_head + age_35to54_kids_5to10_present_noncouple_hhd_head +
              age_35to54_kids_11to15_present_couple_hhd_head + age_35to54_kids_11to15_present_noncouple_hhd_head, 
              age_16to54_kids_present_hhd_head = age_16to24_kids_present_hhd_head + age_25to34_kids_present_hhd_head + age_35to54_kids_present_hhd_head) %>%
       
       
       # Get number of(male/female) persons aged 16-24 who are married or single parents to a child aged 0-15 
       # and express as a percentage of the total number of (male/female) persons aged 16-24
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 270860547)) %>%
       rename("married_age_16to24_male_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 270860548)) %>%
       rename("married_age_16to24_female_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 270860549)) %>%
       rename("lone_parent_age_16to24_male_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 270860550)) %>%
       rename("lone_parent_age_16to24_female_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 270860545)) %>%
       rename("age_16to24_male_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 270860546)) %>%
       rename("age_16to24_female_ppl" = "OBS_VALUE") %>%
       mutate(married_age_16to24_ppl = married_age_16to24_male_ppl + married_age_16to24_female_ppl,
              lone_parent_age_16to24_ppl = lone_parent_age_16to24_male_ppl + lone_parent_age_16to24_female_ppl,
              age_16to24_ppl = age_16to24_male_ppl + age_16to24_female_ppl) %>%
       
       
       # Get number of persons aged 18 plus in each education band 
       # And express as percentages of all persons aged 18 plus
       # Note, this is a 10% sample table
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 273940994)) %>%
       rename("qualified_18_plus_male_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 273941248)) %>%
       rename("qualified_18_plus_female_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 273940993)) %>%
       rename("qualified_18_plus_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 273941250)) %>%
       rename("a_qualified_18_plus_male_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 273941504)) %>%
       rename("a_qualified_18_plus_female_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 273941249)) %>%
       rename("a_qualified_18_plus_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 273941506)) %>%
       rename("b_qualified_18_plus_male_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 273941760)) %>%
       rename("b_qualified_18_plus_female_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 273941505)) %>%
       rename("b_qualified_18_plus_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 273941762)) %>%
       rename("c_qualified_18_plus_male_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 273942016)) %>%
       rename("c_qualified_18_plus_female_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 273941761)) %>%
       rename("c_qualified_18_plus_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 273940738)) %>%
       rename("age_18_plus_male_ppl_s84" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 273940992)) %>%
       rename("age_18_plus_female_ppl_s84" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 273940737)) %>%
       rename("age_18_plus_ppl_s84" = "OBS_VALUE") %>%
       
       
       # Get number of families with each type of parental status from Table S89
       # And express as percentages of all families with dependent children
       # Note, this is a 10% sample table
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 274268930)) %>%
       rename("married_fam_w_kids" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 274268931)) %>%
       rename("cohabiting_fam_w_kids" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 274269184)) %>%
       rename("lone_parent_fam_w_kids" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 274268929)) %>%
       rename("total_fam_w_kids_s89" = "OBS_VALUE") %>%
       
       
       # Get number of female lone parent households (S40)
       # And express as a proportion of all households with dependent children (S31)
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 271057161)) %>%
       rename("female_lone_parent_hhd" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 271057153)) %>%
       rename("lone_parent_hhd" = "OBS_VALUE") %>%
       # S31
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 270467330)) %>%
       rename("total_hhd_w_kids" = "OBS_VALUE") %>%
       
       
       # Get total number of dependent children
       # And divide by number of households with dependent children to get average number of dependent children in a household with dependent children
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 270467338)) %>%
       rename("total_kids" = "OBS_VALUE") %>%

       
       # Get counts of children (all persons under 15) by sex and age
       # Boys
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 270926338)) %>%
       rename("under_yo1_male_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 270926594)) %>%
       rename("yo1_male_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 270926850)) %>%
       rename("yo2_male_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 270927106)) %>%
       rename("yo3_male_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 270927362)) %>%
       rename("yo4_male_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 270927618)) %>%
       rename("yo5_male_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 270927874)) %>%
       rename("yo6_male_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 270928130)) %>%
       rename("yo7_male_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 270928386)) %>%
       rename("yo8_male_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 270928642)) %>%
       rename("yo9_male_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 270928898)) %>%
       rename("yo10_male_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 270929154)) %>%
       rename("yo11_male_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 270929410)) %>%
       rename("yo12_male_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 270929666)) %>%
       rename("yo13_male_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 270929922)) %>%
       rename("yo14_male_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 270930178)) %>%
       rename("yo15_male_ppl" = "OBS_VALUE") %>%
       # Girls
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 270926592)) %>%
       rename("under_yo1_female_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 270926848)) %>%
       rename("yo1_female_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 270927104)) %>%
       rename("yo2_female_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 270927360)) %>%
       rename("yo3_female_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 270927616)) %>%
       rename("yo4_female_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 270927872)) %>%
       rename("yo5_female_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 270928128)) %>%
       rename("yo6_female_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 270928384)) %>%
       rename("yo7_female_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 270928640)) %>%
       rename("yo8_female_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 270928896)) %>%
       rename("yo9_female_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 270929152)) %>%
       rename("yo10_female_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 270929408)) %>%
       rename("yo11_female_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 270929664)) %>%
       rename("yo12_female_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 270929920)) %>%
       rename("yo13_female_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 270930176)) %>%
       rename("yo14_female_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 270930432)) %>%
       rename("yo15_female_ppl" = "OBS_VALUE") %>%
       mutate(under_yo1_ppl = under_yo1_male_ppl + under_yo1_female_ppl,
              yo1_ppl = yo1_male_ppl + yo1_female_ppl, 
              yo2_ppl = yo2_male_ppl + yo2_female_ppl, 
              yo3_ppl = yo3_male_ppl + yo3_female_ppl, 
              yo4_ppl = yo4_male_ppl + yo4_female_ppl, 
              yo5_ppl = yo5_male_ppl + yo5_female_ppl, 
              yo6_ppl = yo6_male_ppl + yo6_female_ppl, 
              yo7_ppl = yo7_male_ppl + yo7_female_ppl, 
              yo8_ppl = yo8_male_ppl + yo8_female_ppl, 
              yo9_ppl = yo9_male_ppl + yo9_female_ppl, 
              yo10_ppl = yo10_male_ppl + yo10_female_ppl, 
              yo11_ppl = yo11_male_ppl + yo11_female_ppl, 
              yo12_ppl = yo12_male_ppl + yo12_female_ppl, 
              yo13_ppl = yo13_male_ppl + yo13_female_ppl, 
              yo14_ppl = yo14_male_ppl + yo14_female_ppl, 
              yo15_ppl = yo15_male_ppl + yo15_female_ppl, 
              male_ppl_u15 = rowSums(across(under_yo1_male_ppl:yo15_male_ppl)), 
              female_ppl_u15 = rowSums(across(under_yo1_female_ppl:yo15_female_ppl)), 
              total_ppl_u15 = male_ppl_u15 + female_ppl_u15) %>%
       
       
       # Get population industry data
       # Note, this is a 10% sample table
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 273219844)) %>%
       rename("mining_employees" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 273219845)) %>%
       rename("manufacturing_metal_employees" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 273219846)) %>%
       rename("manufacturing_oth_employees" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 273219847)) %>%
       rename("construction_employees" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 273219841)) %>%
       rename("total_employees_s73" = "OBS_VALUE") %>%
       mutate(manufacturing_employees = manufacturing_metal_employees + manufacturing_oth_employees) %>%
       
       
       # GET OCCUPATION DATA
       # Note, this is a 10% sample table
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 273418497)) %>%
       rename("plant_and_machinery_employees" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 273418500)) %>%
       rename("mining_plant_and_machinery_employees" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 273418501)) %>%
       rename("manufacturing_metal_plant_and_machinery_employees" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 273418502)) %>%
       rename("manufacturing_oth_plant_and_machinery_employees" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 273418503)) %>%
       rename("construction_plant_and_machinery_employees" = "OBS_VALUE") %>%
       # SHOULD BE THE SAME AS THE total_employees variable above
       mutate(manufacturing_plant_and_machinery_employees = manufacturing_metal_plant_and_machinery_employees + 
              manufacturing_oth_plant_and_machinery_employees) %>%
       
       
       # Get economic activity data 
       # Note, there are other types of economic activity and inactivity available to disaggregate by too, you haven't used all of them 
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268960257)) %>%
       rename("econ_active_16_plus_male_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268961793)) %>%
       rename("unemployed_16_plus_male_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268962305)) %>%
       rename("econ_inactive_16_plus_male_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268962561)) %>%
       rename("student_ei_16_plus_male_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268963841)) %>%
       rename("econ_active_16_plus_female_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268965377)) %>%
       rename("unemployed_16_plus_female_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268965889)) %>%
       rename("econ_inactive_16_plus_female_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268966145)) %>%
       rename("student_ei_16_plus_female_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268960001)) %>%
       rename("age_16_plus_male_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268963585)) %>%
       rename("age_16_plus_female_ppl" = "OBS_VALUE") %>%
       mutate(econ_active_16_plus_ppl = econ_active_16_plus_male_ppl + econ_active_16_plus_female_ppl,
              unemployed_16_plus_ppl = unemployed_16_plus_male_ppl + unemployed_16_plus_female_ppl,
              econ_inactive_16_plus_ppl = econ_inactive_16_plus_male_ppl + econ_inactive_16_plus_female_ppl,
              student_ei_16_plus_ppl = student_ei_16_plus_male_ppl + student_ei_16_plus_female_ppl,
              age_16_plus_ppl = age_16_plus_male_ppl + age_16_plus_female_ppl) %>%
       
       
       # Get country of birth data 
       # Currently this includes EVERY country of birth column available
       # Males
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268894721)) %>%
       rename("uk_born_male_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268894977)) %>%
       rename("england_born_male_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268895233)) %>%
       rename("scotland_born_male_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268895489)) %>%
       rename("wales_born_male_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268895745)) %>%
       rename("ni_born_male_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268896001)) %>%
       rename("ireland_born_male_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268896257)) %>%
       rename("old_cmwlth_born_male_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268896513)) %>%
       rename("new_cmwlth_born_male_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268896769)) %>%
       rename("afr_east_born_male_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268897025)) %>%
       rename("afr_oth_born_male_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268897281)) %>%
       rename("carribean_born_male_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268897537)) %>%
       rename("bangladesh_born_male_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268897793)) %>%
       rename("india_born_male_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268898049)) %>%
       rename("pakistan_born_male_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268898305)) %>%
       rename("se_asia_born_male_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268898561)) %>%
       rename("cyprus_born_male_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268898817)) %>%
       rename("new_cmwlth_oth_born_male_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268899073)) %>%
       rename("ec_oth_born_male_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268899329)) %>%
       rename("europe_oth_born_male_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268899585)) %>%
       rename("china_born_male_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268899841)) %>%
       rename("oth_born_male_ppl" = "OBS_VALUE") %>%
       # Females
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268894976)) %>%
       rename("uk_born_female_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268895232)) %>%
       rename("england_born_female_ppl" = "OBS_VALUE") %>%
       
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268895488)) %>%
       rename("scotland_born_female_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268895744)) %>%
       rename("wales_born_female_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268896000)) %>%
       rename("ni_born_female_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268896256)) %>%
       rename("ireland_born_female_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268896512)) %>%
       rename("old_cmwlth_born_female_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268896768)) %>%
       rename("new_cmwlth_born_female_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268897024)) %>%
       rename("afr_east_born_female_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268897280)) %>%
       rename("afr_oth_born_female_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268897536)) %>%
       rename("carribean_born_female_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268897792)) %>%
       rename("bangladesh_born_female_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268898048)) %>%
       rename("india_born_female_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268898304)) %>%
       rename("pakistan_born_female_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268898560)) %>%
       rename("se_asia_born_female_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268898816)) %>%
       rename("cyprus_born_female_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268899072)) %>%
       rename("new_cmwlth_oth_born_female_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268899328)) %>%
       rename("ec_oth_born_female_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268899584)) %>%
       rename("europe_oth_born_female_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268899840)) %>%
       rename("china_born_female_ppl" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 268900096)) %>%
       rename("oth_born_female_ppl" = "OBS_VALUE") %>%
       mutate(uk_born_ppl = uk_born_male_ppl + uk_born_female_ppl,
              england_born_ppl = england_born_male_ppl + england_born_female_ppl,
              scotland_born_ppl = scotland_born_male_ppl + scotland_born_female_ppl,
              wales_born_ppl = wales_born_male_ppl + wales_born_female_ppl,
              ni_born_ppl = ni_born_male_ppl + ni_born_female_ppl,
              ireland_born_ppl = ireland_born_male_ppl + ireland_born_female_ppl,
              old_cmwlth_born_ppl = old_cmwlth_born_male_ppl + old_cmwlth_born_female_ppl,
              new_cmwlth_born_ppl = new_cmwlth_born_male_ppl + new_cmwlth_born_female_ppl,
              afr_east_born_ppl = afr_east_born_male_ppl + afr_east_born_female_ppl,
              afr_oth_born_ppl = afr_oth_born_male_ppl + afr_oth_born_female_ppl,
              carribean_born_ppl = carribean_born_male_ppl + carribean_born_female_ppl,
              bangladesh_born_ppl = bangladesh_born_male_ppl + bangladesh_born_female_ppl,
              india_born_ppl = india_born_male_ppl + india_born_female_ppl,
              pakistan_born_ppl = pakistan_born_male_ppl + pakistan_born_female_ppl,
              se_asia_born_ppl = se_asia_born_male_ppl + se_asia_born_female_ppl,
              cyprus_born_ppl = cyprus_born_male_ppl + cyprus_born_female_ppl,
              new_cmwlth_oth_born_ppl = new_cmwlth_oth_born_male_ppl + new_cmwlth_oth_born_female_ppl,
              ec_oth_born_ppl = ec_oth_born_male_ppl + ec_oth_born_female_ppl,
              europe_oth_born_ppl = europe_oth_born_male_ppl + europe_oth_born_female_ppl,
              china_born_ppl = china_born_male_ppl + china_born_female_ppl,
              oth_born_ppl = oth_born_male_ppl + oth_born_female_ppl) %>%
       
       
       # Get count of vacant household spaces and express as a percentage of total household spaces
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 271975937)) %>%
       rename("vacant_hhd_space" = "OBS_VALUE") %>%
       left_join(., nomis_get_data(id = "NM_38_1", time = "1991", geography = geography_type_code, measures = 20100,
                                   select = c("geography_code", "OBS_VALUE"), CELL = 271974657)) %>%
       rename("total_hhd_space" = "OBS_VALUE") %>%
       
       # Rename geo ID column
       rename("GEOGRAPHY_CODE_1991" = "GEOGRAPHY_CODE") %>%

       
       # Add short ED code
       left_join(., nomis_ed91code_lookup) %>%
       
       # Merge with the ED-MSOA lookup by the short ED code
       left_join(ed_msoa_lookup, .) %>%
       select(!c(ed91code_short, GEOGRAPHY_CODE_1991)) %>%
       
       # Now do the actual cross-walking

       group_by(msoa11cd) %>%
       summarise(across(.cols = white_ppl:total_hhd_space, 
                     .fns = ~sum(. * propotion_of_ed_in_msoa, na.rm = TRUE))) %>%
       filter(substr(msoa11cd, 1, 1) == "E") %>%
       
       # THE BIG MUTATION to get proportions
       
       mutate(white_ppl_prop = white_ppl / total_ppl_census,
              black_ppl_prop = black_ppl / total_ppl_census,
              
              # Tenure
              across(.cols = private_renter_hhd:renter_hhd, .fns = ~. / total_hhd, .names = "{.col}_prop"),
              
              # Age of household head
              across(.cols = age_16to24_kids_present_hhd_head:age_35to54_kids_present_hhd_head, 
                     .fns = ~. / age_16to54_kids_present_hhd_head, 
                     .names = "{.col}_16to54_prop"),
              age_16to54_kids_present_hhd_head_mean_age = (age_16to24_kids_present_hhd_head_16to54_prop * mean(16, 24)) +
              (age_25to34_kids_present_hhd_head_16to54_prop * mean(25, 34)) + (age_35to54_kids_present_hhd_head_16to54_prop * mean(35, 54)),
              
              # Young adults
              married_age_16to24_male_ppl_prop = married_age_16to24_male_ppl / age_16to24_male_ppl,
              married_age_16to24_female_ppl_prop = married_age_16to24_female_ppl / age_16to24_female_ppl,
              married_age_16to24_ppl_prop = married_age_16to24_ppl / age_16to24_ppl,
              lone_parent_age_16to24_male_ppl_prop = lone_parent_age_16to24_male_ppl / age_16to24_male_ppl,
              lone_parent_age_16to24_female_ppl_prop =  lone_parent_age_16to24_female_ppl / age_16to24_female_ppl,
              lone_parent_age_16to24_ppl_prop = lone_parent_age_16to24_ppl / age_16to24_ppl,
              
              # Parents' education
              across(.cols = contains("qualified_18_plus_male_ppl"), .fns = ~. / age_18_plus_male_ppl_s84, .names = "{.col}_prop"),
              across(.cols = contains("qualified_18_plus_female_ppl"), .fns = ~. / age_18_plus_female_ppl_s84, .names = "{.col}_prop"),
              across(.cols = contains("qualified_18_plus_ppl"), .fns = ~. / age_18_plus_ppl_s84, .names = "{.col}_prop"),
              
              # Family status (10% sample) 
              across(.cols = married_fam_w_kids:lone_parent_fam_w_kids, .fns = ~. / total_fam_w_kids_s89, .names = "{.col}_prop"),
              
              # Female lone parent households
              female_lone_parent_hhd_w_kids_prop = female_lone_parent_hhd / total_hhd_w_kids,
              lone_parent_hhd_w_kids_prop = lone_parent_hhd / total_hhd_w_kids,
              
              # Average siblings 
              avg_siblings = total_kids / total_hhd_w_kids,
              
              # Children by sex and age
              male_ppl_u15_prop = male_ppl_u15 / total_ppl_u15,
              female_ppl_u15_prop = female_ppl_u15 / total_ppl_u15,
              across(.cols = under_yo1_ppl:yo15_ppl, .fns = ~. / total_ppl_u15, .names = "{.col}_u15_prop"),
              
              # Industry (10% sample)
              across(.cols = c(mining_employees:construction_employees, manufacturing_employees), 
                     .fns = ~. / total_employees_s73, 
                     .names = "{.col}_prop"),
              
              # Occupation (10% sample)
              across(.cols = c(plant_and_machinery_employees:construction_plant_and_machinery_employees, manufacturing_plant_and_machinery_employees), 
                     .fns = ~. / total_employees_s73, 
                     .names = "{.col}_prop"),
              
              # Economic activity
              across(.cols = econ_active_16_plus_male_ppl:student_ei_16_plus_male_ppl, .fns = ~. / age_16_plus_male_ppl, .names = "{.col}_prop"),
              across(.cols = econ_active_16_plus_female_ppl:student_ei_16_plus_female_ppl, .fns = ~. / age_16_plus_female_ppl, .names = "{.col}_prop"),
              across(.cols = econ_active_16_plus_ppl:student_ei_16_plus_ppl, .fns = ~. / age_16_plus_ppl, .names = "{.col}_prop"),
              
              # Country of birth
              across(.cols = uk_born_ppl:oth_born_ppl, .fns = ~. / total_ppl_census, .names = "{.col}_prop"),
              
              # Occupancy
              vacant_hhd_space_prop = vacant_hhd_space / total_hhd_space) %>%
       
       
       # Select out count columns we don't want and re-add ones we do (denominators), at the end
       select(!c(white_ppl:total_hhd_space), 
              total_ppl_census,
              total_hhd,
              age_16to54_kids_present_hhd_head,
              age_16to24_male_ppl,
              age_16to24_female_ppl,
              age_16to24_ppl,
              age_18_plus_male_ppl_s84,
              age_18_plus_female_ppl_s84,
              age_18_plus_ppl_s84,
              total_fam_w_kids_s89,
              total_hhd_w_kids,
              total_kids,
              total_ppl_u15,
              total_employees_s73,
              age_16_plus_male_ppl,
              age_16_plus_female_ppl,
              age_16_plus_ppl,
              total_hhd_space) %>%
       
       # Rename all columns except msoa11cd so that they have a "_1991" suffix
       rename_with(.fn = ~paste(., "_1991", sep = ""),
                     .cols = !msoa11cd)
                     
}