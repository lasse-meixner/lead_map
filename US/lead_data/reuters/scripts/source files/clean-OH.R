library(tidyverse)
library(readxl)


         
file_path <- 'BLL_OH_Raw.xlsx'


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
ohraw <- paste0("../../raw_data/", file_path) %>%
  excel_sheets() %>% # Read in the names of all sheets in the .xlsx file
  map_df(~ read_excel(path = paste0("../../raw_data/", file_path), sheet ='OH_redact',skip = 2))


# create dataframes for each year

for(i in 1:11){
  df <-  data.frame(ohraw[,c(1,(5*(i-1)+2):(5*(i-1)+4))])
  df <-  mutate(df, year=2004+i)
  names(df)[2] <- "BLL_geq_5"
  names(df)[3] <- "BLL_geq_10"
  names(df)[4] <- "tested"
  assign(paste(2004+i),df)
}

# bind dataframes
oh <-  bind_rows(`2005`,`2006`,`2007`,`2008`,`2009`,`2010`,`2011`,`2012`,`2013`,`2014`,`2015`)

oh <- oh %>% 
  rename(tract = `Census.Tract`) %>%
  mutate(tested=replace(tested, tested == "(b)(6)", "<5"))%>%
  mutate(BLL_geq_5=replace(BLL_geq_5, BLL_geq_5 == "(b)(6)", "<5"))%>%
  mutate(BLL_geq_10=replace(BLL_geq_10, BLL_geq_10 == "(b)(6)", "<5"))%>%
  mutate(state = 'OH') %>%
  relocate(state) %>%
  mutate(year = factor(year)) %>%
  mutate(n=nchar(tract)) %>%  
  filter(n==9) %>%  # get the right granularity of tracts (9+2 digits)
  mutate(tract=paste0(39,tract)) |>
  select(-n) 


# remove unnecessary variables
rm(ohraw, df, `2005`,`2006`,`2007`,`2008`,`2009`,`2010`,`2011`,`2012`,`2013`,`2014`,`2015`)

# save to csv
write_csv(oh, file = "../../processed_data/oh.csv")
