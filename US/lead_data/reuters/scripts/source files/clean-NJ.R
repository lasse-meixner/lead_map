library(tidyverse)
library(readxl)
# library(xlsx)


         
file_path <- 'BLL_NJ_Raw.xlsx'


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
njraw <- paste0("../../raw_data/", file_path) %>%
  excel_sheets() %>% # Read in the names of all sheets in the .xlsx file
  map_df(~ read_excel(path = paste0("../../raw_data/", file_path), sheet ='NJ_redact',skip = 2,col_types = c("text",rep("guess",55))))


# create dataframes for each year

for(i in 1:11){
  df <-  data.frame(njraw[,c(1,(5*(i-1)+2):(5*(i-1)+4))])
  df <-  mutate(df, year=2004+i)
  names(df)[2] <- "BLL_geq_5"
  names(df)[3] <- "BLL_geq_10"
  names(df)[4] <- "tested"
  assign(paste(2004+i),df)
}

# bind dataframes
nj <-  bind_rows(`2005`,`2006`,`2007`,`2008`,`2009`,`2010`,`2011`,`2012`,`2013`,`2014`,`2015`)

nj <- nj %>% 
  rename(zip = `Zip.Code`) %>%
  mutate(tested=replace(tested, tested == "(b)(6)", "<5"))%>%
  mutate(BLL_geq_5=replace(BLL_geq_5, BLL_geq_5 == "(b)(6)", "<5"))%>%
  mutate(BLL_geq_10=replace(BLL_geq_10, BLL_geq_10 == "(b)(6)", "<5"))%>%
  mutate(state = 'NJ') %>%
  relocate(state) %>%
  mutate(year = factor(year)) %>% 
  mutate(n=nchar(zip)) %>% 
  mutate(zip=ifelse(n==2,paste0("000",zip),ifelse(n==3,paste0("00",zip),ifelse(n==4,paste0("0",zip),zip)))) %>% # add leading zeros
  filter(nchar(zip) == 5) |> # remove "missing" and illegal zips
  select(-n) # remove n column


# remove unnecessary variables
rm(njraw, df, `2005`,`2006`,`2007`,`2008`,`2009`,`2010`,`2011`,`2012`,`2013`,`2014`,`2015`)

# save to csv
write_csv(nj, file = "../../processed_data/nj.csv")