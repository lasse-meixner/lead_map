library(googledrive)

drive_upload_w_tstamp <- function(tbl_name) {
    current_time  <- format(Sys.time(), "%Y-%m-%d_%H:%M:%S")
    drive_upload(
        media = paste0("../processed_data/", tbl_name, ".csv"),
        path = paste0(
        "Lead_Map_Project/US/processed_data/",
        tbl_name,
        "_@",
        current_time,
        ".csv"),
        overwrite = TRUE)
}