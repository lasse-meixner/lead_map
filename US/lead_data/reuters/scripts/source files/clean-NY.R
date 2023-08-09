library(readxl)
library(tidyverse)
library(dplyr)


         
ny_path <- 'BLL_NY_Raw.xlsx'

# if drop_get_from_root function is in env, continue, otherwise source "00_drop_box_access.R"
if (!exists("drop_get_from_root")) {
    source("../00_drop_box_access.R")
}

drop_get_from_root(ny_path)


ny <- read_excel(ny_path) %>%
  rename(BLL_geq_5 = `Children tested => 5 mg/dL`,
         tested = `All Unique Children Tested (up to 72 months of age)`,
         year=Year,
         zip=Zip) %>% 
  mutate(state='NY') %>% 
  select(-`County Code`, -`County`) %>% 
  mutate(year=factor(year)) %>% 
  relocate(state) %>% 
  mutate(tested=ifelse(tested=='*',"<7",tested)) %>% # replace * with <7, as this appears to be the empirical cutoff
  mutate(BLL_geq_5=ifelse(BLL_geq_5 == '*', "<7", BLL_geq_5)) %>% 
  mutate(BLL_geq_5=ifelse(BLL_geq_5 == '.', NA, BLL_geq_5)) %>% # replace . with NA
  mutate(zip=as.character(zip))

# save to csv
write_csv(ny, "../processed_files/ny.csv")