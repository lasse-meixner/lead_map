library(readxl)
library(tidyverse)
library(dplyr)

tryCatch(setwd(dir = "../../raw_files/"),
         error = function(e) 1)

il_path <- 'BLL_IL_Raw.xlsx'

# if drop_get_from_root function is in env, continue, otherwise source "00_drop_box_access.R"
if (exists("drop_get_from_root")) {
    drop_get_from_root(il_path)
} else {
    source("../scripts/00_drop_box_access.R")
    drop_get_from_root(il_path)
}

il <- read_excel(il_path) %>% 
  pivot_longer(Test2005:ebl2015) %>% 
  mutate(year=str_sub(name,start=-4)) %>% 
  mutate(state='IL') %>% 
  mutate(year=factor(year)) %>% 
  select(-County,-ZIPCode...1) %>%
  rename(zip=ZIPCode...24) %>% 
  mutate(type=str_sub(name,start=1,end=1)) %>% 
  mutate(type=ifelse(type=='T','tested','BLL_geq_10')) %>% 
  mutate(type=factor(type)) %>% 
  select(-name) %>% 
  pivot_wider(names_from=type,values_from = value) %>% 
  relocate(state)

# save to csv
write_csv(il, "../../processed_files/il.csv")