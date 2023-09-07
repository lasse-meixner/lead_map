# auxiliary script to find and set working directories flexibly from anywhere in "lead_map" directory

find_and_set_directory <- function(dir_name){
    # search path upwards for "lead_map" directory
    findLeadMapDirectory <- function() {
        target_directory_name <- "lead_map"
        current_directory <- getwd()

        while (basename(current_directory) != target_directory_name && current_directory != "/") {
            current_directory <- dirname(current_directory)
        }
    current_directory
    }
    # Call the function to find the 'lead_map' directory
    lead_map_directory <- findLeadMapDirectory()
    # search recursively downstream for "source files" directory using list.dirs
    source_files_directory <- list.dirs(lead_map_directory, recursive = TRUE, full.names = TRUE) %>% 
        .[grepl(dir_name, .)] %>% 
        .[1]
    # set working directory to source_files_directory
    setwd(source_files_directory)
}