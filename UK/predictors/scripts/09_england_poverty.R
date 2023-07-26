# Processing of ONS Poverty Estimates for MSOAs
# (Only available for MSOAs, not for LSOAs)

library(tidyverse)
library(readxl)

poverty_ons_msoa <- read_excel("https://www.ons.gov.uk/file?uri=%2fpeoplepopulationandcommunity%2fpersonalandhouseholdfinances%2fincomeandwealth%2fdatasets%2fhouseholdsinpovertyestimatesformiddlelayersuperoutputareasinenglandandwales%2fcurrent/householdsinpovertyfye14.xls",
                               sheet = "Households in poverty AHC",
                               skip = 4) %>%
  rename("msoa11cd" = "MSOA code",
         "poverty_rateE" = 7,
         "poverty_rateE_lower_bound" = 8,
         "poverty_rateE_upper_bound" = 9) %>%
  select(msoa11cd, poverty_rateE, poverty_rateE_lower_bound, poverty_rateE_upper_bound) %>%
  filter(substr(msoa11cd, 1, 1) == "E")

poverty_ons_msoa %>%
  write_csv("data_processed/poverty_ons_msoa.csv")

rm(poverty_ons_msoa)


# Done