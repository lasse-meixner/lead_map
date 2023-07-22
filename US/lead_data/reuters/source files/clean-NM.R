library(tidyverse)
library(readxl)
# library(xlsx)
setwd(dir = "/Users/peter/Documents/Oxford/Frank RA/Lead Project/Raw Files")
nm_path <- 'BLL_NM_Raw.xlsx'

nmraw <- nm_path %>%
  excel_sheets() %>% # Read in the names of all sheets in the .xlsx file
  map_df(~ read_excel(path = nm_path, sheet ='totaltest',skip = 1))

nm <- nmraw %>% 
  pivot_longer(cols =! `Zipcode`,
               names_sep = " 2",
               names_to = c("type","year")) %>% 
  mutate(year=paste0("2",year)) %>% 
  pivot_wider(names_from = type,
              values_from = value) %>% 
  rename(zip=Zipcode,
         tested=Tests,
         BLL_geq_5=`Elevated Tests 5 mcg/dL -`,
         BLL_geq_10=`Elevated Tests 10 mcg/dL -`) %>% 
  mutate(year=factor(year)) %>% 
  mutate(state="NM") %>% 
  relocate(state)

