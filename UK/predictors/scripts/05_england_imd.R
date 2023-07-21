# IMD data processing 

library(tidyverse)

# Read in postcodes, super output areas, and local authority districts look-up file 
# We will need this to compute MSOA and LA IMD scores

lsoa_msoa_la_lookup_May_2020 <- drop_read_csv(paste0(drop_box_base_url, "geography_lookup_May_2020.csv")) %>%
  select(lsoa11cd, msoa11cd, ladcd) %>%
  distinct(lsoa11cd, .keep_all = TRUE) %>%
  rename("lad20cd" = "ladcd") %>%
  filter(substr(lad20cd, 1, 1) == "E")

# Read in the IMD data and join it to the look-up to include the MSOA and LA code for each LSOA

imd_with_all_area_codes <- read_csv("https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/845345/File_7_-_All_IoD2019_Scores__Ranks__Deciles_and_Population_Denominators_3.csv") %>%
  select("LSOA code (2011)",
         "LSOA name (2011)",
         "Index of Multiple Deprivation (IMD) Score", 
         "Income Score (rate)",
         "Employment Score (rate)",
         "Health Deprivation and Disability Score",
         "Barriers to Housing and Services Score",
         "Total population: mid 2015 (excluding prisoners)") %>%
  rename("lsoa11cd" = "LSOA code (2011)",
         "lsoa_name" ="LSOA name (2011)",
         "imd_overall_score_2015" = "Index of Multiple Deprivation (IMD) Score", 
         "imd_income_score_2015" = "Income Score (rate)",
         "imd_employment_score_2015" = "Employment Score (rate)",
         "imd_health_disability_score_2015" = "Health Deprivation and Disability Score",
         "imd_housing_services_score_2015" = "Barriers to Housing and Services Score",
         "total_ppl_est_2015" = "Total population: mid 2015 (excluding prisoners)") %>%
  left_join(lsoa_msoa_la_lookup_May_2020, .)

# AT THIS POINT WE CAN GET RID OF THE lsoa_msoa_la_lookup OBJECT
rm(lsoa_msoa_la_lookup_May_2020)

# Compute IMD scores for MSOAs and LAs as population-weighted averages of the LSOAs they contain
# Create three separate data frames of IMD scores, one each for LSOAs, MSOAs, and LAs
# Note, we want to retain the higher level area codes for each smaller area
# This is where the higher level area codes will comes from in each merged data frame for LSOAs and MSOAs

imd_msoa <- imd_with_all_area_codes  %>%
  group_by(msoa11cd) %>%
  summarize(imd_overall_score_2015 = weighted.mean(imd_overall_score_2015, total_ppl_est_2015),
            imd_income_score_2015 = weighted.mean(imd_income_score_2015, total_ppl_est_2015),
            imd_employment_score_2015 = weighted.mean(imd_employment_score_2015, total_ppl_est_2015), 
            imd_health_disability_score_2015 = weighted.mean(imd_health_disability_score_2015, total_ppl_est_2015), 
            imd_housing_services_score_2015 = weighted.mean(imd_housing_services_score_2015, total_ppl_est_2015),
            total_ppl_est_2015 = sum(total_ppl_est_2015),
            lad20cd = getmode(lad20cd)) %>%
  relocate(lad20cd, .after = msoa11cd)


imd_msoa %>%
  write_csv("data_processed/imd_msoa.csv")


# AT THIS POINT YOU CAN GET RID OF THE imd_with_all_area_codes OBJECT 
rm(imd_with_all_area_codes)

# Done
