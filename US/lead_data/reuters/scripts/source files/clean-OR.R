library(readxl)
library(tidyverse)


         
file_path <- 'BLL_OR_Raw.xlsx'


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


# Tested but not confirmed (???)
or1 <- paste0("../../raw_data/", file_path) %>%
  excel_sheets() %>% # Read in the names of all sheets in the .xlsx file
  set_names() %>%
  map_df(~ read_excel(path = paste0("../../raw_data/", file_path), sheet = "Tested_LT3yo_2004-2015"), .id = 'sheet') %>%
  slice(-1) %>% # It's best not to subset by position: do it by name
  select(-17) %>% # otherwise someone reading the file can't tell what's happening
  pivot_longer(cols = 5:16 ,
               names_to = c('year')) %>%
  rename(tract = `Tract ID`,
         tested = `value`,
         county = `County`,
         tractlabel = `Tract Label`
  )  %>%
  select(-1) %>% # Same comment as above
  mutate(year = factor(year),
         tract = as.character(tract))

# Confirmed
or2 <- paste0("../../raw_data/", file_path) %>%
  excel_sheets() %>% # Read in the names of all sheets in the .xlsx file
  set_names() %>%
  map_df(~ read_excel(path = paste0("../../raw_data/", file_path), sheet = "Confirmed EBLLs 2004-2015"), .id = 'sheet') %>%
  subset(!is.na(County)) %>%
  select(-17) %>%
  pivot_longer(cols = 5:16 ,
               names_to = c('year')) %>%
  rename(tract = `Tract ID`,
         BLL_geq_5 = `value`,
         county = `County`,
         tractlabel = `Tract Label`
  ) %>%
  select(-1) %>%
  mutate(year = factor(year),
         tract = as.character(tract),
         state = "OR")


# Better to use a "join" function from dplyr so you get a tibble. Also it's
# a bit clearer what's happening

or <- inner_join(or1, or2, by=c("tract","year")) %>%
  select(-tractlabel.y, -county.y, - tractlabel.x, -county.x) # none of these are needed if we have the tract

# remove unnecessary objects
rm(or1, or2)

# save to csv
write_csv(or, "../../processed_data/or.csv")