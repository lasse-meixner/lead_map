library(tidyverse)
library(readxl)
# library(xlsx)


         
co_path <- 'BLL_CO_Raw.xlsx'

# if drop_get_from_root function is in env, continue, otherwise source "00_drop_box_access.R"
if (!exists("drop_get_from_root")) {
    source("../00_drop_box_access.R")
}

drop_get_from_root(co_path)

co <- read_excel(co_path) %>% 
  rename(tract=FIPS,
         tested=N_children_tested,
         BLL_geq_5=N_EBLL5,
         BLL_geq_10=N_EBLL10) %>% 
  mutate(state="CO")

## assume Colorado aggregation is an average of these years and allocate 
## all evenly across years
#TODO: Check this!

co2010 <- co %>% mutate(year=2010)
co2011 <- co %>% mutate(year=2011)
co2012 <- co %>% mutate(year=2012)
co2013 <- co %>% mutate(year=2013)
co2014 <- co %>% mutate(year=2014)

co <- rbind(co2010,co2011,co2012,co2013,co2014) %>% 
  mutate(year=factor(year))

# remove unnecessary variables
rm(co2010,co2011,co2012,co2013,co2014)

# save to csv
write_csv(co, "../processed_files/co.csv")