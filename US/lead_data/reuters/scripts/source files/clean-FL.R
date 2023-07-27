library(readxl)
library(tidyverse)

tryCatch(setwd(dir = "../../raw_files/"),
         error = function(e) 1)
         
fl_path <- 'BLL_FL_Raw.xlsx'

# if drop_get_from_root function is in env, continue, otherwise source "00_drop_box_access.R"
if (exists("drop_get_from_root")) {
    drop_get_from_root(fl_path)
} else {
    source("../scripts/00_drop_box_access.R")
    drop_get_from_root(fl_path)
}

fl <- read_excel(fl_path, skip = 1) %>% 
  pivot_longer(cols=!`Zip code`,
               names_sep = ' ',
               names_to = c('year','measure')) %>% 
  pivot_wider(names_from='measure',
              values_from='value') %>% 
  rename(zip=`Zip code`,
         tested=number,
         BLL_geq_10=`\r\ncases`) %>% 
  mutate(year=factor(year)) %>% 
  mutate(state='FL') %>% 
  relocate(state)


# save to csv
write_csv(fl, "../processed_files/fl.csv")