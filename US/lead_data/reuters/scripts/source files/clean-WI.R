library(tidyverse)
library(readxl)


file_path <- 'BLL_WI2_Raw.csv'


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

wi_raw <- read_csv(paste0("../../raw_data/", file_path))

wi <- wi_raw |> 
  rename(tract = GEOID,
         county = COUNTY,
         year = YEAR,
         tested = TESTED,
         BLL_geq_5 = POISONED) |> 
  filter(nchar(tract) == 11) |>
  select(tract, county, year, tested, BLL_geq_5) |>
  mutate(BLL_geq_5 = ifelse(BLL_geq_5 == -5, "<5", BLL_geq_5),
         state = "WI",
         tract = as.character(tract)) |> 
  # year are in 4y chunks, e.g. "1998-2001", and vars are summed
  # split the year column into start and end years
  separate(year, into = c("start_year", "end_year"), sep = "-") |>
  # create a sequence of years for each chunk
  rowwise() |>
  mutate(year = list(seq(start_year, end_year))) |>
  # unnest the list of years
  unnest(year) |>
  mutate(is_sup = (BLL_geq_5 == "<5"),
         BLL_geq_5_num = as.numeric(BLL_geq_5)) |>
  # divide the numeric variables by 4 and round to the nearest integer since we run count models
  mutate(tested = round(tested / 4),
         BLL_geq_5 = ifelse(is_sup, 1, round(as.numeric(BLL_geq_5_num / 4)))) |>  #Note: If suppressed, we have <1.25 but not 0, so there is only 1.
  select(-is_sup, -BLL_geq_5_num) |> 
  relocate(state)

  # remove the raw file
  rm(wi_raw)

# save to csv
write_csv(wi, file = "../../processed_data/wi.csv")
                    