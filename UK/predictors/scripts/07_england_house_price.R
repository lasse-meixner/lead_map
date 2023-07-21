# Draft processing of ONS Median House Price data for LSOAs and MSOAs
# Note, you can also get the mean house price in each year
# Take the mean since records began since hopefully that better reflects the underlying qualities of the house
# (see notes in area_level_predictor_pairs_us_uk spreadsheet about this)

library(tidyverse)
library(readxl)

# TAKE YEAR ENDING SEP 2021, YEAR ENDING DEC 1995, AND FIVE YEARS TO 2001 

# LSOA

# house_prices_lsoa <- read_excel(url_ons_lsoa, sheet = "Data", skip = 5) %>%
#   rename("lsoa11cd" = "LSOA code") %>%
#   filter(substr(lsoa11cd, 1, 1) == "E") %>%
#   mutate(across("Year ending Dec 1995":"Year ending Sep 2021", as.numeric))
# 
# house_prices_lsoa$house_price_mean_median_1995to2000 <- rowMeans(house_prices_lsoa %>% select("Year ending Dec 1995":"Year ending Jun 2000"), 
#                                                                  na.rm = TRUE)
# house_prices_lsoa$house_price_mean_median_2017to2021 <- rowMeans(house_prices_lsoa %>% select("Year ending Mar 2017":"Year ending Sep 2021"), 
#                                                                  na.rm = TRUE)

# house_prices_lsoa <- house_prices_lsoa %>%
#   rename("house_price_median_yrto_dec_95" = "Year ending Dec 1995",
#          "house_price_median_yrto_sep_21" = "Year ending Sep 2021") %>%
#   select(lsoa11cd, 
#          house_price_median_yrto_dec_95, house_price_median_yrto_sep_21,
#          house_price_mean_median_1995to2000, house_price_mean_median_2017to2021)


# MSOA

house_prices_msoa <- read_excel(paste0(drop_box_base_url, "median_house_price_ons_msoa.xls"), sheet = "1a", skip = 5) %>%
  rename("msoa11cd" = "MSOA code") %>%
  filter(substr(msoa11cd, 1, 1) == "E") %>%
  mutate(across("Year ending Dec 1995":"Year ending Sep 2021", as.numeric))

house_prices_msoa$house_price_mean_median_1995to2000 <- rowMeans(house_prices_msoa %>% select("Year ending Dec 1995":"Year ending Jun 2000"), 
                                                                 na.rm = TRUE)
house_prices_msoa$house_price_mean_median_2017to2021 <- rowMeans(house_prices_msoa %>% select("Year ending Mar 2017":"Year ending Sep 2021"), 
                                                                 na.rm = TRUE)

house_prices_msoa <- house_prices_msoa %>%
  rename("house_price_median_yrto_dec_95" = "Year ending Dec 1995",
         "house_price_median_yrto_sep_21" = "Year ending Sep 2021") %>%
  select(msoa11cd, 
         house_price_median_yrto_dec_95, house_price_median_yrto_sep_21,
         house_price_mean_median_1995to2000, house_price_mean_median_2017to2021)

house_prices_msoa %>%
  write_csv("data_processed/house_prices_msoa.csv")


# Done
