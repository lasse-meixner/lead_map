library(readxl)
library(tidyverse)
library(dplyr)




sc_path <- '../../raw_files/BLL_SC_Raw.xlsx'

# if drop_get_from_root function is in env, continue, otherwise source "00_drop_box_access.R"
if (exists("drop_get_from_root")) {
    drop_get_from_root(sc_path)
} else {
    source("../scripts/00_drop_box_access.R")
    drop_get_from_root(sc_path)
}


# Read in all sheets and bind into a single tibble
# (based on <https://readxl.tidyverse.org/articles/readxl-workflows.html>)
sc <- sc_path %>%
  excel_sheets() %>% # Read in the names of all sheets in the .xlsx file
  set_names() %>% # First three lines in each sheet are garbage!
  map_df(~ read_excel(path = sc_path, sheet=.x, skip = 0), .id = 'sheet') %>% 
  filter(sheet!="Data Information") %>% 
  rename(year=sheet) %>% 
  select(-`SOUTH CAROLINA CHILDREN'S (<6 YEARS OF AGE) BLOOD LEAD DATA BY ZIP CODE, 2010 - 2015`) %>% 
  rename(zip=ZipCode,
         tested=3, ### need to use column order. name of the column cannot be recognised due to characters
         BLL_geq_5=4,
         BLL_geq_10=5) %>% 
  filter(zip!="UNKNOWN",
         zip!="SOUTH CAROLINA") %>% 
  mutate(year=factor(year)) %>% 
  mutate(state="SC")
  
# save to csv
write_csv(sc, file = "../../processed_files/sc.csv")