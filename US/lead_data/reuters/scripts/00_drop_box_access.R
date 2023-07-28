# DROPBOX authentication to access parked files (for which download links were no longer available).
# Since these are already saved remotely and not modified, we do not version control them. 

library(rdrop2)
library(purrr)

reuters_drop_box_base_url <- "/reuters/Raw Files/"
drop_auth(new_user = TRUE) # this should prompt authentication in the browser

# function to download file:

drop_get_from_root <- function(path) {
    # check if file lies already in ../raw_data
    if (file.exists(paste0("../raw_files/", path))) {
        return()
    }
    # if not, download from dropbox
    else {
        drop_download(paste0(reuters_drop_box_base_url, path), local_path = paste0("../raw_files/"), overwrite = TRUE)
    }
}

# function to download all files in folder:

drop_get_folder <- function(path) {
    # check if directory already exists in ../raw_data
    if (dir.exists(paste0("../raw_files/", path))) {
        return("Directory already exists")
    }
    # if not, download from dropbox by iterating over files in directory
    else {
        drop_dir(paste0(reuters_drop_box_base_url, path))$name %>% 
            map(~ drop_get_from_root(paste0(path, .x)))
    }
}