library(readxl)
library(tidyverse)
library(dplyr)


         
file_path <- 'BLL_NY_Raw.xlsx'


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



ny <- read_excel(paste0("../../raw_data/", file_path)) %>%
  rename(BLL_geq_5 = `Children tested => 5 mg/dL`,
         tested = `All Unique Children Tested (up to 72 months of age)`,
         year=Year,
         zip=Zip) %>% 
  mutate(state='NY') %>% 
  select(-`County Code`, -`County`) %>% 
  mutate(year=factor(year)) %>% 
  relocate(state) %>% 
  mutate(tested=ifelse(tested=='*',"<7",tested)) %>% # replace * with <7, as this appears to be the empirical cutoff
  mutate(BLL_geq_5=ifelse(BLL_geq_5 == '*', "<7", BLL_geq_5)) %>% 
  mutate(BLL_geq_5=ifelse(BLL_geq_5 == '.', NA, BLL_geq_5)) %>% # replace . with NA
  mutate(zip=as.character(zip))

# save to csv
write_csv(ny, "../../processed_data/ny.csv")