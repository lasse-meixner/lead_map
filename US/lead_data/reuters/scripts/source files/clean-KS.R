library(tidyverse)
library(readxl)
# library(xlsx)

setwd(dir = "/Users/peter/Documents/Oxford/Frank RA/Lead Project/Raw Files")
ks_path <- 'BLL_KS_Raw.xlsx'

ks <- read_excel(ks_path,skip=2) %>% 
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
  mutate(state='KS') %>% 
  relocate(state)

## assuming that every year is the same as the average of the years.
ks2005 <- ks %>% mutate(year=2005)
ks2006 <- ks %>% mutate(year=2006)
ks2007 <- ks %>% mutate(year=2007)
ks2008 <- ks %>% mutate(year=2008)
ks2009 <- ks %>% mutate(year=2009)
ks2010 <- ks %>% mutate(year=2010)
ks2011 <- ks %>% mutate(year=2011)
ks2012 <- ks %>% mutate(year=2012)


## merging all the replicated years into one larger file
ks <- rbind(ks2005,ks2006,ks2007,ks2008,ks2009,ks2010,ks2011,ks2012) %>% 
  mutate(year=factor(year))