# US merging 

require(tidyverse)

# for each data object, check if it's already in memory, otherwise read from processed_data directory
for (obj in c("acs_dec_tract", "svi", "roads_clean", "tri_cleaned")) {
  if (exists(obj)) {
    print(paste0(obj, " already in memory"))
  } else {
    assign(obj, read_csv(paste0("../processed_data/", obj, ".csv")))
  }
}

data_tract <- acs_dec_tract |>
  left_join(., svi) |>
  left_join(., roads_clean) |>
  left_join(., tri_cleaned) |>
  relocate(tract, .after = state)

data_tract |>
  write_csv("../processed_data/combined_tract.csv")



# NOTE: think about aggregation to ZIPs for those states in which only ZIP level data is available (use USPS API!)
