library(readxl)
library(tidyverse)


         
file_path <- 'BLL_MI_Raw.xlsx'


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



mi <- read_excel(paste0("../../raw_data/", file_path)) %>% 
  pivot_longer(cols=starts_with("Num")) %>% 
  mutate(value=ifelse(value=="**","<6",value)) %>% 
  mutate(year=str_sub(name,start=-4)) %>% 
  mutate(name=str_sub(name,start=4,end=-5)) %>% 
  pivot_wider(names_from=name,values_from=value) %>% 
  rename(tested=Tested,
         BLL_geq_5=EBLL, # It seems to me this should be BLL_geq_5, not BLL_geq_10. The raw data only mentions "EBLL", yet see def. of Michigan report: https://www.michigan.gov/mileadsafe/-/media/Project/Websites/mileadsafe/Reports/2016_CLPPP_Annual_Report_5-1-18.pdf?rev=607b44316e234a4fbf41375bd80c1882&hash=A4A70437975AD0F928EE7D208D3CF45D
         zip=`Zip Code`) %>% 
  select(-County,-State) %>% 
  mutate(year=factor(year)) %>% 
  mutate(state='MI') %>% 
  relocate(state)
  
# save to csv
write_csv(mi, "../../processed_data/mi.csv")