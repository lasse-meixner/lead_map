library(tidyverse)
library(readxl)


         
md_path <- '../../raw_files/BLL_MD_Raw.xlsx'

# if drop_get_from_root function is in env, continue, otherwise source "00_drop_box_access.R"
if (exists("drop_get_from_root")) {
    drop_get_from_root(md_path)
} else {
    source("../scripts/00_drop_box_access.R")
    drop_get_from_root(md_path)
}

# Read in all sheets and bind into a single tibble
# (based on <https://readxl.tidyverse.org/articles/readxl-workflows.html>)
md <- md_path %>%
  excel_sheets() %>% # Read in the names of all sheets in the .xlsx file
  set_names() %>% # First three lines in each sheet are garbage!
  map_df(~ read_excel(path = md_path, sheet = .x, skip = 3), .id = 'sheet') %>%
  rename(year = sheet,
         county = County,
         tract = `Census Tract`,
         tested = Tested,
         BLL_geq_5 = 5, ## needed to use column point due to naming of characters not recognised
         BLL_geq_10 = 6) %>%
  filter(!is.na(tract) & !(tract %in% c('Total', 'Census Tract'))) %>%
  mutate(state = 'MD') %>%
  relocate(state) %>%
  fill(county) %>% # county only recorded when it changes: fill with prev. non-missing
  mutate(county = str_to_title(county)) %>% # Convert from all caps to "usual" caps
  mutate(across(tested:BLL_geq_10, ~as.integer(.))) %>%
  mutate(year = factor(year)) %>% 
  mutate(tract=str_remove(tract,"[.]")) %>% ## for some reason decimals were popping up
  mutate(n=nchar(tract)) %>% # filter for the right granularity of tracts (11 digits)
  filter(n==11) %>%
  select(-n)


# save to csv
write_csv(md, "../../processed_files/md.csv")