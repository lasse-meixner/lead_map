library(tidyverse)
library(readxl)
# library(xlsx)

setwd(dir = "/Users/peter/Documents/Oxford/Frank RA/Lead Project/Raw Files")
va_path <- 'BLL_VA_Raw.xlsx'

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

