

## Census tract to ZIP code mapping


# try to setwd to the raw_files folder, if cannot change directory, assume already in raw_files folder
tryCatch(setwd(dir = "../raw_files/"),
         error = function(e) 1)

# Crosswalk file to be pulled from DropBox
tract_path <- 'TRACT_ZIP_032010.xlsx'

# if drop_get_from_root function is in env, continue, otherwise source "00_drop_box_access.R"
if (exists("drop_get_from_root")) {
    drop_get_from_root(tract_path)
} else {
    source("../scripts/00_drop_box_access.R")
    drop_get_from_root(tract_path)
}

tracttozip <- read_excel(tract_path) %>% 
  rename(tract=TRACT)


## Ohio

track_oh <- oh %>% 
  mutate(n=nchar(tract)) %>% 
  filter(n==9) %>% 
  mutate(tract=paste0(39,tract)) %>% 
  mutate(newn=nchar(tract))

## make decision to call <5 = 0.

oh_zip <- left_join(track_oh,tracttozip,key=tract) %>% 
  mutate(BLL_geq_5 = as.numeric(BLL_geq_5),
         BLL_geq_10 = as.numeric(BLL_geq_10),
         tested=as.numeric(tested)) %>% 
  mutate(new_BLL_geq_5 = BLL_geq_5*RES_RATIO,
         new_BLL_geq_10 = BLL_geq_10*RES_RATIO,
         new_tested = tested*RES_RATIO,
         new_BLL_geq_5_max = BLL_geq_5_max*RES_RATIO,
         new_BLL_geq_5_min = BLL_geq_5_min*RES_RATIO,
         new_BLL_geq_10_max = BLL_geq_10_max*RES_RATIO,
         new_BLL_geq_10_min = BLL_geq_10_min*RES_RATIO,
         new_tested_max = tested_max*RES_RATIO,
         new_tested_min = tested_min*RES_RATIO) %>% 
  group_by(ZIP,year) %>% 
  summarise(BLL_geq_5 = sum(new_BLL_geq_5,na.rm = TRUE),
            BLL_geq_10 = sum(new_BLL_geq_10,na.rm = TRUE),
            tested = sum(new_tested,na.rm = TRUE),
            BLL_geq_5_max = sum(new_BLL_geq_5_max,na.rm = TRUE),
            BLL_geq_5_min = sum(new_BLL_geq_5_min,na.rm = TRUE),
            BLL_geq_10_max = sum(new_BLL_geq_10_max,na.rm = TRUE),
            BLL_geq_10_min = sum(new_BLL_geq_10_min,na.rm = TRUE),
            tested_max = sum(new_tested_max,na.rm = TRUE),
            tested_min = sum(new_tested_min,na.rm = TRUE)) %>% 
  rename(zip=ZIP) %>% 
  mutate(state='OH')

## PA

track_pa <- pa

pa_zip <- left_join(track_pa,tracttozip,key=tract) %>% 
  mutate(BLL_geq_5 = as.numeric(BLL_geq_5),
         BLL_geq_10 = as.numeric(BLL_geq_10),
         tested=as.numeric(tested)) %>% 
  mutate(new_BLL_geq_5 = BLL_geq_5*RES_RATIO,
         new_BLL_geq_10 = BLL_geq_10*RES_RATIO,
         new_tested = tested*RES_RATIO,
         new_BLL_geq_5_max = BLL_geq_5_max*RES_RATIO,
         new_BLL_geq_5_min = BLL_geq_5_min*RES_RATIO,
         new_BLL_geq_10_max = BLL_geq_10_max*RES_RATIO,
         new_BLL_geq_10_min = BLL_geq_10_min*RES_RATIO,
         new_tested_max = tested_max*RES_RATIO,
         new_tested_min = tested_min*RES_RATIO) %>% 
  group_by(ZIP,year) %>% 
  summarise(BLL_geq_5 = sum(new_BLL_geq_5,na.rm = TRUE),
            BLL_geq_10 = sum(new_BLL_geq_10,na.rm = TRUE),
            tested = sum(new_tested,na.rm = TRUE),
            BLL_geq_5_max = sum(new_BLL_geq_5_max,na.rm = TRUE),
            BLL_geq_5_min = sum(new_BLL_geq_5_min,na.rm = TRUE),
            BLL_geq_10_max = sum(new_BLL_geq_10_max,na.rm = TRUE),
            BLL_geq_10_min = sum(new_BLL_geq_10_min,na.rm = TRUE),
            tested_max = sum(new_tested_max,na.rm = TRUE),
            tested_min = sum(new_tested_min,na.rm = TRUE)) %>% 
  rename(zip=ZIP) %>% 
  mutate(state="PA")

## MD 

track_md <- md %>% 
  mutate(n=nchar(tract)) %>% 
  filter(n==11)

md_zip <- left_join(track_md,tracttozip,key=tract) %>% 
  mutate(BLL_geq_5 = as.numeric(BLL_geq_5),
         BLL_geq_10 = as.numeric(BLL_geq_10),
         tested=as.numeric(tested)) %>% 
  mutate(new_BLL_geq_5 = BLL_geq_5*RES_RATIO,
         new_BLL_geq_10 = BLL_geq_10*RES_RATIO,
         new_tested = tested*RES_RATIO) %>% 
  group_by(ZIP,year) %>% 
  summarise(BLL_geq_5 = sum(new_BLL_geq_5,na.rm = TRUE),
            BLL_geq_10 = sum(new_BLL_geq_10,na.rm = TRUE),
            tested = sum(new_tested,na.rm = TRUE)) %>% 
  rename(zip=ZIP) %>% 
  mutate(state='MD')

## MA

track_ma <- ma %>% 
  mutate(n=nchar(tract)) %>% 
  filter(n==11)

ma_zip <- left_join(track_ma,tracttozip,key=tract) %>% 
  mutate(BLL_geq_5 = as.numeric(BLL_geq_5),
         tested=as.numeric(tested)) %>% 
  mutate(new_BLL_geq_5 = BLL_geq_5*RES_RATIO,
         new_tested = tested*RES_RATIO) %>% 
  mutate(new_tested_max = tested_max*RES_RATIO,
         new_tested_min = tested_min*RES_RATIO,
         new_BLL_geq_5_max = BLL_geq_5_max*RES_RATIO,
         new_BLL_geq_5_min = BLL_geq_5_min*RES_RATIO) %>% 
  group_by(ZIP,year) %>% 
  summarise(BLL_geq_5 = sum(new_BLL_geq_5,na.rm = TRUE),
            tested = sum(new_tested,na.rm = TRUE),
            BLL_geq_5_max = sum(new_BLL_geq_5_max,na.rm = TRUE),
            BLL_geq_5_min = sum(new_BLL_geq_5_min,na.rm = TRUE),
            tested_max = sum(new_tested_max,na.rm = TRUE),
            tested_min = sum(new_tested_min,na.rm = TRUE)) %>% 
  rename(zip=ZIP) 

## NYC

### setting to numerics will make >5 equal to NA.
## PR 17/2 - Now incorporates max and min for range of impact for tract conversions

track_nyc <- nyc

nyc_zip <- left_join(track_nyc,tracttozip,key=tract)  %>% 
  mutate(BLL_geq_5 = as.numeric(BLL_geq_5),
         BLL_geq_10 = as.numeric(BLL_geq_10),
         tested=as.numeric(tested)) %>% 
  mutate(new_BLL_geq_5 = BLL_geq_5*RES_RATIO,
         new_BLL_geq_10 = BLL_geq_10*RES_RATIO,
         new_tested = tested*RES_RATIO,
         new_tested_max = tested_max*RES_RATIO,
         new_tested_min = tested_min*RES_RATIO,
         new_BLL_geq_5_max = BLL_geq_5_max*RES_RATIO,
         new_BLL_geq_5_min = BLL_geq_5_min*RES_RATIO,
         new_BLL_geq_10_max = BLL_geq_10_max*RES_RATIO,
         new_BLL_geq_10_min = BLL_geq_10_min*RES_RATIO) %>% 
  group_by(ZIP,year) %>% 
  summarise(BLL_geq_5 = sum(new_BLL_geq_5,na.rm = TRUE),
            BLL_geq_10 = sum(new_BLL_geq_10,na.rm = TRUE),
            tested = sum(new_tested,na.rm = TRUE),
            BLL_geq_5_max = sum(new_BLL_geq_5_max,na.rm = TRUE),
            BLL_geq_5_min = sum(new_BLL_geq_5_min,na.rm = TRUE),
            BLL_geq_10_max = sum(new_BLL_geq_10_max,na.rm = TRUE),
            BLL_geq_10_min = sum(new_BLL_geq_10_min,na.rm = TRUE),
            tested_max = sum(new_tested_max,na.rm = TRUE),
            tested_min = sum(new_tested_min,na.rm = TRUE)) %>% 
  rename(zip=ZIP) 

## NC

track_nc <- nc %>% 
  mutate(n=nchar(tract))

nc_zip <- left_join(track_nc,tracttozip,key=tract) %>% 
  mutate(BLL_geq_5 = as.numeric(BLL_geq_5),
         tested=as.numeric(tested)) %>% 
  mutate(new_BLL_geq_5 = BLL_geq_5*RES_RATIO,
         new_tested = tested*RES_RATIO,
         new_tested_max = tested_max*RES_RATIO,
         new_tested_min = tested_min*RES_RATIO,
         new_BLL_geq_5_max = BLL_geq_5_max*RES_RATIO,
         new_BLL_geq_5_min = BLL_geq_5_min*RES_RATIO) %>% 
  group_by(ZIP,year) %>% 
  summarise(BLL_geq_5 = sum(new_BLL_geq_5,na.rm = TRUE),
            tested = sum(new_tested,na.rm = TRUE),
            BLL_geq_5_max = sum(new_BLL_geq_5_max,na.rm = TRUE),
            BLL_geq_5_min = sum(new_BLL_geq_5_min,na.rm = TRUE),
            tested_max = sum(new_tested_max,na.rm = TRUE),
            tested_min = sum(new_tested_min,na.rm = TRUE)) %>% 
  rename(zip=ZIP) 
  
### Indiana

track_ind <- ind
  
ind_zip <- left_join(track_ind,tracttozip,key=tract) %>% 
  mutate(BLL_geq_5 = as.numeric(BLL_geq_5),
         tested=as.numeric(tested)) %>% 
  mutate(new_BLL_geq_5 = BLL_geq_5*RES_RATIO,
         new_tested = tested*RES_RATIO) %>% 
  group_by(ZIP,year) %>% 
  summarise(BLL_geq_5 = sum(new_BLL_geq_5,na.rm = TRUE),
            tested = sum(new_tested,na.rm = TRUE)) %>% 
  rename(zip=ZIP) 

## OR

track_or <- or %>% 
  mutate(tract=as.character(tract))

or_zip <- left_join(track_or,tracttozip,key=tract) %>% 
  mutate(BLL_geq_5 = as.numeric(BLL_geq_5),
         tested=as.numeric(tested)) %>% 
  mutate(new_BLL_geq_5 = BLL_geq_5*RES_RATIO,
         new_tested = tested*RES_RATIO,
         new_BLL_geq_5_max = BLL_geq_5_max*RES_RATIO,
         new_BLL_geq_5_min = BLL_geq_5_min*RES_RATIO,
         new_tested_max = tested_max*RES_RATIO,
         new_tested_min = tested_min*RES_RATIO) %>% 
  group_by(ZIP,year) %>% 
  summarise(BLL_geq_5 = sum(new_BLL_geq_5,na.rm = TRUE),
            tested = sum(new_tested,na.rm = TRUE),
            BLL_geq_5_max = sum(new_BLL_geq_5_max,na.rm = TRUE),
            BLL_geq_5_min = sum(new_BLL_geq_5_min,na.rm = TRUE),
            tested_max = sum(new_tested_max,na.rm = TRUE),
            tested_min = sum(new_tested_min,na.rm = TRUE)) %>% 
  rename(zip=ZIP) 
  
## MN

track_mn <- mn %>% 
  mutate(tract=as.character(tract))

mn_zip <- left_join(track_mn,tracttozip,key=tract) %>% 
  mutate(BLL_geq_5 = as.numeric(BLL_geq_5),
         BLL_geq_10 = as.numeric(BLL_geq_10),
         tested=as.numeric(tested)) %>% 
  mutate(new_BLL_geq_5 = BLL_geq_5*RES_RATIO,
         new_BLL_geq_10 = BLL_geq_10*RES_RATIO,
         new_tested = tested*RES_RATIO) %>% 
  group_by(ZIP,year) %>% 
  summarise(BLL_geq_5 = sum(new_BLL_geq_5,na.rm = TRUE),
            BLL_geq_10 = sum(new_BLL_geq_10,na.rm=TRUE),
            tested = sum(new_tested,na.rm = TRUE)) %>% 
  rename(zip=ZIP) 


## Colorado

track_co <- co %>% 
  mutate(tract=as.character(tract))

co_zip <- left_join(track_co,tracttozip,key=tract) %>% 
  mutate(BLL_geq_5 = as.numeric(BLL_geq_5),
         BLL_geq_10 = as.numeric(BLL_geq_10),
         tested=as.numeric(tested)) %>% 
  mutate(new_BLL_geq_5 = BLL_geq_5*RES_RATIO,
         new_BLL_geq_10 = BLL_geq_10*RES_RATIO,
         new_tested = tested*RES_RATIO,
         new_BLL_geq_5_max = BLL_geq_5_max*RES_RATIO,
         new_BLL_geq_5_min = BLL_geq_5_min*RES_RATIO,
         new_BLL_geq_10_max = BLL_geq_10_max*RES_RATIO,
         new_BLL_geq_10_min = BLL_geq_10_min*RES_RATIO,
         new_tested_max = tested_max*RES_RATIO,
         new_tested_min = tested_min*RES_RATIO) %>% 
  group_by(ZIP,year) %>% 
  summarise(BLL_geq_5 = sum(new_BLL_geq_5,na.rm = TRUE),
            BLL_geq_10 = sum(new_BLL_geq_10,na.rm=TRUE),
            tested = sum(new_tested,na.rm = TRUE),
            BLL_geq_5_max = sum(new_BLL_geq_5_max,na.rm = TRUE),
            BLL_geq_5_min = sum(new_BLL_geq_5_min,na.rm = TRUE),
            BLL_geq_10_max = sum(new_BLL_geq_10_max,na.rm=TRUE),
            BLL_geq_10_min = sum(new_BLL_geq_10_min,na.rm=TRUE),
            tested_max = sum(new_tested_max,na.rm = TRUE),
            tested_min = sum(new_tested_min,na.rm = TRUE)) %>% 
  rename(zip=ZIP) 


## New Hampshire

track_nh <- nh %>% 
  mutate(tract=as.character(tract))

nh_zip <- left_join(track_nh,tracttozip,key=tract) %>% 
  mutate(BLL_geq_5 = as.numeric(BLL_geq_5),
         BLL_geq_10 = as.numeric(BLL_geq_10),
         tested=as.numeric(tested)) %>% 
  mutate(new_BLL_geq_5 = BLL_geq_5*RES_RATIO,
         new_BLL_geq_10 = BLL_geq_10*RES_RATIO,
         new_tested = tested*RES_RATIO) %>% 
  group_by(ZIP,year) %>% 
  summarise(BLL_geq_5 = sum(new_BLL_geq_5,na.rm = TRUE),
            BLL_geq_10 = sum(new_BLL_geq_10,na.rm=TRUE),
            tested = sum(new_tested,na.rm = TRUE)) %>% 
  rename(zip=ZIP) 

## Wisconsin 

# track_wi <- wi %>% 
#   mutate(tract=as.character(tract))
# 
# wi_zip <- left_join(track_wi,tracttozip,key=tract) %>% 
#   mutate(BLL_geq_5 = as.numeric(BLL_geq_5),
#          BLL_geq_10 = as.numeric(BLL_geq_10),
#          tested=as.numeric(tested)) %>% 
#   mutate(new_BLL_geq_5 = BLL_geq_5*RES_RATIO,
#          new_BLL_geq_10 = BLL_geq_10*RES_RATIO,
#          new_tested = tested*RES_RATIO) %>% 
#   group_by(ZIP,year) %>% 
#   summarise(BLL_geq_5 = sum(new_BLL_geq_5,na.rm = TRUE),
#             BLL_geq_10 = sum(new_BLL_geq_10,na.rm=TRUE),
#             tested = sum(new_tested,na.rm = TRUE)) %>% 
#   rename(zip=ZIP) 

