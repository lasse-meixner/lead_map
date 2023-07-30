
### open SAS data file 

library(haven)


         
tx_path <- "BLL_TX_Raw.sas7bdat"

# if drop_get_from_root function is in env, continue, otherwise source "00_drop_box_access.R"
if (exists("drop_get_from_root")) {
    drop_get_from_root(tx_path)
} else {
    source("../00_drop_box_access.R")
    drop_get_from_root(tx_path)
}

tx <- read_sas(tx_path) %>% 
  rename(year = year_test,
         zip = ZIP,
         tested = NUM_TESTED,
         BLL_geq_10 = BLL_GE_10) %>% 
  # get rid of spaces in suppressed values
  mutate(BLL_5_9 = replace(BLL_5_9, BLL_5_9 == "< 5", "<5"),
         BLL_geq_10 = replace(BLL_geq_10, BLL_geq_10 == "< 5", "<5")) %>%
  # auxiliary cols indicating suppression
  mutate(BLL_5_9_sup = (BLL_5_9 == "<5"),
         BLL_geq_10_sup = (BLL_geq_10 == "<5")) %>%
  # if both are suppressed, then BLL_geq_5 is ">1&<10"
  # if only one is supprsed, then BLL_geq_5 is the other + ">0&<5"
  # if none are suppressed, then BLL_geq_5 is the sum of the two
  mutate(BLL_geq_5 = case_when(
    BLL_5_9_sup & BLL_geq_10_sup ~ ">1&<10",
    BLL_5_9_sup ~ paste0(">", as.numeric(BLL_geq_10), "&<", as.numeric(BLL_geq_10) + 5),
    BLL_geq_10_sup ~ paste0(">", as.numeric(BLL_5_9), "&<", as.numeric(BLL_5_9) + 5),
    .default = as.character(as.numeric(BLL_5_9) + as.numeric(BLL_geq_10))
      ),
    year = factor(year),
    state = "TX") %>%
  select(-BLL_5_9_sup, -BLL_geq_10_sup)



# save to csv
write_csv(tx, "../processed_files/tx.csv")