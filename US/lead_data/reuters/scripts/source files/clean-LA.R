library(tidyverse)
library(readxl)
# library(xlsx)
tryCatch(setwd(dir = "../../raw_files/"),
         error = function(e) 1)
         
la_path <- 'BLL_LA_Raw.xlsx'

# if drop_get_from_root function is in env, continue, otherwise source "00_drop_box_access.R"
if (exists("drop_get_from_root")) {
    drop_get_from_root(la_path)
} else {
    source("../scripts/00_drop_box_access.R")
    drop_get_from_root(la_path)
}

# Read in all sheets and bind into a single tibble
# (based on <https://readxl.tidyverse.org/articles/readxl-workflows.html>)
laraw <- la_path %>%
  excel_sheets() %>% # Read in the names of all sheets in the .xlsx file
  map_df(~ read_excel(path = la_path, sheet ='LA_redact',skip = 2))


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
  mutate(year = factor(year))

# remove unnecessary variables
rm(laraw, `2005`,`2006`,`2007`,`2008`,`2009`,`2010`,`2011`,`2012`,`2013`,`2014`,`2015`)

# save to csv
write_csv(la, file = "../../processed_files/la.csv")