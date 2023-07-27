library(tidyverse)
library(readxl)
# library(xlsx)
setwd(dir = "/Users/peter/Documents/Oxford/Frank RA/Lead Project/Raw Files")
tn_path <- 'BLL_TN_Raw.xlsx'

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


