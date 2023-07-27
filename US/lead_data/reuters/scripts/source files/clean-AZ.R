library(tidyverse)
library(readxl)
# library(xlsx)

setwd(dir = "/Users/peter/Documents/Oxford/Frank RA/Lead Project/Raw Files")
az_path <- 'BLL_AZ_Raw.xlsx'

az <- read_excel(az_path, sheet ='ALL',skip=2) %>% 
  rename(value=`COUNT**`,
         year=`YEAR SAMPLE WAS TAKEN`,
         measure=`BLOOD LEAD LEVEL CATEGORY`) %>% 
  mutate(value=ifelse(value=="*",0,value)) %>% 
  filter(measure!="NA") %>% 
  pivot_wider(names_from=measure,
              values_from=value) %>% 
  select(-starts_with("*")) %>% 
  mutate(BLL_leq_5 = as.integer(`<5 µg/dL`)) %>% 
  mutate(BLL_geq_10 = as.integer(`10+ µg/dL`)) %>% 
  mutate(BLL_59=as.integer(`5-9 µg/dL`)) %>% 
  mutate(tested=BLL_leq_5+BLL_geq_10+BLL_59) %>% 
  mutate(BLL_geq_5 = BLL_59+BLL_geq_10) %>% 
  rename(zip=`ZIP CODE`) %>% 
  mutate(year=factor(year))
