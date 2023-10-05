library(tidyverse)
library(readxl)
# library(xlsx)


file_path <- 'BLL_AZ_Raw.xlsx'


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


az <- read_excel(paste0("../../raw_data/", file_path), sheet ='ALL',skip=2) %>% 
  rename(value=`COUNT**`,
         year=`YEAR SAMPLE WAS TAKEN`,
         measure=`BLOOD LEAD LEVEL CATEGORY`) %>% 
  mutate(value=ifelse(value=="*","<6",value)) %>% # suppression <6
  filter(measure!="NA") %>% 
  pivot_wider(names_from=measure,
              values_from=value) %>% 
  select(-starts_with("*")) %>% 
  rename(BLL_leq_5 = `<5 µg/dL`, 
         BLL_geq_10 = `10+ µg/dL`,
         BLL_5_9 = `5-9 µg/dL`) %>%
  # auxiliary cols indicating suppression
  mutate(BLL_5_9_sup = (BLL_5_9 == "<6"),
         BLL_geq_10_sup = (BLL_geq_10 == "<6"),
         BLL_leq_5_sup = (BLL_leq_5 == "<6")) %>%
  # if both are suppressed, then BLL_geq_5 is ">1&<12"
  # if only one is supprsed, then BLL_geq_5 is the other + ">0&<6"
  # if none are suppressed, then BLL_geq_5 is the sum of the two
  mutate(BLL_geq_5 = case_when(
              BLL_5_9_sup & BLL_geq_10_sup ~ ">1&<12",
              BLL_5_9_sup ~ paste0(">", as.numeric(BLL_geq_10), "&<", as.numeric(BLL_geq_10) + 6),
              BLL_geq_10_sup ~ paste0(">", as.numeric(BLL_5_9), "&<", as.numeric(BLL_5_9) + 6),
              .default = as.character(as.numeric(BLL_5_9) + as.numeric(BLL_geq_10))),
        tested = case_when( # similar logic for tested, which is sum of the 3 BLL classes
              BLL_5_9_sup & BLL_geq_10_sup & BLL_leq_5_sup ~ ">2&<18",
              BLL_5_9_sup & BLL_geq_10_sup ~ paste0(">", as.numeric(BLL_leq_5) + 1, "&<", as.numeric(BLL_leq_5) + 12),
              BLL_5_9_sup & BLL_leq_5_sup ~ paste0(">", as.numeric(BLL_geq_10) + 1, "&<", as.numeric(BLL_geq_10) + 12),
              BLL_geq_10_sup & BLL_leq_5_sup ~ paste0(">", as.numeric(BLL_5_9) + 1, "&<", as.numeric(BLL_5_9) + 12),
              BLL_5_9_sup ~ paste0(">", as.numeric(BLL_geq_10) + as.numeric(BLL_leq_5), "&<", as.numeric(BLL_geq_10) + as.numeric(BLL_leq_5) + 6),
              BLL_geq_10_sup ~ paste0(">", as.numeric(BLL_5_9) + as.numeric(BLL_leq_5), "&<", as.numeric(BLL_5_9) + as.numeric(BLL_leq_5) + 6),
              BLL_leq_5_sup ~ paste0(">", as.numeric(BLL_geq_10) + as.numeric(BLL_5_9), "&<", as.numeric(BLL_geq_10) + as.numeric(BLL_5_9) + 6),
              .default = as.character(as.numeric(BLL_5_9) + as.numeric(BLL_geq_10) + as.numeric(BLL_leq_5))),
         year = factor(year),
         state = "AZ") %>% 
  rename(zip=`ZIP CODE`,
         county = COUNTY) %>%
  filter(nchar(zip) == 5) %>%
  select(- BLL_5_9_sup, - BLL_geq_10_sup, - BLL_leq_5_sup)


# save to csv
write_csv(az, "../../processed_data/az.csv")
