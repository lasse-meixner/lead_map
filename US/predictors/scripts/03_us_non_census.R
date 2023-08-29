# SVI 

#NOTE: see old file for legacy information on crosswalking to ZCTAs and ZIP crosswalking. 
library(googledrive)
library(tidyverse)


svi <- drive_get("Lead_Map_Project/US/raw_data/SVI_2010_US.csv") |> 
  drive_read_string() |> 
  read_csv()

svi <- svi |>
  rename("ST" = 1,
         "svi_socioeconomic_pctile" = "R_PL_THEME1",
         "svi_disability_pctile" = "R_PL_THEME2",
         "svi_minority_lang_pctile" = "R_PL_THEME3",
         "svi_housing_transprt_pctile" = "R_PL_THEME4",
         "svi_pctile" = "R_PL_THEMES",
         "tract" = "FIPS") |>
  select(c(ST:LOCATION, svi_socioeconomic_pctile, svi_disability_pctile, 
           svi_minority_lang_pctile, svi_housing_transprt_pctile, svi_pctile)) |>
  mutate(across(.cols = svi_socioeconomic_pctile:svi_pctile, .fns = ~ifelse(. == -999, NA, .)),
         tract = as.character(tract))

 # save to processed_data
svi |> 
  write_csv("../processed_data/svi.csv")