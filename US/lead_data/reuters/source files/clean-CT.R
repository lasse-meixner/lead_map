library(readxl)
library(tidyverse)

setwd(dir = "/Users/peter/Documents/Oxford/Frank RA/Lead Project/Raw Files")
ct_path <- 'BLL_CT_Raw.xlsx'

ct <- read_excel(ct_path) %>% 
  pivot_longer(cols=!`Zip_Code`,
               names_sep = -4,
               names_to = c('measure','year')) %>% 
  pivot_wider(names_from=measure,values_from=value) %>% 
  rename(BLL_geq_5=VGT5_,
         zip=Zip_Code) %>% 
  mutate(state="CT",
         year=factor(year))

         