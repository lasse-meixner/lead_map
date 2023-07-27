library(tidyverse)
library(readxl)
# library(xlsx)

setwd(dir = "/Users/peter/Documents/Oxford/Frank RA/Lead Project/Raw Files")
mn_path <- 'BLL_MN_Raw.xlsx'

mn <- read_excel(mn_path) %>% 
  mutate(tested_2005_2010=ifelse(tested_2005_2010=='.',NA,tested_2005_2010)) %>% 
  mutate(tested_2011_2015=ifelse(tested_2011_2015=='.',NA,tested_2011_2015)) %>% 
  mutate(ebll5_2011_2015=ifelse(ebll5_2011_2015=='.',NA,ebll5_2011_2015)) %>% 
  mutate(ebll10_2005_2010=ifelse(ebll10_2005_2010=='.',NA,ebll10_2005_2010)) %>% 
  mutate(ebll10_2011_2015=ifelse(ebll10_2011_2015=='.',NA,ebll10_2011_2015)) 
  
mn2005to2010 <- mn %>% 
  select(tract_id,tested_2005_2010,ebll10_2005_2010) %>% 
  rename(tested=tested_2005_2010,
         BLL_geq_10=ebll10_2005_2010,
         tract=tract_id)

mn2011to2015 <- mn %>% 
  select(tract_id,tested_2011_2015,ebll5_2011_2015,ebll10_2011_2015) %>% 
  rename(tested=tested_2011_2015,
         BLL_geq_10=ebll10_2011_2015,
         BLL_geq_5=ebll5_2011_2015,
         tract=tract_id)

## Assume 2005 to 2010 average is the same every year.
## Assume 2011 to 2015 average is the same every year.

mn2005 <- mn2005to2010 %>% mutate(year=2005) %>% mutate(BLL_geq_5=NA)
mn2006 <- mn2005to2010 %>% mutate(year=2006) %>% mutate(BLL_geq_5=NA)
mn2007 <- mn2005to2010 %>% mutate(year=2007) %>% mutate(BLL_geq_5=NA)
mn2008 <- mn2005to2010 %>% mutate(year=2008) %>% mutate(BLL_geq_5=NA)
mn2009 <- mn2005to2010 %>% mutate(year=2009) %>% mutate(BLL_geq_5=NA)
mn2010 <- mn2005to2010 %>% mutate(year=2010) %>% mutate(BLL_geq_5=NA)

mn2011 <- mn2011to2015 %>% mutate(year=2011)
mn2012 <- mn2011to2015 %>% mutate(year=2012)
mn2013 <- mn2011to2015 %>% mutate(year=2013)
mn2014 <- mn2011to2015 %>% mutate(year=2014)
mn2015 <- mn2011to2015 %>% mutate(year=2015)

mn <- rbind(mn2005,mn2006,mn2007,mn2008,mn2009,mn2010,mn2011,mn2012,mn2013,mn2014,mn2015) %>% 
  mutate(year=factor(year)) %>% 
  mutate(state='MN') %>% 
  relocate(state)

