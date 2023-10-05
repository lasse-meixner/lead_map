library(readxl)
library(tidyverse)

# This excel file has only a single sheet and is fairly clean, but it's in *wide*
# format, so we convert it to *long format* using tidyr. Here's a nice tutorial:
# <https://dcl-wrangle.stanford.edu/pivot-advanced.html>
# See also *R for Data Science* Chapter 12

         
file_path <- 'BLL_RI_Raw.xlsx'


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



ri <- read_excel(paste0("../../raw_data/", file_path), skip = 5) %>%
  filter(TownName != 'Totals') %>% # The last row gives column totals
  pivot_longer(cols = starts_with('Tested'),
               names_sep = ' ',
               names_to = c('measure', 'year')) %>%
  pivot_wider(names_from = 'measure',
              values_from = 'value') %>%
  rename(town = TownName,
         zip = Zip,
         tested = Tested,
         BLL_geq_5 = `Tested>=5`) %>%
  mutate(state = 'RI') %>%
  relocate(state) %>% 
  fill(zip,.direction = "up") %>% 
  select(-town) %>% 
  mutate(tested=as.character(tested)) %>% 
  mutate(BLL_geq_5=as.character(BLL_geq_5))
  
# save to csv
write_csv(ri, file = "../../processed_data/ri.csv")