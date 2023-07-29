library(dplyr)
library(tabulizer)

## Load in CA files


         
ca_path <- "../../raw_files/BLL_CA_Raw.pdf"

# if drop_get_from_root function is in env, continue, otherwise source "00_drop_box_access.R"
if (exists("drop_get_from_root")) {
    drop_get_from_root(ca_path)
} else {
    source("../00_drop_box_access.R")
    drop_get_from_root(ca_path)
}

ca_raw <- extract_tables(ca_path) # uses tabulizer


for(i in 1:13){
  df <- ca_raw %>% 
  pluck(i) %>% 
  as_tibble() %>% 
  separate(V4,into=c("BLL_geq_5","%"),sep=" ") %>% 
  rename(zip=V1,
         country=V2,
         tested=V3) %>% 
  mutate(state='CA') %>% 
  filter(!row_number() %in% c(1, 2, 3)) %>% 
  select(-'%')
  assign(paste0("CA_Rawpg",i),df)
      }

ca_pages <- list(CA_Rawpg1,CA_Rawpg2,CA_Rawpg3,CA_Rawpg4,CA_Rawpg5,
                 CA_Rawpg6,CA_Rawpg7,CA_Rawpg8,CA_Rawpg9,CA_Rawpg10,
                 CA_Rawpg11,CA_Rawpg12,CA_Rawpg13)

ca <- ca_pages %>% 
  reduce(full_join) %>% 
  mutate(BLL_geq_5=ifelse(BLL_geq_5=="0.00%",0,BLL_geq_5)) %>% ## some empty values will pick up the % from the original pdf
  mutate(year=2012) %>% 
  mutate(year=factor(year))

# remove pages
rm(CA_Rawpg1,CA_Rawpg2,CA_Rawpg3,CA_Rawpg4,CA_Rawpg5,
   CA_Rawpg6,CA_Rawpg7,CA_Rawpg8,CA_Rawpg9,CA_Rawpg10,
   CA_Rawpg11,CA_Rawpg12,CA_Rawpg13)

# save to csv
write_csv(ca, "../processed_files/ca.csv")
