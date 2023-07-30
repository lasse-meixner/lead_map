library(tidyverse)
library(readxl)

         
nm_path <- 'BLL_NM_Raw.xlsx'

# if drop_get_from_root function is in env, continue, otherwise source "00_drop_box_access.R"
if (exists("drop_get_from_root")) {
    drop_get_from_root(nm_path)
} else {
    source("../00_drop_box_access.R")
    drop_get_from_root(nm_path)
}

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

# remove unnecessary variables
rm(nmraw)

# save to csv
write_csv(nm, "../processed_files/nm.csv")