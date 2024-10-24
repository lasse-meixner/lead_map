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
  left_join(svi) |>
  left_join(roads_clean) |>
  left_join(tri_cleaned) |>
  relocate(TRACT)

# generate COUNTY and STATE from NAME, e.g. "Census Tract 45.02, Jefferson County, Alabama"
data_tract <- data_tract |>
  mutate(
    COUNTY = str_extract(NAME, "(?<=, ).*?(?=,)"),
    STATE = str_extract(NAME, "(?<=, )[^,]+$")
  ) |>
  relocate(c("STATE", "COUNTY"), .after = TRACT)


# save to disk
data_tract |>
  write_csv("../processed_data/combined_tract.csv")

# write to Gdrive
source("00_gdrive_utils.R")
gdrive_upload_w_tstamp("combined_tract")
