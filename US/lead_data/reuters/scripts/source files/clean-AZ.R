library(tidyverse)
library(readxl)
# library(xlsx)


az_path <- '../../raw_files/BLL_AZ_Raw.xlsx'

# if drop_get_from_root function is in env, continue, otherwise source "00_drop_box_access.R"
if (exists("drop_get_from_root")) {
    drop_get_from_root(az_path)
} else {
    source("../scripts/00_drop_box_access.R")
    drop_get_from_root(az_path)
}

az <- read_excel(az_path, sheet ='ALL',skip=2) %>% 
  rename(value=`COUNT**`,
         year=`YEAR SAMPLE WAS TAKEN`,
         measure=`BLOOD LEAD LEVEL CATEGORY`) %>% 
  mutate(value=ifelse(value=="*",0,value)) %>% 
  filter(measure!="NA") %>% 
  pivot_wider(names_from=measure,
              values_from=value) %>% 
  select(-starts_with("*")) %>% 
  mutate(BLL_leq_5 = as.integer(`<5 µg/dL`)) %>% #TODO: This coerces suppressed "*" to NA
  mutate(BLL_geq_10 = as.integer(`10+ µg/dL`)) %>% 
  mutate(BLL_59=as.integer(`5-9 µg/dL`)) %>% 
  mutate(tested=BLL_leq_5+BLL_geq_10+BLL_59) %>% 
  mutate(BLL_geq_5 = BLL_59+BLL_geq_10) %>% 
  rename(zip=`ZIP CODE`,
         county = COUNTY) %>% 
  mutate(year=factor(year)) %>%

# save to csv
write_csv(az, "../../processed_files/az.csv")
