library(tidyverse)
library(readxl)
# library(xlsx)


         
file_path <- 'BLL_VA_Raw.xlsx'


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


va <- read_excel(paste0("../../raw_data/", file_path),skip=2) %>% 
  select(1:4) %>% 
  rename(zip=`Zip Code`,
         BLL_geq_5=2, ## use column index here due to specific characters in titles
         BLL_geq_10=3,
         tested=4) %>% 
  filter(zip!='Total',
         zip!='Missing') %>% 
  mutate(tested=replace(tested, tested == "(b)(6)", "<5"))%>%
  mutate(BLL_geq_5=replace(BLL_geq_5, BLL_geq_5 == "(b)(6)", "<5"))%>%
  mutate(BLL_geq_10=replace(BLL_geq_10, BLL_geq_10 == "(b)(6)", "<5")) %>% 
  mutate(state='VA') %>% 
  relocate(state)

## assuming that every year is the same as the average of the years.
va2005 <- va %>% mutate(year=2005)
va2006 <- va %>% mutate(year=2006)
va2007 <- va %>% mutate(year=2007)
va2008 <- va %>% mutate(year=2008)
va2009 <- va %>% mutate(year=2009)
va2010 <- va %>% mutate(year=2010)
va2011 <- va %>% mutate(year=2011)

## merging all the replicated years into one larger file
va <- rbind(va2005,va2006,va2007,va2008,va2009,va2010,va2011) %>% 
  mutate(year=factor(year))


# remove unnecessary variables
rm(va2005,va2006,va2007,va2008,va2009,va2010,va2011)

# save to csv
write_csv(va, file = "../../processed_data/va.csv")