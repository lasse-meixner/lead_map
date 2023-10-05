library(tidyverse)
library(readxl)

         
file_path <- 'BLL_NM_Raw.xlsx'


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


nmraw <- paste0("../../raw_data/", file_path) %>%
  excel_sheets() %>% # Read in the names of all sheets in the .xlsx file
  map_df(~ read_excel(path = paste0("../../raw_data/", file_path), sheet ='totaltest',skip = 1))

nm <- nmraw %>% 
  pivot_longer(cols =! `Zipcode`,
               names_sep = " 2",
               names_to = c("type","year")) %>% 
  mutate(year=paste0("2",year)) %>% 
  pivot_wider(names_from = type,
              values_from = value) %>% 
  rename(zip=Zipcode,
         tested=Tests,
         BLL_geq_5=`Elevated Tests 5 mcg/dL -`,
         BLL_geq_10=`Elevated Tests 10 mcg/dL -`) %>% 
  mutate(year=factor(year)) %>% 
  mutate(state="NM") %>% 
  relocate(state)

# remove unnecessary variables
rm(nmraw)

# save to csv
write_csv(nm, "../../processed_data/nm.csv")