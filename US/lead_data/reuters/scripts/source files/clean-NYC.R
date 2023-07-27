library(tidyverse)
library(readxl)
# library(xlsx)

tryCatch(setwd(dir = "../../raw_files/"),
         error = function(e) 1)
         
nyc_path <- 'BLL_NYC_Raw.xlsx'

# if drop_get_from_root function is in env, continue, otherwise source "00_drop_box_access.R"
if (exists("drop_get_from_root")) {
    drop_get_from_root(nyc_path)
} else {
    source("../scripts/00_drop_box_access.R")
    drop_get_from_root(nyc_path)
}


# Read in all sheets and bind into a single tibble
# (based on <https://readxl.tidyverse.org/articles/readxl-workflows.html>)
nycraw <- nyc_path %>%
  excel_sheets() %>% # Read in the names of all sheets in the .xlsx file
  map_df(~ read_excel(path = nyc_path, sheet ='NYC',skip = 2))


# create dataframes for each year

for(i in 1:11){
  df <-  data.frame(nycraw[,c(1,(5*(i-1)+2):(5*(i-1)+4))])
  df <-  mutate(df, year=2004+i)
  names(df)[2] <- "BLL_geq_5"
  names(df)[3] <- "BLL_geq_10"
  names(df)[4] <- "tested"
  assign(paste(2004+i),df)
}

# bind dataframes
nyc <-  bind_rows(`2005`,`2006`,`2007`,`2008`,`2009`,`2010`,`2011`,`2012`,`2013`,`2014`,`2015`)

nyc <- nyc %>% 
  rename(tract = `Census.Tract`) %>%
  mutate(tested=replace(tested, tested == "(b)(6)", "<5"))%>%
  mutate(BLL_geq_5=replace(BLL_geq_5, BLL_geq_5 == "(b)(6)", "<5"))%>%
  mutate(BLL_geq_10=replace(BLL_geq_10, BLL_geq_10 == "(b)(6)", "<5"))%>%
  mutate(state = 'NYC') %>%
  relocate(state) %>%
  mutate(year = factor(year)) %>% 
  filter(str_detect(tract,"^0061")|str_detect(tract,"^0047")|str_detect(tract,"^0081")|str_detect(tract,"^0085")|str_detect(tract,"^0029")) %>% 
  mutate(tract=substring(tract,2)) %>% 
  mutate(tract=paste0("36",tract)) %>% 
  mutate(n=nchar(tract)) %>% 
  mutate(tract=ifelse(n==9,paste0(tract,"00"),
                      ifelse(n==10,paste0(paste0(substring(tract,1,5),"0"),substring(tract,6,10)),tract)))  %>% 
  distinct()
  
# remove unnecessary variables
rm(nycraw, `2005`,`2006`,`2007`,`2008`,`2009`,`2010`,`2011`,`2012`,`2013`,`2014`,`2015`)

# save to csv
write_csv(nyc, file = "../processed_files/nyc.csv")