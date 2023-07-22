# DROPBOX authentication to access parked files (for which download links were no longer available).
# Since these are already saved remotely and not modified, we do not version control them. CSV files are read using the drop_read_csv wrapper and saved in temporary directories.
# This option does not exist for other file types, so those are downloaded to ../raw_data prior to being read into memory.

library(rdrop2)
library(purrr)

drop_box_base_url <- "/downloading_cleaning_mapping_predictors_data_raw/uk/"
drop_auth(new_user = TRUE) # this should prompt authentication in the browser

drop_get_from_root <- function(path) {
    # check if file lies already in ../raw_data
    if (file.exists(paste0("../raw_data/", path))) {
        return()
    }
    # if not, download from dropbox
    else {
        drop_download(paste0(drop_box_base_url, path), local_path = paste0("../raw_data/",path), overwrite = TRUE)
    }
}

# write function to read all files in folder:

drop_get_folder <- function(path) {
    # check if directory already exists in ../raw_data
    if (dir.exists(paste0("../raw_data/", path))) {
        return("Directory already exists")
    }
    # if not, download from dropbox by iterating over files in directory
    else {
        drop_dir(paste0(drop_box_base_url, path))$name %>% 
            map(~ drop_get_from_root(paste0(path, .x)))
    }
}