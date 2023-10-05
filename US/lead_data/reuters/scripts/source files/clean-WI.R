library(tidyverse)
library(readxl)


file_path <- 'BLL_WI2_Raw.csv'

# if drop_get_from_root function is in env, do nothing, otherwise source "00_drop_box_access.R"
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

wi_raw <- drop_read_csv(paste0(reuters_drop_box_base_url, file_path), dest = "../raw_files/")
  
wi <- wi_raw |> 
  rename(tract = GEOID,
         county = COUNTY,
         year = YEAR,
         tested = TESTED,
         BLL_geq_5 = POISONED) |> 
  filter(nchar(tract) == 11) |>
  select(tract, county, year, tested, BLL_geq_5) |>
  mutate(BLL_geq_5 = ifelse(BLL_geq_5 == -5, "<5", BLL_geq_5),
         state = "WI") |> 
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
  # divide the numeric variables by 4
  mutate(tested = (tested / 4),
         BLL_geq_5 = ifelse(is_sup, "<1.25", as.numeric(BLL_geq_5_num / 4))) |> 
  select(-is_sup, -BLL_geq_5_num) |> 
  relocate(state)

  # remove the raw file
  rm(wi_raw)

# save to csv
write_csv(wi, file = "../../processed_data/vt.csv")
                    