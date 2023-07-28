library(tidyverse)
library(readxl)
# library(xlsx)

tryCatch(setwd(dir = "../../raw_files/"),
         error = function(e) 1)
         
va_path <- 'BLL_VA_Raw.xlsx'

# if drop_get_from_root function is in env, continue, otherwise source "00_drop_box_access.R"
if (exists("drop_get_from_root")) {
    drop_get_from_root(va_path)
} else {
    source("../scripts/00_drop_box_access.R")
    drop_get_from_root(va_path)
}

va <- read_excel(va_path,skip=2) %>% 
  select(1:4) %>% 
  rename(zip=`Zip Code`,
         BLL_geq_5=2, ## use column index here due to specific characters in titles
         BLL_geq_10=3,
         tested=4) %>% 
  filter(zip!='Total',
         zip!='Missing') %>% 
  mutate(tested=replace(tested, tested == "(b)(6)", "<5"))%>%
  mutate(BLL_geq_5=replace(BLL_geq_5, BLL_geq_5 == "(b)(6)", "<5"))%>%
  mutate(BLL_geq_10=replace(BLL_geq_10, BLL_geq_10 == "(b)(6)", "<5")) %>% 
  mutate(state='VA') %>% 
  relocate(state)

## assuming that every year is the same as the average of the years.
va2005 <- va %>% mutate(year=2005)
va2006 <- va %>% mutate(year=2006)
va2007 <- va %>% mutate(year=2007)
va2008 <- va %>% mutate(year=2008)
va2009 <- va %>% mutate(year=2009)
va2010 <- va %>% mutate(year=2010)
va2011 <- va %>% mutate(year=2011)

## merging all the replicated years into one larger file
va <- rbind(va2005,va2006,va2007,va2008,va2009,va2010,va2011) %>% 
  mutate(year=factor(year))


# remove unnecessary variables
rm(va2005,va2006,va2007,va2008,va2009,va2010,va2011)

# save to csv
write_csv(va, file = "../processed_files/va.csv")