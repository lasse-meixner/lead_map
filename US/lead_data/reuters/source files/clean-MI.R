library(readxl)
library(tidyverse)

setwd(dir = "/Users/peter/Documents/Oxford/Frank RA/Lead Project/Raw Files")
mi_path <- 'BLL_MI_Raw.xlsx'


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
  