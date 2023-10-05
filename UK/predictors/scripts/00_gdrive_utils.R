# Some utility functions to access parked files (for which download links were no longer available) on the project GDrive directory.
# Since these are already saved remotely and not modified, we do not version control them. CSV files are read directly into memtory, others are saved in raw_data (see ReadMe there for more information).

library(googledrive)
library(purrr)
require(tidyverse)

# function to check if file has been downloaded already (would only be used in non-csv case), and download otherwise
gdrive_get_file <- function(file_name) {
    # download if file_name does not already exists in "../raw_data/"
    if (!file.exists(paste0("../raw_data/", file_name))) {
        print(paste0("Downloading file: ", file_name))
        drive_download(
            file = paste0("Lead_Map_Project/UK/predictors/raw_data/", file_name), 
            path = paste0("../raw_data/", file_name), 
            overwrite = TRUE)
    }
    # if not, abort
    else {
        print(paste0("File ", file_name, " already exists."))
        return()
    }
}

# function to download all files in folder:

gdrive_get_folder <- function(path, filetypes = ".csv$|.shp$|.shx$|.dbf$|.prj$") {
    # create directory if it does not exist, using the last part of the path as the folder name
    folder_name  <- strsplit(path, "/")[[1]][length(strsplit(path, "/")[[1]])]
    if (!dir.exists(paste0("../raw_data/", folder_name))) {
        dir.create(paste0("../raw_data/", folder_name))
    }
    # if not, abort
    else {
        print("Folder already exists, skipping download.")
    }
    drive_ls(path) |>
        filter(str_detect(name, filetypes)) |>
        pull(name) |>
        map(~ drive_download(paste0(path, "/", .x), 
                             path = paste0("../raw_data/", folder_name, "/", .x), 
                             overwrite = TRUE))
}

gdrive_upload_w_tstamp <- function(tbl_name) {
    
    file_path <- paste0("../processed_data/", tbl_name, ".csv")
    
    # get date and time of when file in ../processed_data/tbl_name.csv was last modified
    file_mod_time <- file.info(file_path)$mtime

    drive_upload(
        media = file_path,
        path = paste0(
        "Lead_Map_Project/UK/predictors/processed_data/",
        tbl_name,
        "_@",
        file_mod_time,
        ".csv"),
        overwrite = TRUE)
}
