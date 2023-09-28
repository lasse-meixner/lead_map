library(tidyverse)
library(readxl)
# library(xlsx)


         
file_path <- 'BLL_CO_Raw.xlsx'


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


co <- read_excel(paste0("../../raw_data/", file_path)) %>% 
  rename(tract=FIPS,
         tested=N_children_tested,
         BLL_geq_5=N_EBLL5,
         BLL_geq_10=N_EBLL10) %>% 
  mutate(state="CO")

## assume Colorado aggregation is an average of these years and allocate 
## all evenly across years
#TODO: Check this!

co2010 <- co %>% mutate(year=2010)
co2011 <- co %>% mutate(year=2011)
co2012 <- co %>% mutate(year=2012)
co2013 <- co %>% mutate(year=2013)
co2014 <- co %>% mutate(year=2014)

co <- rbind(co2010,co2011,co2012,co2013,co2014) %>% 
  mutate(year=factor(year))

# remove unnecessary variables
rm(co2010,co2011,co2012,co2013,co2014)

# save to csv
write_csv(co, "../../processed_data/co.csv")