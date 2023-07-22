library(readxl)
library(tidyverse)

setwd(dir = "/Users/peter/Documents/Oxford/Frank RA/Lead Project/Raw Files")
fl_path <- 'BLL_FL_Raw.xlsx'

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



