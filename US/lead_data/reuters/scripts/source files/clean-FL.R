library(readxl)
library(tidyverse)


         
file_path <- 'BLL_FL_Raw.xlsx'


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


fl <- read_excel(paste0("../../raw_data/", file_path), skip = 1) %>% 
  pivot_longer(cols=!`Zip code`,
               names_sep = ' ',
               names_to = c('year','measure')) %>% 
  pivot_wider(names_from='measure',
              values_from='value') %>% 
  rename(zip=`Zip code`,
         tested=number,
         BLL_geq_10=`\r\ncases`) %>% 
  mutate(year=factor(year)) %>% 
  mutate(state='FL') %>% 
  relocate(state)


# save to csv
write_csv(fl, "../../processed_data/fl.csv")