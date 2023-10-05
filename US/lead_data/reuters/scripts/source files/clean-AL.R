library(readxl)
library(tidyverse)
library(dplyr)



file_path <- 'BLL_AL_Raw.xlsx'


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

al <- paste0("../../raw_data/", file_path) %>%
  excel_sheets() %>% # Read in the names of all sheets in the .xlsx file
  set_names() %>% # First three lines in each sheet are garbage!
  map_df(~ read_excel(path = paste0("../../raw_data/", file_path), sheet = .x, skip = 1), .id = 'sheet') %>%
  mutate(BLL_geq_5= `5 to 9` + `10 and greater`) %>% 
  select(-`5 to 9`) %>%
  unite(zip, Zip, `Zip Code`, na.rm = TRUE, remove = TRUE) %>%
  #TODO: filter for zip!="Total"?!
  rename(year = sheet,
         tested = Total,
         BLL_geq_10 = `10 and greater`) %>%
  mutate(state = 'AL',
         year = factor(year)) %>%
  relocate(state)


# save to csv
write_csv(al, "../../processed_data/al.csv")