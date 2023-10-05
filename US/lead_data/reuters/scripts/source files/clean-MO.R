library(readxl)
library(tidyverse)


         
file_path <- 'BLL_MO_Raw.xlsx'


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



## Missouri stored data in different sheets. This aggregates those sheets and brings them together

mo1 <- paste0("../../raw_data/", file_path) %>%
  excel_sheets() %>% # Read in the names of all sheets in the .xlsx file
  set_names() %>%
  map_df(~ read_excel(path = paste0("../../raw_data/", file_path),skip=3,sheet="Zip by Year Total")) %>% 
  mutate(measure='tested')

mo2 <- paste0("../../raw_data/", file_path) %>%
  excel_sheets() %>% # Read in the names of all sheets in the .xlsx file
  set_names() %>%
  map_df(~ read_excel(path = paste0("../../raw_data/", file_path),skip=3,sheet="Zip by Year 5+")) %>% 
  mutate(measure='BLL_geq_5')

mo3 <- paste0("../../raw_data/", file_path) %>%
  excel_sheets() %>% # Read in the names of all sheets in the .xlsx file
  set_names() %>%
  map_df(~ read_excel(path = paste0("../../raw_data/", file_path),skip=3,sheet="Zip by Year 10+")) %>% 
  mutate(measure='BLL_geq_10')

mo <- rbind(mo1,mo2,mo3) %>% 
  filter(`Year:`!='Statistics:',
         `Year:`!='Zip / ZCTA',
         `Year:`!='Total for selection',
         `Year:`!='Confidentiality:',
         `Year:`!='Source:',
         `Year:`!='Generated On:') %>% 
  select(-`Total for selection`) %>% 
  rename(zip=`Year:`) %>% 
  relocate(measure) %>% 
  pivot_longer(cols=3:8,
               names_to = 'year') %>% 
  mutate(value = replace(value, value=="x", "<5")) %>% # TODO: Check with answer from Missouri State Hleath Dept to confirm confidentiality trigger
  distinct() %>% 
  pivot_wider(names_from = 'measure',
              values_from = 'value') %>% 
  mutate(state='MO',
         year=factor(year)) %>% 
  relocate(state)


# remove unnecessary objects
rm(mo1,mo2,mo3)

# save to csv
write_csv(mo, "../../processed_data/mo.csv")