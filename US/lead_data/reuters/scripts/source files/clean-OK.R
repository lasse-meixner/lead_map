library(tidyverse)
library(readxl)
# library(xlsx)

setwd(dir = "/Users/peter/Documents/Oxford/Frank RA/Lead Project/Raw Files")
ok_path <- 'BLL_OK_Raw.xlsx'

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






