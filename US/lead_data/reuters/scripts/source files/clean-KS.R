library(tidyverse)
library(readxl)
# library(xlsx)



file_path <- 'BLL_KS_Raw.xlsx'


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


ks <- read_excel(paste0("../../raw_data/", file_path),skip=2) %>% 
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
  mutate(state='KS') %>% 
  relocate(state)

#TODO: Check this!
## assuming that every year is the same as the average of the years.
ks2005 <- ks %>% mutate(year=2005)
ks2006 <- ks %>% mutate(year=2006)
ks2007 <- ks %>% mutate(year=2007)
ks2008 <- ks %>% mutate(year=2008)
ks2009 <- ks %>% mutate(year=2009)
ks2010 <- ks %>% mutate(year=2010)
ks2011 <- ks %>% mutate(year=2011)
ks2012 <- ks %>% mutate(year=2012)


## merging all the replicated years into one larger file
ks <- rbind(ks2005,ks2006,ks2007,ks2008,ks2009,ks2010,ks2011,ks2012) %>% 
  mutate(year=factor(year))

# remove unnecessary variables
rm(ks2005,ks2006,ks2007,ks2008,ks2009,ks2010,ks2011,ks2012)

# save to csv
write_csv(ks, file = "../../processed_data/ks.csv")