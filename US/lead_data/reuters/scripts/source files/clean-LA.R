library(tidyverse)
library(readxl)
# library(xlsx)

         
file_path <- 'BLL_LA_Raw.xlsx'


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
laraw <- paste0("../../raw_data/", file_path) %>%
  excel_sheets() %>% # Read in the names of all sheets in the .xlsx file
  map_df(~ read_excel(path = paste0("../../raw_data/", file_path), sheet ='LA_redact',skip = 2))


# create dataframes for each year

for(i in 1:11){
  df <-  data.frame(laraw[,c(1,(5*(i-1)+2):(5*(i-1)+4))])
  df <-  mutate(df, year=2004+i)
  names(df)[2] <- "BLL_geq_5"
  names(df)[3] <- "BLL_geq_10"
  names(df)[4] <- "tested"
  assign(paste(2004+i),df)
}

# bind dataframes
la <-  bind_rows(`2005`,`2006`,`2007`,`2008`,`2009`,`2010`,`2011`,`2012`,`2013`,`2014`,`2015`)

la <- la %>% 
  rename(zip = `Zip.Code`) %>%
  mutate(tested=replace(tested, tested == "(b)(6)", "<5"))%>%
  mutate(BLL_geq_5=replace(BLL_geq_5, BLL_geq_5 == "(b)(6)", "<5"))%>%
  mutate(BLL_geq_10=replace(BLL_geq_10, BLL_geq_10 == "(b)(6)", "<5"))%>%
  mutate(state = 'LA') %>%
  relocate(state) %>%
  mutate(year = factor(year)) %>%
  filter(nchar(zip) == 5) # removes 240 of ~20k entries (where ZIP is missing or illegal)

# remove unnecessary variables
rm(laraw, df, `2005`,`2006`,`2007`,`2008`,`2009`,`2010`,`2011`,`2012`,`2013`,`2014`,`2015`)

# save to csv
write_csv(la, file = "../../processed_data/la.csv")