library(googledrive)

drive_upload_w_tstamp <- function(tbl_name) {
    
    file_path <- paste0("../processed_data/", tbl_name, ".csv")
    
    # get date and time of when file in ../processed_data/tbl_name.csv was last modified
    file_mod_time <- file.info(file_path)$mtime

    drive_upload(
        media = file_path,
        path = paste0(
        "Lead_Map_Project/US/predictors/processed_data/",
        tbl_name,
        "_@",
        file_mod_time,
        ".csv"),
        overwrite = TRUE)
}