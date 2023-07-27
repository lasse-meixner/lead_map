library(readxl)
library(tidyverse)
library(dplyr)

setwd(dir = "/Users/peter/Documents/Oxford/Frank RA/Lead Project/Raw Files")
ny_path <- 'BLL_NY_Raw.xlsx'

ny <- read_excel(ny_path) %>%
  rename(BLL_geq_5 = `Children tested => 5 mg/dL`,
         tested = `All Unique Children Tested (up to 72 months of age)`,
         year=Year,
         zip=Zip) %>% 
  mutate(state='NY') %>% 
  select(-`County Code`, -`County`) %>% 
  mutate(year=factor(year)) %>% 
  relocate(state) %>% 
  mutate(tested=ifelse(tested=='*',"<5",tested)) %>% 
  mutate(BLL_geq_5=ifelse(BLL_geq_5=='*',"<5",BLL_geq_5)) %>% 
  mutate(zip=as.character(zip))
