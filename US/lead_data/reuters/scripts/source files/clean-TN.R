library(tidyverse)
library(readxl)
# library(xlsx)
tryCatch(setwd(dir = "../../raw_files/"),
         error = function(e) 1)

tn_path <- 'BLL_TN_Raw.xlsx'

# if drop_get_from_root function is in env, continue, otherwise source "00_drop_box_access.R"
if (exists("drop_get_from_root")) {
    drop_get_from_root(tn_path)
} else {
    source("../scripts/00_drop_box_access.R")
    drop_get_from_root(tn_path)
}


tn <- read_excel(tn_path,skip=2) %>% 
  select(1:4) %>% 
  ## use absolute renaming since the characters not recognisable easily 
  rename(zip=`Zip Code`,
         BLL_geq_5=2,
         BLL_geq_10=3,
         tested=4) %>% 
  filter(zip!="Missing",
         zip!="Total") %>% 
  mutate(tested=replace(tested, tested == "(b)(6)", "<5"))%>%
  mutate(BLL_geq_5=replace(BLL_geq_5, BLL_geq_5 == "(b)(6)", "<5"))%>%
  mutate(BLL_geq_10=replace(BLL_geq_10, BLL_geq_10 == "(b)(6)", "<5")) %>% 
  mutate(state='TN') %>% 
  relocate(state)

# TODO: Check this!
## assumes each year is the same as the average blocks
tn2005 <- tn %>% mutate(year=2005)
tn2006 <- tn %>% mutate(year=2006)
tn2007 <- tn %>% mutate(year=2007)

tn2010 <- tn %>% mutate(year=2010)
tn2011 <- tn %>% mutate(year=2011)
tn2012 <- tn %>% mutate(year=2012)
tn2013 <- tn %>% mutate(year=2013)
tn2014 <- tn %>% mutate(year=2014)
tn2015 <- tn %>% mutate(year=2015)

tn <- rbind(tn2005,tn2006,tn2007,tn2010,tn2011,tn2012,tn2013,tn2014,tn2015) %>% 
  mutate(year=factor(year))


# remove unnecessary variables
rm(tn2005,tn2006,tn2007,tn2010,tn2011,tn2012,tn2013,tn2014,tn2015)

# save to csv
write_csv(tn, file = "../../processed_files/tn.csv")