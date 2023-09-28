library(readxl)
library(tidyverse)
library(dplyr)




file_path <- 'BLL_SC_Raw.xlsx'


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



# Read in all sheets and bind into a single tibble
# (based on <https://readxl.tidyverse.org/articles/readxl-workflows.html>)
sc <- paste0("../../raw_data/", file_path) %>%
  excel_sheets() %>% # Read in the names of all sheets in the .xlsx file
  set_names() %>% # First three lines in each sheet are garbage!
  map_df(~ read_excel(path = paste0("../../raw_data/", file_path), sheet=.x, skip = 0), .id = 'sheet') %>% 
  filter(sheet!="Data Information") %>% 
  rename(year=sheet) %>% 
  select(-`SOUTH CAROLINA CHILDREN'S (<6 YEARS OF AGE) BLOOD LEAD DATA BY ZIP CODE, 2010 - 2015`) %>% 
  rename(zip=ZipCode,
         tested=3, ### need to use column order. name of the column cannot be recognised due to characters
         BLL_geq_5=4,
         BLL_geq_10=5) %>% 
  filter(zip!="UNKNOWN",
         zip!="SOUTH CAROLINA") %>% 
  mutate(year=factor(year),
         state="SC",
         tested=replace(tested, tested == "~", "<5"),
         BLL_geq_5=replace(BLL_geq_5, BLL_geq_5 == "~", "<5"),
         BLL_geq_10=replace(BLL_geq_10, BLL_geq_10 == "~", "<5"))
  
# save to csv
write_csv(sc, file = "../../processed_data/sc.csv")