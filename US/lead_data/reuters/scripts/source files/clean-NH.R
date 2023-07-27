library(tidyverse)
library(readxl)
library(zoo)
library(purrr)
library(xlsx)
library(openxlsx)
library(stringr)
library(naniar)

tryCatch(setwd(dir = "../../raw_files/"),
         error = function(e) 1)
         
nh_path <- 'BLL_NH_Raw.xlsx'
nh2_path <- 'BLL_NH2_Raw.xlsx'

# if drop_get_from_root function is in env, continue, otherwise source "00_drop_box_access.R"
if (exists("drop_get_from_root")) {
    drop_get_from_root(nc_path)
    drop_get_from_root(nc2_path)
} else {
    source("../scripts/00_drop_box_access.R")
    drop_get_from_root(nc_path)
    drop_get_from_root(nc2_path)
}

#TODO: Check all this
nh <- read.xlsx(nh_path,fillMergedCells = TRUE, colNames = FALSE,startRow=2)

nhtested <- read_excel(nh2_path,skip=1,na=".") %>% 
  select(-`Missing Census Tract`,-`Total Number of Tests`) %>% 
  pivot_longer(cols=!YEAR,names_to="tract",values_to = "value") %>% 
  mutate(tract = str_remove(tract,"Census Tract ")) %>% 
  mutate(tract = ifelse(grepl("\\.",tract)==TRUE,tract,paste0(tract,".00"))) %>% 
  mutate(tract = str_remove(tract,"\\.")) %>% 
  mutate(n = nchar(tract)) %>% 
  mutate(tract = ifelse(n==6,tract,
                        ifelse(n==5,paste0("0",tract),
                               ifelse(n==4,paste0("00",tract),
                                      ifelse(n==3,paste0("000",tract),tract))))) %>% 
  rename(year=YEAR,
         tested=value) %>% 
  select(-n)

countyindex <- read_excel('NH_COUNTY.XLSX') %>% 
  mutate(tract = str_sub(GEOID,-6,-1)) %>% 
  mutate(fips = str_sub(GEOID,3,5)) %>% 
  select(GEOID,tract,fips)

## merging two titles per column into one column name
new_names <- paste(as.character(nh[1,]), as.character(nh[2,]),sep="_")

names(nh) <- new_names          # assign the new column names

#removing now defunct rows
nh <- nh %>% 
  slice(-1,-2,-3)

# clean BLL data
nh <- nh %>% 
  pivot_longer(cols=!1,names_to = c("tract","measure"),names_sep = "_") %>% 
  rename(year=NA_NA) %>% 
  filter(tract!="Missing Census Tract") %>% 
  mutate(tract = str_remove(tract,"Census Tract ")) %>% 
  mutate(tract = ifelse(grepl("\\.",tract)==TRUE,tract,paste0(tract,".00"))) %>% 
  mutate(tract = str_remove(tract,"\\.")) %>% 
  mutate(n = nchar(tract)) %>% 
  mutate(tract = ifelse(n==6,tract,
                        ifelse(n==5,paste0("0",tract),
                               ifelse(n==4,paste0("00",tract),
                                      ifelse(n==3,paste0("000",tract),tract)))))

#join BLL with testing data  
nh <- full_join(nhtested,nh,by=c("tract","year"))

# join all state BLL and testing data with state codes to assist with tract matching
nh <- left_join(nh,countyindex,by="tract")

# some manual tract entry that isnt picked up by merge
nh <- nh %>% 
  mutate(fips = ifelse(tract == "040500","013",fips)) %>% 
  mutate(fips = ifelse(tract == "965800","001",fips)) %>% 
  mutate(fips = ifelse(tract == "966402","001",fips)) %>% 
  mutate(fips = ifelse(tract == "970400","005",fips)) %>% 
  mutate(fips = ifelse(tract == "970900","005",fips)) %>% 
  mutate(fips = ifelse(tract == "000101","011",fips)) %>% 
  mutate(fips = ifelse(tract == "010800","011",fips)) %>%
  mutate(fips = ifelse(tract == "000102","011",fips)) 

nh <- nh %>% 
  mutate(newtract = paste0("33",fips,tract)) 

nh <- nh %>% 
  mutate(value = ifelse(value==".",NA,value)) %>% 
  pivot_wider(names_from = measure, values_from = value) %>% 
  rowwise() %>% 
  mutate(BLL_geq_5 = sum(as.numeric(`6 - 9 �g/dL Venous`),as.numeric(`Capillary Tests`),as.numeric(`Existing 10 �g/dL`),as.numeric(`New 10 �g/dL Venous`),na.rm=TRUE)) %>% 
  mutate(BLL_geq_10 = sum(as.numeric(`Capillary Tests`),as.numeric(`Existing 10 �g/dL`),as.numeric(`New 10 �g/dL Venous`),na.rm=TRUE)) %>% 
  select(-tract) %>% 
  rename(tract=newtract) %>% 
  mutate(state="NH") %>% 
  relocate(state) %>% 
  mutate(year=factor(year))

# remove unnecessary variables
rm(nh2_path, nh_path, nhtested, countyindex, new_names)

# save to csv
write_csv(nh, "../processed_files/nh.csv")