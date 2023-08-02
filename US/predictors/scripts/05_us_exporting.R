# US exporting 

# Write US data to a CSV

data_zcta %>% 
  as.data.frame() %>%
  select(-geometry) %>%
  write_csv("data_processed/predictors_zcta_draft.csv")

