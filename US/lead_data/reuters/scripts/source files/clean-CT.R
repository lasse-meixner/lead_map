library(readxl)
library(tidyverse)

tryCatch(setwd(dir = "../../raw_files/"),
         error = function(e) 1)
         
ct_path <- 'BLL_CT_Raw.xlsx'

# if drop_get_from_root function is in env, continue, otherwise source "00_drop_box_access.R"
if (exists("drop_get_from_root")) {
    drop_get_from_root(ct_path)
} else {
    source("../scripts/00_drop_box_access.R")
    drop_get_from_root(ct_path)
}

ct <- read_excel(ct_path) %>% 
  pivot_longer(cols=!`Zip_Code`,
               names_sep = -4,
               names_to = c('measure','year')) %>% 
  pivot_wider(names_from=measure,values_from=value) %>% 
  rename(BLL_geq_5=VGT5_,
         zip=Zip_Code) %>% 
  mutate(state="CT",
         year=factor(year))

         
# save to csv
write_csv(ct, "../processed_files/ct.csv")