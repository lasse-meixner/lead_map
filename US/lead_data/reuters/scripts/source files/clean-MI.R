library(readxl)
library(tidyverse)


         
mi_path <- 'BLL_MI_Raw.xlsx'

# if drop_get_from_root function is in env, continue, otherwise source "00_drop_box_access.R"
if (exists("drop_get_from_root")) {
    drop_get_from_root(mi_path)
} else {
    source("../00_drop_box_access.R")
    drop_get_from_root(mi_path)
}


mi <- read_excel(mi_path) %>% 
  pivot_longer(cols=starts_with("Num")) %>% 
  mutate(value=ifelse(value=="**",NA,value)) %>% 
  mutate(year=str_sub(name,start=-4)) %>% 
  mutate(name=str_sub(name,start=4,end=-5)) %>% 
  pivot_wider(names_from=name,values_from=value) %>% 
  rename(tested=Tested,
         BLL_geq_10=EBLL,
         zip=`Zip Code`) %>% 
  select(-County,-State) %>% 
  mutate(year=factor(year)) %>% 
  mutate(state='MI') %>% 
  relocate(state)
  
# save to csv
write_csv(mi, "../processed_files/mi.csv")