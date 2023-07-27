library(tidyverse)
library(readxl)
# library(xlsx)

setwd(dir = "/Users/peter/Documents/Oxford/Frank RA/Lead Project/Raw Files")
pa_path <- 'BLL_PA_Raw.xlsx'
# Read in all sheets and bind into a single tibble
# (based on <https://readxl.tidyverse.org/articles/readxl-workflows.html>)
paraw <- pa_path %>%
  excel_sheets() %>% # Read in the names of all sheets in the .xlsx file
  map_df(~ read_excel(path = pa_path, sheet ='PA_redact',skip = 2))


# create dataframes for each year

for(i in 1:11){
  df <-  data.frame(paraw[,c(1,(5*(i-1)+2):(5*(i-1)+4))])
  df <-  mutate(df, year=2004+i)
  names(df)[2] <- "BLL_geq_5"
  names(df)[3] <- "BLL_geq_10"
  names(df)[4] <- "tested"
  assign(paste(2004+i),df)
}

# bind dataframes
pa <-  bind_rows(`2005`,`2006`,`2007`,`2008`,`2009`,`2010`,`2011`,`2012`,`2013`,`2014`,`2015`)

pa <- pa %>% 
  rename(tract = `Census.Tract`) %>%
  mutate(tested=replace(tested, tested == "(b)(6)", "<5"))%>%
  mutate(BLL_geq_5=replace(BLL_geq_5, BLL_geq_5 == "(b)(6)", "<5"))%>%
  mutate(BLL_geq_10=replace(BLL_geq_10, BLL_geq_10 == "(b)(6)", "<5"))%>%
  mutate(state = 'PA') %>%
  relocate(state) %>%
  mutate(year = factor(year)) %>% 
  mutate(n=nchar(tract)) %>% 
  distinct() %>% 
  mutate(tract=ifelse(n==9,paste0("42",tract),tract)) %>% 
  filter(n==9)
  


