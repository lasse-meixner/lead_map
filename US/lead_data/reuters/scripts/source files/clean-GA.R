library(tidyverse)
library(readxl)

setwd(dir = "/Users/peter/Documents/Oxford/Frank RA/Lead Project/Raw Files")
ga_path <- 'BLL_GA_Raw.xlsx'

garaw <- ga_path %>%
  excel_sheets() %>% # Read in the names of all sheets in the .xlsx file
  map_df(~ read_excel(path = ga_path, sheet ='NEW',skip = 3))

# create dataframes for each year

for(i in 1:11){
  df <-  data.frame(garaw[,c(1,i+1,i+13)])
  df <-  mutate(df, year=2004+i)
  names(df)[2] <- "BLL_leq_5"
  names(df)[3] <- "BLL_geq_5"
  assign(paste(2004+i),df)
}

# bind dataframes'
ga <-  bind_rows(`2005`,`2006`,`2007`,`2008`,`2009`,`2010`,`2011`,`2012`,`2013`,`2014`,`2015`)

ga <- ga %>% 
  rename(zip=...1) %>% 
  mutate(BLL_geq_5=ifelse(is.na(BLL_geq_5),0,BLL_geq_5)) %>% 
  mutate(tested=BLL_geq_5+BLL_leq_5) %>% 
  filter(zip!="NA",
         zip!="All",
         zip!="ZIP",
         zip!="MISSING") %>% 
  mutate(year=factor(year)) %>% 
  mutate(state="GA") %>% 
  relocate(state)
