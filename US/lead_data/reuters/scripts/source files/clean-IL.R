library(readxl)
library(tidyverse)
library(dplyr)



file_path <- 'BLL_IL_Raw.xlsx'


#TODO: set working directory in script?

# check if file exists in raw_data, if not, download it from Gdrive
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


il <- read_excel(paste0("../../raw_data/", file_path)) %>% 
  pivot_longer(Test2005:ebl2015) %>% 
  mutate(year=str_sub(name,start=-4)) %>% 
  mutate(state='IL') %>% 
  mutate(year=factor(year)) %>% 
  select(-County,-ZIPCode...1) %>%
  rename(zip=ZIPCode...24) %>% 
  mutate(type=str_sub(name,start=1,end=1)) %>% 
  mutate(type=ifelse(type=='T','tested','BLL_geq_10')) %>% 
  mutate(type=factor(type)) %>% 
  select(-name) %>% 
  pivot_wider(names_from=type,values_from = value) %>% 
  relocate(state)

# save to csv
write_csv(il, "../../processed_data/il.csv")