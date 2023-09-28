
### open SAS data file 

library(haven)


         
file_path <- "BLL_TX_Raw.sas7bdat"


#TODO: set working directory in script?

# check if file exists in raw_data, if not, download it from Gdrive
if (!file.exists(paste0("../../raw_data/",file_path))){
       print("Downloading file from Google Drive...")
       drive_download(
              file = paste0("Lead_Map_Project/US/lead_data/raw_data/", file_path),
              path = paste0("../../raw_data/", file_path),
              overwrite = TRUE
       )
} else {
   print(paste0("File ", file_path ," already in local folder."))
}


tx <- read_sas(paste0("../../raw_data/", file_path)) %>% 
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
write_csv(tx, "../../processed_data/tx.csv")