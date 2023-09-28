library(readxl)
library(tidyverse)


         
file_path <- 'BLL_CT_Raw.xlsx'


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


ct <- read_excel(paste0("../../raw_data/", file_path)) %>% 
  pivot_longer(cols=!`Zip_Code`,
               names_sep = -4,
               names_to = c('measure','year')) %>% 
  pivot_wider(names_from=measure,values_from=value) %>% 
  rename(BLL_geq_5=VGT5_,
         zip=Zip_Code) %>% 
  mutate(state="CT",
         year=factor(year),
         tested = na_if(tested, "."), # . represents NA, not suppression
         BLL_geq_5 = na_if(BLL_geq_5, "."))

         
# save to csv
write_csv(ct, "../../processed_data/ct.csv")