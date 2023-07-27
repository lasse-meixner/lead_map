library(readxl)
library(tidyverse)
library(dplyr)

tryCatch(setwd(dir = "../../raw_files/"),
         error = function(e) 1)
         
ny_path <- 'BLL_NY_Raw.xlsx'

# if drop_get_from_root function is in env, continue, otherwise source "00_drop_box_access.R"
if (exists("drop_get_from_root")) {
    drop_get_from_root(ny_path)
} else {
    source("../scripts/00_drop_box_access.R")
    drop_get_from_root(ny_path)
}


ny <- read_excel(ny_path) %>%
  rename(BLL_geq_5 = `Children tested => 5 mg/dL`,
         tested = `All Unique Children Tested (up to 72 months of age)`,
         year=Year,
         zip=Zip) %>% 
  mutate(state='NY') %>% 
  select(-`County Code`, -`County`) %>% 
  mutate(year=factor(year)) %>% 
  relocate(state) %>% 
  mutate(tested=ifelse(tested=='*',"<5",tested)) %>% 
  mutate(BLL_geq_5=ifelse(BLL_geq_5=='*',"<5",BLL_geq_5)) %>% 
  mutate(zip=as.character(zip))

# save to csv
write_csv(ny, "../processed_files/ny.csv")