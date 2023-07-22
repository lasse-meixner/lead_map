library(readxl)
library(tidyverse)
library(dplyr)

setwd(dir = "/Users/peter/Documents/Oxford/Frank RA/Lead Project/Raw Files")
il_path <- 'BLL_IL_Raw.xlsx'

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
