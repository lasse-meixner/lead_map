library(readxl)
library(tidyverse)
library(dplyr)

# try to setwd to the raw_files folder, if cannot change directory, assume already in raw_files folder
tryCatch(setwd(dir = "../../raw_files/"),
         error = function(e) 1)

al_path <- 'BLL_AL_Raw.xlsx'

# if drop_get_from_root function is in env, continue, otherwise source "00_drop_box_access.R"
if (exists("drop_get_from_root")) {
    drop_get_from_root(al_path)
} else {
    source("../scripts/00_drop_box_access.R")
    drop_get_from_root(al_path)
}

# Read in all sheets and bind into a single tibble
# (based on <https://readxl.tidyverse.org/articles/readxl-workflows.html>)

al <- al_path %>%
  excel_sheets() %>% # Read in the names of all sheets in the .xlsx file
  set_names() %>% # First three lines in each sheet are garbage!
  map_df(~ read_excel(path = al_path, sheet = .x, skip = 1), .id = 'sheet') %>%
  mutate(BLL_geq_5= `5 to 9` + `10 and greater`) %>% 
  select(-`5 to 9`) %>%
  unite(zip, Zip, `Zip Code`, na.rm = TRUE, remove = TRUE) %>%
  #TODO: filter for zip!="Total"?!
  rename(year = sheet,
         tested = Total,
         BLL_geq_10 = `10 and greater`) %>%
  mutate(state = 'AL') %>%
  relocate(state) %>%
  mutate(across(tested:BLL_geq_10, ~as.integer(.))) %>%
  mutate(year = factor(year)) %>% 
  mutate(tested=as.character(tested)) %>% 
  mutate(BLL_geq_5=as.character(BLL_geq_5))


# save to csv
write_csv(al, "../../processed_files/al.csv")