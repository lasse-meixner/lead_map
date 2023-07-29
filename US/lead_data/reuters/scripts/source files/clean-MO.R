library(readxl)
library(tidyverse)


         
mo_path <- 'BLL_MO_Raw.xlsx'

# if drop_get_from_root function is in env, continue, otherwise source "00_drop_box_access.R"
if (exists("drop_get_from_root")) {
    drop_get_from_root(mo_path)
} else {
    source("../00_drop_box_access.R")
    drop_get_from_root(mo_path)
}


## Missouri stored data in different sheets. This aggregates those sheets and brings them together

mo1 <- mo_path %>%
  excel_sheets() %>% # Read in the names of all sheets in the .xlsx file
  set_names() %>%
  map_df(~ read_excel(path = mo_path,skip=3,sheet="Zip by Year Total")) %>% 
  mutate(measure='tested')

mo2 <- mo_path %>%
  excel_sheets() %>% # Read in the names of all sheets in the .xlsx file
  set_names() %>%
  map_df(~ read_excel(path = mo_path,skip=3,sheet="Zip by Year 5+")) %>% 
  mutate(measure='BLL_geq_5')

mo3 <- mo_path %>%
  excel_sheets() %>% # Read in the names of all sheets in the .xlsx file
  set_names() %>%
  map_df(~ read_excel(path = mo_path,skip=3,sheet="Zip by Year 10+")) %>% 
  mutate(measure='BLL_geq_10')

mo <- rbind(mo1,mo2,mo3) %>% 
  filter(`Year:`!='Statistics:',
         `Year:`!='Zip / ZCTA',
         `Year:`!='Total for selection',
         `Year:`!='Confidentiality:',
         `Year:`!='Source:',
         `Year:`!='Generated On:') %>% 
  select(-`Total for selection`) %>% 
  rename(zip=`Year:`) %>% 
  relocate(measure) %>% 
  pivot_longer(cols=3:8,
               names_to = 'year') %>% 
  mutate(value = replace(value, value=="x", "<5")) %>% # TODO: Check with answer from Missouri State Hleath Dept to confirm confidentiality trigger
  distinct() %>% 
  pivot_wider(names_from = 'measure',
              values_from = 'value') %>% 
  mutate(state='MO',
         year=factor(year)) %>% 
  relocate(state)


# remove unnecessary objects
rm(mo1,mo2,mo3)

# save to csv
write_csv(mo, "../processed_files/mo.csv")