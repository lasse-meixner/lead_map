library(readxl)
library(tidyverse)

# This excel file has only a single sheet and is fairly clean, but it's in *wide*
# format, so we convert it to *long format* using tidyr. Here's a nice tutorial:
# <https://dcl-wrangle.stanford.edu/pivot-advanced.html>
# See also *R for Data Science* Chapter 12
tryCatch(setwd(dir = "../../raw_files/"),
         error = function(e) 1)
         
ri_path <- 'BLL_RI_Raw.xlsx'

# if drop_get_from_root function is in env, continue, otherwise source "00_drop_box_access.R"
if (exists("drop_get_from_root")) {
    drop_get_from_root(ri_path)
} else {
    source("../scripts/00_drop_box_access.R")
    drop_get_from_root(ri_path)
}


ri <- read_excel(ri_path, skip = 5) %>%
  filter(TownName != 'Totals') %>% # The last row gives column totals
  pivot_longer(cols = starts_with('Tested'),
               names_sep = ' ',
               names_to = c('measure', 'year')) %>%
  pivot_wider(names_from = 'measure',
              values_from = 'value') %>%
  rename(town = TownName,
         zip = Zip,
         tested = Tested,
         BLL_geq_5 = `Tested>=5`) %>%
  mutate(state = 'RI') %>%
  relocate(state) %>% 
  fill(zip,.direction = "up") %>% 
  select(-town) %>% 
  mutate(tested=as.character(tested)) %>% 
  mutate(BLL_geq_5=as.character(BLL_geq_5))
  
# save to csv
write_csv(ri, file = "../../processed_files/ri.csv")