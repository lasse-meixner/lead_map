# UK merging
# Now, merge census and non-census data into one sf object each containing all the data for MSOAs
# Note that the MSOAs sf object also includes the LA code for each MSOA
# which is useful for filtering MSOAs in certain LAs, or groupings of LAs
# And similar for the LSOAs sf object (but not OAs currently)

library(tidyverse)

# MSOAs

# for each data object, check if it's already in memory, otherwise read from processed_data directory

for (obj in c("imd_msoa", "sop_msoa", "house_prices_msoa", "income_msoa", "poverty_ons_msoa", "census_data_2011_msoa", "census_data_1991_msoa", "roads_msoa", "pollution_msoa", "soil_msoa", "moss_msoa")) {
  if (exists(obj)) {
    print(paste0(obj, " already in memory"))
  } else {
    assign(obj, read_csv(paste0("../processed_data/", obj, ".csv")))
  }
}


data_msoa <- imd_msoa %>%
  left_join(., sop_msoa) %>%
  left_join(., house_prices_msoa) %>%
  left_join(., income_msoa) %>%
  left_join(., poverty_ons_msoa) %>%
  left_join(., census_data_2011_msoa) %>%
  left_join(., census_data_1991_msoa) %>%
  left_join(., roads_msoa) %>%
  left_join(., pollution_msoa) %>%
  left_join(., soil_msoa) %>%
  left_join(., moss_msoa) %>% # NOTE: no match. to be dropped later. included here since UK wide.
  relocate(total_ppl_census_1991, .after = lad20cd) %>%
  relocate(total_ppl_census_2011, .after = total_ppl_census_1991) %>%
  relocate(total_ppl_est_2015, .after = total_ppl_census_2011) %>%
  relocate(msoa_name, .after = msoa11cd) %>%
  # select out degenerate variables
  select(-c(emissions_yearly_air_2006_density:emissions_yearly_air_2008_density),
         -c(emissions_yearly_air_2006_neighbours_density:emissions_yearly_air_2008_neighbours_density),
         -contains("emissions_yearly_land"),
         -contains("emissions_cumulative_land"))

data_msoa |> 
  write_csv("../processed_data/combined_msoa.csv")


# clear environment except for data_msoa
rm(list = ls() |> setdiff(c("data_msoa")))