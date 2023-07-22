library(tidyverse)
library(readxl)
# library(xlsx)

setwd(dir = "/Users/peter/Documents/Oxford/Frank RA/Lead Project/Raw Files")
co_path <- 'BLL_CO_Raw.xlsx'

co <- read_excel(co_path) %>% 
  rename(tract=FIPS,
         tested=N_children_tested,
         BLL_geq_5=N_EBLL5,
         BLL_geq_10=N_EBLL10) %>% 
  mutate(state="CO")

## assume Colorado aggregation is an average of these years and allocate 
## all evenly across years

co2010 <- co %>% mutate(year=2010)
co2011 <- co %>% mutate(year=2011)
co2012 <- co %>% mutate(year=2012)
co2013 <- co %>% mutate(year=2013)
co2014 <- co %>% mutate(year=2014)

co <- rbind(co2010,co2011,co2012,co2013,co2014) %>% 
  mutate(year=factor(year))


