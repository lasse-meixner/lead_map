library(readxl)
library(tidyverse)


         
file_path <- 'BLL_IN_Raw.xlsx'
file_path2 <- 'INDIANA_COUNTY.xlsx'


if (exists("drop_get_from_root")) {
    drop_get_from_root(paste0("../../raw_data/", file_path))
    drop_get_from_root(paste0("../../raw_data/", file_path2))
} else {
    source("../00_drop_box_access.R")
    drop_get_from_root(paste0("../../raw_data/", file_path))
    drop_get_from_root(paste0("../../raw_data/", file_path2))
}

ind <- read_excel(paste0("../../raw_data/", file_path)) 

ind_county_codes <- read_excel(paste0("../../raw_data/", file_path2)) %>% 
  rename(County=NAME) %>% 
  select(County,GEOID)

## The tract codes were typically missing 0 at certain points. The character length finds which 
## adjustments are necessary.

## I line up the indiana county codes to the indiana county names from a state website. This allows
## us to attach county codes to the particular area codes and the state fips code

ind <- left_join(ind,ind_county_codes) %>% 
  mutate(tract=substring(Geog,14)) %>% 
  mutate(tract=str_remove_all(tract,"[.]")) %>% 
  mutate(n=nchar(tract)) %>% 
  mutate(tract=ifelse(n==3,paste0("0",paste0(tract,"00")),
                      ifelse(n==4,paste0(tract,"00"),
                             ifelse(n==5,paste0("0",tract),
                                    ifelse(n==2,paste0("00",paste0(tract,"00")),
                                           ifelse(n==1,paste0("000",paste0(tract,"00")),tract)))))) %>% 
  mutate(tract=paste0(GEOID,tract)) %>% 
  relocate(tract) %>% 
  select(-POP100,-Tests_Total,-Tests_Total_Elev,-Perc_Elev_Total,
         -Geog,-County,-GEOID,-n) %>% 
  pivot_longer(cols=!tract,
               names_sep = c(6,11),
               names_to = c("test","year","type")) %>% 
  select(-test) %>% 
  mutate(year=substring(year,1,4)) %>% 
  mutate(year=factor(year)) %>% 
  mutate(state = "IN") %>%
  mutate(measure=ifelse(type=="Elev","BLL_geq_5","tested")) %>% 
  select(-type) %>% 
  pivot_wider(names_from=measure,values_from=value)

# remove unnecessary variables
rm(ind_county_codes)

# save to csv
write_csv(ind, "../../processed_data/in.csv")