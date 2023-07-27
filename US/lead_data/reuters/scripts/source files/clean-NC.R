library(tidyverse)
library(readxl)

tryCatch(setwd(dir = "../../raw_files/"),
         error = function(e) 1)
         
nc_path <- 'BLL_NC_Raw.xlsx'

# if drop_get_from_root function is in env, continue, otherwise source "00_drop_box_access.R"
if (exists("drop_get_from_root")) {
    drop_get_from_root(nc_path)
} else {
    source("../scripts/00_drop_box_access.R")
    drop_get_from_root(nc_path)
}


# Read in all sheets and bind into a single tibble
# (based on <https://readxl.tidyverse.org/articles/readxl-workflows.html>)
ncraw <- nc_path %>%
  excel_sheets() %>% # Read in the names of all sheets in the .xlsx file
  map_df(~ read_excel(path = nc_path, sheet ='NC_redact',skip = 2))



# create dataframes for each year

for(i in 1:11){
  df <-  data.frame(ncraw[,c(1,(5*(i-1)+2):(5*(i-1)+4))])
  df <-  mutate(df, year=2004+i)
  names(df)[2] <- "BLL_geq_5"
  names(df)[3] <- "BLL_geq_10"
  names(df)[4] <- "tested"
  assign(paste(2004+i),df)
}

# bind dataframes
nc <-  bind_rows(`2005`,`2006`,`2007`,`2008`,`2009`,`2010`,`2011`,`2012`,`2013`,`2014`,`2015`)


nc <- nc %>% 
  rename(tract = `Census.Tract`) %>%
  mutate(tested=replace(tested, tested == "(b)(6)", "<5"))%>%
  mutate(BLL_geq_5=replace(BLL_geq_5, BLL_geq_5 == "(b)(6)", "<5"))%>%
  mutate(BLL_geq_10=replace(BLL_geq_10, BLL_geq_10 == "(b)(6)", "<5"))%>%
  mutate(state = 'NC') %>%
  relocate(state) %>%
  mutate(year = factor(year)) %>% 
  mutate(n=nchar(tract)) %>% 
  ##### the state tract codes were missing 0s at certain points. This is mapped to state FIPS code
  ## data by comparing the character lengths of the tract codes and adding appropriate 0s
  mutate(tract=ifelse(n==8,paste0("00",tract),ifelse(n==9,paste0("0",tract),tract))) %>%
  mutate(tract=paste0(substring(tract,first=1,last=3),substring(tract,first=5,last=10))) %>% 
  mutate(tract=paste0("37",tract)) %>% 
  mutate(newn=nchar(tract)) %>% 
  filter(newn==11)

# remove unnecessary variables
rm(ncraw, `2005`,`2006`,`2007`,`2008`,`2009`,`2010`,`2011`,`2012`,`2013`,`2014`,`2015`)

# save to csv
write_csv(nc, file = "../../processed_files/nc.csv")