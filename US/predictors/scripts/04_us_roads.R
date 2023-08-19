## read in shapefile
library(googledrive)
library(tidyverse)
library(sf)

# check if tl_2021_us_primaryroads.shp exists in "../raw_data/roads", otherwise download all required files from google drive folder

if (!file.exists("../raw_data/roads/tl_2021_us_primaryroads.shp")) {
  # create directory if it does not exist
  dir.create("../raw_data/roads", recursive = TRUE)
  # iterate over files and download
  drive_ls("lasse-frank-test-dir/tl_2021_us_primaryroads") |> 
    # filter name that end with .shp, .shx, .dbf, .prj
    filter(str_detect(name, ".shp$|.shx$|.dbf$|.prj$")) |>
    pull(name) |> 
    map(~ drive_download(paste0("lasse-frank-test-dir/tl_2021_us_primaryroads/", .x), 
                         path = paste0("../raw_data/roads/", .x), 
                         overwrite = TRUE))
}

