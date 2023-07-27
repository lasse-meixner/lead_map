library(tidyverse)
library(readxl)
# library(xlsx)

setwd(dir = "/Users/peter/Documents/Oxford/Frank RA/Lead Project/Raw Files")
dc_path <- 'BLL_DC_Raw.xlsx'
# Read in all sheets and bind into a single tibble
# (based on <https://readxl.tidyverse.org/articles/readxl-workflows.html>)
dcraw <- dc_path %>%
  excel_sheets() %>% # Read in the names of all sheets in the .xlsx file
  map_df(~ read_excel(path = dc_path, sheet ='DC_redact',skip = 2))


for(i in 1:11){
  df <-  data.frame(dcraw[,c(1,(5*(i-1)+2):(5*(i-1)+4))])
  df <-  mutate(df, year=2004+i)
  names(df)[2] <- "BLL_geq_5"
  names(df)[3] <- "BLL_geq_10"
  names(df)[4] <- "tested"
  assign(paste(2004+i),df)
}

# bind dataframes
dc <-  bind_rows(`2005`,`2006`,`2007`,`2008`,`2009`,`2010`,`2011`,`2012`,`2013`,`2014`,`2015`)

dc <- dc %>% 
  rename(zip = `Zip.Code`) %>% 
  mutate(n=nchar(zip)) %>% 
  mutate(zip=ifelse(n==2,paste0("000",zip),
                    ifelse(n==3,paste0("00",zip),
                           ifelse(n==4,paste0("0",zip),zip)))) %>% 
  mutate(tested=replace(tested, tested == "(b)(6)", "<5"))%>%
  mutate(BLL_geq_5=replace(BLL_geq_5, BLL_geq_5 == "(b)(6)", "<5"))%>%
  mutate(BLL_geq_10=replace(BLL_geq_10, BLL_geq_10 == "(b)(6)", "<5"))%>%
  mutate(state = 'DC') %>%
  relocate(state) %>% 
  mutate(year=factor(year))
  
  


