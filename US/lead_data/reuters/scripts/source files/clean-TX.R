
### open SAS data file 

library(haven)


         
tx_path <- "BLL_TX_Raw.sas7bdat"

# if drop_get_from_root function is in env, continue, otherwise source "00_drop_box_access.R"
if (exists("drop_get_from_root")) {
    drop_get_from_root(tx_path)
} else {
    source("../scripts/00_drop_box_access.R")
    drop_get_from_root(tx_path)
}

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
         

# save to csv
write_csv(tx, "../../processed_files/tx.csv")