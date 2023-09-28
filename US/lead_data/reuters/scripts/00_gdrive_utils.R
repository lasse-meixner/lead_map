library(googledrive)
library(purrr)
require(tidyverse)

# function to download all files in folder:

gdrive_get_folder <- function(path, filetypes = ".csv$|.shp$|.shx$|.dbf$|.prj$") {
    # create directory if it does not exist, using the last part of the path as the folder name
    folder_name  <- strsplit(path, "/")[[1]][length(strsplit(path, "/")[[1]])]
    if (!dir.exists(paste0("../raw_data/", folder_name))) {
        dir.create(paste0("../raw_data/", folder_name))
    }
    # if not, abort
    else {
        stop("Folder already exists")
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
        "Lead_Map_Project/US/processed_data/",
        tbl_name,
        "_@",
        file_mod_time,
        ".csv"),
        overwrite = TRUE)
}