library(readxl)
library(tidyverse)


         
file_path <- 'BLL_IN_Raw.xlsx'
file_path2 <- 'INDIANA_COUNTY.xlsx'


# check if file 1 exists in raw_data, if not, download it from Gdrive
if (!file.exists(paste0("../../raw_data/",file_path))){
       print("Downloading file from Google Drive...")
       drive_download(
              file = paste0("Lead_Map_Project/US/lead_data/raw_data/", file_path),
              path = paste0("../../raw_data/", file_path),
              overwrite = TRUE
       )
} else {
   print(paste0("File ", file_path ," already in local folder."))
}

# check if file 2  exists in raw_data, if not, download it from Gdrive
if (!file.exists(paste0("../../raw_data/",file_path2))){
       print("Downloading file from Google Drive...")
       drive_download(
              file = paste0("Lead_Map_Project/US/lead_data/raw_data/", file_pat2h),
              path = paste0("../../raw_data/", file_path2),
              overwrite = TRUE
       )
} else {
   print(paste0("File ", file_path2 ," already in local folder."))
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