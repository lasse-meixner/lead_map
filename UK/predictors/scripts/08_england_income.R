# Processing of ONS Income Estimates for Small Areas for MSOAs
# (Only available for MSOAs, not for LSOAs)

library(tidyverse)

income_msoa <- read_csv("https://www.ons.gov.uk/file?uri=%2femploymentandlabourmarket%2fpeopleinwork%2fearningsandworkinghours%2fdatasets%2fsmallareaincomeestimatesformiddlelayersuperoutputareasenglandandwales%2ffinancialyearending2018/totalannualincome2018.csv")

income_msoa <- income_msoa[-c(1:4), ] %>%
  rename("msoa11cd" = 1,
         "median_annual_incomeE" = 7,
         "median_annual_incomeE_upper_bound" = 8,
         "median_annual_incomeE_lower_bound" = 9) %>%
  select(msoa11cd, median_annual_incomeE, median_annual_incomeE_upper_bound, median_annual_incomeE_lower_bound) %>%
  filter(substr(msoa11cd, 1, 1) == "E") %>%
  relocate(median_annual_incomeE_lower_bound, .before = median_annual_incomeE_upper_bound)

income_msoa %>%
  write_csv("../processed_data/income_msoa.csv")

# Done