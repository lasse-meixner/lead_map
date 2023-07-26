# Stock of Properties data processing

library(tidyverse)
library(stringr)

# PROPERTY AGE DATA

# Read in Stock of Properties age data for English LSOAs, MSOAs, and LAs

sop_age <- read_csv(paste0(drop_box_base_url,"data_raw/uk/stock_of_properties_2021_age.csv")) %>%
  filter(geography %in% c("LSOA", "MSOA", "LAUA"), 
         band == "All", 
         substr(ecode, 1, 1) == "E") %>%
  select(-ba_code, -area_name, -band) %>%
  mutate(across(bp_pre_1900:all_properties, as.numeric)) %>%
  replace(is.na(.), 0) %>%
  mutate(across(bp_pre_1900:bp_unkw, ~. / all_properties, .names = "{.col}_prop"),
         bp_pre_1929_prop = bp_pre_1900_prop + bp_1900_1918_prop + bp_1919_1929_prop,
         bp_pre_1939_prop = bp_pre_1929_prop + bp_1930_1939_prop,
         bp_pre_1954_prop = bp_pre_1939_prop + bp_1945_1954_prop,
         bp_pre_1982_prop = bp_pre_1954_prop + bp_1955_1964_prop + bp_1965_1972_prop + bp_1973_1982_prop,
         bp_pre_1992_prop = bp_pre_1982_prop + bp_1983_1992_prop,
         bp_pre_1999_prop = bp_pre_1992_prop + bp_1993_1999_prop,
         bp_post_2000_prop = bp_2000_2008_prop + bp_2009_prop + bp_2010_prop + bp_2011_prop + bp_2012_prop + 
           bp_2013_prop + bp_2014_prop + bp_2015_prop + bp_2016_prop + bp_2017_prop + bp_2018_prop + bp_2019_prop + 
           bp_2020_prop + bp_2021_prop) %>%
  select(!c(bp_pre_1900:bp_unkw,
            bp_unkw_prop, all_properties),
         bp_unkw_prop, all_properties) %>% 
  rename("geo_code" = "ecode")

# Create a matrix describing build year intervals and a vector of interval midpoints 
# We will use these objects to impute mean and median build year for each row

year_bins_uk <- sop_age %>%
  select(bp_pre_1900_prop:bp_2021_prop) %>%
  colnames()

start_years_uk <- year_bins_uk[-1] %>%
  substr(., 4, 7) %>%
  as.numeric() %>%
  # If you want to change the assumption about when bp_pre_1900 houses were built, you change 1868.5 in the line below
  c(1837, .)

end_years_uk <- year_bins_uk[-1] %>%
  str_sub(., -9, -6) %>%
  as.numeric() %>%
  c(1899, .)

year_intervals_uk <- cbind(start_years_uk, end_years_uk)

# AT THIS POINT YOU CAN GET RID OF THE year_bins_uk, start_years_uk, and end_years_uk objects
rm(year_bins_uk, start_years_uk, end_years_uk)

mid_years <- rowMeans(year_intervals_uk)

# Impute build year medians and add them to rows
# There should be a better way of doing this, but it was difficult to use mutate(). Perhaps convert data to long format first. 
# Maybe use sapply with mutate. Check Data Rodeo notes

year_col_1st <- grep("bp_pre_1900_prop", colnames(sop_age))
year_col_last <- grep("bp_2021_prop", colnames(sop_age))

for (i in c(1:nrow(sop_age))) {
  vector_of_frequencies <- unlist(sop_age[i, year_col_1st:year_col_last], use.names = FALSE)
  sop_age$build_year_median[i] = GroupedMedian(vector_of_frequencies, year_intervals_uk)
}

# Impute build year means and add them to rows

for (i in c(1:nrow(sop_age))) {
  sop_age$build_year_mean[i] = sum(sop_age[i, year_col_1st:year_col_last] * mid_years) / sum(sop_age[i, year_col_1st:year_col_last])
}

# AT THIS POINT YOU CAN GET RID OF THE year_intervals_uk, mid_years, i, and vector_of_frequencies objects
rm(year_intervals_uk, mid_years, i, vector_of_frequencies)

# PROPERTY TYPE DATA

# Read in Stock of Properties type data for English LSOAs, MSOAs, and LAs

sop_type <- read_csv(paste0(drop_box_base_url,"data_raw/uk/stock_of_properties_2021_type.csv")) %>%
  filter(geography %in% c("LSOA", "MSOA", "LAUA"), 
         band == "All", 
         substr(ecode, 1, 1) == "E") %>%
  select(-ba_code, -geography, -area_name, -band) %>%
  mutate(across(bungalow_1:all_properties, as.numeric),
         across(bungalow_1:all_properties, ~. / all_properties)) %>%
  replace(is.na(.), 0) %>%
  rename("geo_code" = "ecode",
         "type_unknown_prop" = "unknown", 
         "house_terraced_prop" = "house_terraced_total") %>%
  select(geo_code, house_terraced_prop)

# MERGE AGE AND TYPE DATA
# Move build_year_mean, build_year_median, and all_properties to the end

sop <- left_join(sop_age, sop_type) %>%
  select(-build_year_mean, -build_year_median,
         build_year_mean, build_year_median) %>%
  relocate(all_properties, .before = 1)

# Now, filter stock_of_properties_proportions so that you have separate objects for LSOAs, MSOAs. and LAs, like for the processed IMD data

# sop_lsoa <- sop %>%
#   filter(geography == "LSOA") %>%
#   rename("lsoa11cd" = "geo_code") %>%
#   select(-geography)

sop_msoa <- sop %>%
  filter(geography == "MSOA") %>%
  rename("msoa11cd" = "geo_code") %>%
  select(-geography)

# sop_la <- sop %>%
#   filter(geography == "LAUA") %>%
#   rename("lad20cd" = "geo_code") %>%
#   select(-geography)


sop_msoa %>%
  write_csv("data_processed/sop_msoa.csv")

# AT THIS POINT YOU CAN GET RID OF THE sop_proportion OBJECT
rm(sop_age, sop_type, sop)

# Done
