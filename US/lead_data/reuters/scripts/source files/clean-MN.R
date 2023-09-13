library(tidyverse)
library(readxl)



mn_path <- 'BLL_MN_Raw.xlsx'

if (!exists("drop_get_from_root")) {
    source("../00_drop_box_access.R")
}

drop_get_from_root(mn_path)

mn <- read_excel(mn_path) %>% 
  mutate(tested_2005_2010=ifelse(tested_2005_2010=='.',NA,tested_2005_2010)) %>% 
  mutate(tested_2011_2015=ifelse(tested_2011_2015=='.',NA,tested_2011_2015)) %>% 
  mutate(ebll5_2011_2015=ifelse(ebll5_2011_2015=='.',NA,ebll5_2011_2015)) %>% 
  mutate(ebll10_2005_2010=ifelse(ebll10_2005_2010=='.',NA,ebll10_2005_2010)) %>% 
  mutate(ebll10_2011_2015=ifelse(ebll10_2011_2015=='.',NA,ebll10_2011_2015)) 

# range variables represent sums over 4 years
# extract years and create a year column for tested, ebll5, and ebll10
mn2005to2010 <- mn %>% 
  select(tract_id, tested_2005_2010, ebll10_2005_2010) %>% 
  mutate(year = "2005-2010") %>% 
  rename(tested = tested_2005_2010,
         BLL_geq_10 = ebll10_2005_2010) |>
  mutate(BLL_geq_5 = NA)

mn2011to2015 <- mn %>%
  select(tract_id, tested_2011_2015, ebll5_2011_2015, ebll10_2011_2015) %>% 
  mutate(year = "2011-2015") %>% 
  rename(tested = tested_2011_2015,
         BLL_geq_5 = ebll5_2011_2015,
         BLL_geq_10 = ebll10_2011_2015)

# append the two dataframe, then unravel years and divide numeric variables by 4
mn <- rbind(mn2005to2010,mn2011to2015) |>
  mutate(tested = as.numeric(tested)) |>
  separate(year, into = c("start_year", "end_year"), sep = "-") |>
  rowwise() |>
  mutate(year = list(seq(start_year, end_year))) |>
  unnest(year) |>
  mutate(is_sup = (BLL_geq_5 == "<5"),
         BLL_geq_5_num = as.numeric(BLL_geq_5)) |>
  mutate(tested = (tested / 4),
          BLL_geq_5 = ifelse(is_sup, "<1.25", as.numeric(BLL_geq_5_num / 4))) |>
  select(-is_sup, -BLL_geq_5_num, start_year, end_year) |>
  mutate(state = "MN") |>
  rename(tract = tract_id) |> 
  relocate(state)

# remove unnecessary objects
rm(mn2005to2010,mn2011to2015)


# save to csv
write_csv(mn, file = "../processed_files/mn.csv")