library(tidyverse)
library(readxl)


         
file_path <- 'BLL_IO_Raw.xlsx'


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
io <- paste0("../../raw_data/", file_path) %>%
  excel_sheets() %>% # Read in the names of all sheets in the .xlsx file
  map_df(~ read_excel(path = paste0("../../raw_data/", file_path), sheet ='Iowa Data')) %>%
  select(- `<5`) %>% 
  rename(year = `Year Tested`,
         zip = `Zip Code`,
         tested = `Total Children Tested`,
         BLL_geq_5 = `>5`,
         BLL_geq_10 = `>10`) %>%
  mutate(tested=replace(tested, tested == "*", "<5"))%>%
  mutate(BLL_geq_5=replace(BLL_geq_5, BLL_geq_5 == "*", "<5"))%>%
  mutate(BLL_geq_10=replace(BLL_geq_10, BLL_geq_10 == "*", "<5"))%>%
  mutate(state = 'IO') %>%
  relocate(state) %>%
  mutate(year = factor(year))

# save to csv
write_csv(io, file = "../../processed_data/io.csv")