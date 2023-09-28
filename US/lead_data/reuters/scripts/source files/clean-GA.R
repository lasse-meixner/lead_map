library(tidyverse)
library(readxl)


         
file_path <- 'BLL_GA_Raw.xlsx'


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


garaw <- paste0("../../raw_data/", file_path) %>%
  excel_sheets() %>% # Read in the names of all sheets in the .xlsx file
  map_df(~ read_excel(path = paste0("../../raw_data/", file_path), sheet ='NEW',skip = 3))

# create dataframes for each year

for(i in 1:11){
  df <-  data.frame(garaw[,c(1,i+1,i+13)])
  df <-  mutate(df, year=2004+i)
  names(df)[2] <- "BLL_leq_5"
  names(df)[3] <- "BLL_geq_5"
  assign(paste(2004+i),df)
}

# bind dataframes'
ga <-  bind_rows(`2005`,`2006`,`2007`,`2008`,`2009`,`2010`,`2011`,`2012`,`2013`,`2014`,`2015`)

ga <- ga %>% 
  rename(zip=...1) %>% 
  mutate(tested=BLL_geq_5+BLL_leq_5) %>% 
  filter(zip!="NA",
         zip!="All",
         zip!="ZIP",
         zip!="MISSING") %>% 
  mutate(year=factor(year)) %>% 
  mutate(state="GA") %>% 
  relocate(state)

# remove unnecessary variables
rm(garaw, df, `2005`,`2006`,`2007`,`2008`,`2009`,`2010`,`2011`,`2012`,`2013`,`2014`,`2015`)

# save to csv
write_csv(ga, file = "../../processed_data/ga.csv")