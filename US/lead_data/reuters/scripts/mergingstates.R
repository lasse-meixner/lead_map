## Merging dataframes
library(dplyr)
library(tidyverse)

## Run individual codes for each state
list.files("/Users/peter/OneDrive/Documents/GitHub/leadmap-public/reuters/source files",
           full.names = TRUE) %>% map(source)

## Adjust some states from fips codes to zip codes
setwd(dir = "/Users/peter/OneDrive/Documents/GitHub/leadmap-public/reuters")
source("tract-zip_code.R")

## additional changes to ensure a full join is possible.
## Make all values characters to have all dataframes able to be joined

al <- al %>% 
  mutate(BLL_geq_10=as.character(BLL_geq_10)) %>% 
  mutate(state="AZ")

il <- il %>% 
  mutate(BLL_geq_10=as.character(BLL_geq_10)) %>% 
  mutate(zip=as.character(zip)) %>% 
  mutate(tested=as.character(tested))

mi <- mi %>% 
  mutate(zip=as.character(zip)) %>% 
  mutate(tested=as.character(tested)) %>% 
  mutate(BLL_geq_10=as.character(BLL_geq_10)) %>% 
  mutate(state='MI')

oh_zip <- oh_zip %>% 
  mutate(tested=as.character(tested)) %>% 
  mutate(BLL_geq_10=as.character(BLL_geq_10)) %>% 
  mutate(BLL_geq_5=as.character(BLL_geq_5)) 

pa_zip <- pa_zip %>% 
  mutate(tested=as.character(tested)) %>% 
  mutate(BLL_geq_10=as.character(BLL_geq_10)) %>% 
  mutate(BLL_geq_5=as.character(BLL_geq_5)) 

md_zip <- md_zip %>% 
  mutate(tested=as.character(tested)) %>% 
  mutate(BLL_geq_10=as.character(BLL_geq_10)) %>% 
  mutate(BLL_geq_5=as.character(BLL_geq_5))

ma_zip <- ma_zip %>% 
  mutate(tested=as.character(tested)) %>% 
  mutate(BLL_geq_5=as.character(BLL_geq_5)) %>% 
  mutate(state='MA')

nc_zip <- nc_zip %>% 
  mutate(tested=as.character(tested)) %>% 
  mutate(BLL_geq_5=as.character(BLL_geq_5)) %>% 
  mutate(state='NC')

ga <- ga %>% 
  mutate(tested=as.character(tested)) %>% 
  mutate(BLL_geq_5=as.character(BLL_geq_5))

nm <- nm %>% 
  mutate(zip=as.character(zip)) %>% 
  mutate(tested=as.character(tested)) %>% 
  mutate(BLL_geq_10=as.character(BLL_geq_10)) %>% 
  mutate(BLL_geq_5=as.character(BLL_geq_5))

ind_zip <- ind_zip %>% 
  mutate(tested=as.character(tested)) %>% 
  mutate(BLL_geq_5=as.character(BLL_geq_5)) %>% 
  mutate(state='IN')

nyc_zip <- nyc_zip %>% 
  mutate(zip=as.character(zip)) %>% 
  mutate(tested=as.character(tested)) %>% 
  mutate(BLL_geq_10=as.character(BLL_geq_10)) %>% 
  mutate(BLL_geq_5=as.character(BLL_geq_5)) %>% 
  mutate(state='NYC')

or_zip <- or_zip %>% 
  mutate(tested=as.character(tested)) %>% 
  mutate(BLL_geq_5=as.character(BLL_geq_5)) %>% 
  mutate(state='OR')

mo <- mo %>% 
  mutate(tested=as.character(tested)) %>% 
  mutate(BLL_geq_5=as.character(BLL_geq_5)) %>% 
  mutate(BLL_geq_10=as.character(BLL_geq_10))

ok <- ok %>% 
  mutate(zip=as.character(zip))

mn_zip <- mn_zip %>% 
  mutate(state='MN') %>% 
  mutate(tested=as.character(tested)) %>% 
  mutate(BLL_geq_10=as.character(BLL_geq_10)) %>% 
  mutate(BLL_geq_5=as.character(BLL_geq_5))

az <- az %>% 
  mutate(tested=as.character(tested)) %>% 
  mutate(BLL_geq_10=as.character(BLL_geq_10)) %>% 
  mutate(BLL_geq_5=as.character(BLL_geq_5)) %>% 
  mutate(state="AZ")

tx <- tx %>% 
  mutate(tested=as.character(tested)) %>% 
  mutate(BLL_geq_10=as.character(BLL_geq_10)) %>% 
  mutate(BLL_geq_5=as.character(BLL_geq_5)) %>% 
  mutate(state="TX")

nh_zip <- nh_zip %>% 
  mutate(tested=as.character(tested)) %>% 
  mutate(BLL_geq_10=as.character(BLL_geq_10)) %>% 
  mutate(BLL_geq_5=as.character(BLL_geq_5)) %>% 
  mutate(state="NH")

co_zip <- co_zip %>% 
  mutate(tested=as.character(tested)) %>% 
  mutate(BLL_geq_10=as.character(BLL_geq_10)) %>% 
  mutate(BLL_geq_5=as.character(BLL_geq_5)) %>% 
  mutate(state="CO")

wi_zip <- wi_zip %>% 
  mutate(tested=as.character(tested)) %>% 
  mutate(BLL_geq_10=as.character(BLL_geq_10)) %>% 
  mutate(BLL_geq_5=as.character(BLL_geq_5)) %>% 
  mutate(state="WI")

## List of states to merge
prelim_list <- list(al,az,ri,ny,nyc_zip,il,la,oh_zip,pa_zip,nj,vt,md_zip,ca,mi,fl,
                    io,ma_zip,ct,nc_zip,sc,ga,dc,nm,ind_zip,or_zip,mo,ok,va,ks,mn_zip,tn,tx,nh_zip,co_zip,wi_zip)

## Merge and clean states
mergedstates <- prelim_list %>% 
  reduce(full_join) %>% 
  rename(zipcode=zip) %>% 
  select(-country)


## State totals merges
totals_list <- list(al_totals,ct_totals,mi_totals,mo_totals)

mergedtotals <- totals_list %>% 
  reduce(full_join)

