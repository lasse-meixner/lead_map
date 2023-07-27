
### open SAS data file 

library(haven)

setwd(dir = "/Users/peter/Documents/Oxford/Frank RA/Lead Project/Raw Files")
tx_path <- "BLL_TX_Raw.sas7bdat"

tx <- read_sas(tx_path) %>% 
  rename(year = year_test,
         zip = ZIP,
         tested = NUM_TESTED,
         BLL_geq_10 = BLL_GE_10) %>% 
  mutate(tested=replace_na(as.numeric(tested),0),
         BLL_geq_10=replace_na(as.numeric(BLL_geq_10),0),
         BLL_5_9=replace_na(as.numeric(BLL_5_9),0)) %>% 
  mutate(BLL_geq_5 = BLL_geq_10 + BLL_5_9) %>% 
  mutate(year=factor(year))
         

