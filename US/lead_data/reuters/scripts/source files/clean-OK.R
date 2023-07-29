library(tidyverse)
library(readxl)
# library(xlsx)


         
ok_path <- 'BLL_OK_Raw.xlsx'

# if drop_get_from_root function is in env, continue, otherwise source "00_drop_box_access.R"
if (exists("drop_get_from_root")) {
    drop_get_from_root(ok_path)
} else {
    source("../00_drop_box_access.R")
    drop_get_from_root(ok_path)
}

okraw <- ok_path %>%
  excel_sheets() %>% # Read in the names of all sheets in the .xlsx file
  map_df(~ read_excel(path = ok_path, sheet ='By Zip Code',skip = 7))

for(i in 1:11){
  df <-  data.frame(okraw[,c(1,(3*(i-1)+2):(3*(i-1)+4))])
  df <-  mutate(df, year=2004+i)
  names(df)[2] <- "BLL_geq_5"
  names(df)[3] <- "BLL_geq_10"
  names(df)[4] <- "tested"
  assign(paste(2004+i),df)
}

# bind dataframes
ok <-  bind_rows(`2005`,`2006`,`2007`,`2008`,`2009`,`2010`,`2011`,`2012`,`2013`,`2014`,`2015`)

ok <- ok %>% 
  rename(zip=1) %>% #given the naming convention, easiest to use location.
  mutate(year=factor(year)) %>% 
  mutate(state='OK') %>% 
  relocate(state)


# remove unnecessary variables
rm(okraw, `2005`,`2006`,`2007`,`2008`,`2009`,`2010`,`2011`,`2012`,`2013`,`2014`,`2015`)


# save to csv
write_csv(ok, file = "../processed_files/ok.csv")