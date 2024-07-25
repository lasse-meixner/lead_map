library(dplyr)
library(tidyverse)
library(jsonlite)

## This script contains functions to merge the data from the individual states into one dataframe

# get state metadata
find_and_set_directory("US")
metadata  <- fromJSON("metadata.json")
# list of zip and tract states
zip_states <- metadata$zip_states
tract_states <- metadata$tract_states

# list of variables except zip OR tract
var_list <- c("state", "year", "BLL_geq_5", "BLL_geq_10", "tested")

# auxiliary function to run all cleaning scripts
run_all_states <- function() {
  list.files() |>  map(source)
}

# function to load a SELECTED list of states in case they are not already in memory (either from disk, or from source)
load_states <- function(state_str_list, from_raw = FALSE) {
  # for each state in state_str_list, apply load_state function
  for (state_str in state_str_list) {
    load_state(state_str, from_raw)
  }
}

# auxiliary method for loading single state
load_state <- function(state_str, from_raw = FALSE) {
  if (from_raw) {
    print(paste0("Building ", state_str, " from raw_data"))
    # try to set wd to ../source files/ and then source the file script, otherwise catch error
      find_and_set_directory("US/lead_data/reuters/scripts/source files")
      tryCatch(source(paste0("clean-", toupper(state_str), ".R")),
                error = function(e) {
                  print(paste0("Error loading ", state_str, " file: ", e$message))
                }
              )
  } else {
    print(paste0("Loading ", state_str, " from processed_data"))
    # try to set wd to /processed_data/ and load file, otherwise catch error and rerun with from_raw = TRUE
    file_name <- paste0(str_to_lower(state_str), ".csv")
    find_and_set_directory("US/lead_data/reuters/processed_data")
    tryCatch(assign(str_to_lower(state_str), read_csv(file_name), envir = .GlobalEnv),
              error = function(e) {
                print(paste0("Error loading ", state_str, " file: ", e$message))
                load_state(state_str, from_raw = TRUE)
              }
            )
  }
}

# auxiliary function to merge SELECTED data that is in memory
merge_loaded_data <- function(states_list, level = "zip") {
  # get list of loaded data frames
  loaded_data <- mget(states_list[states_list %in% ls(envir = .GlobalEnv)], envir = .GlobalEnv)
  # print a warning for the missing states_list
  missing_states  <- setdiff(states_list, ls(envir = .GlobalEnv))
  if (length(missing_states) > 0) {
    print(paste0("Warning: ", missing_states, " not loaded and therefore not merged."))
  }
  # add BLL_geq_5 and BLL_geq_10 columns with NA values if they don't exist
  loaded_data <- lapply(loaded_data, function(x) {
    if (!("BLL_geq_5" %in% colnames(x))) {
      x$BLL_geq_5 <- NA
    }
    if (!("BLL_geq_10" %in% colnames(x))) {
      x$BLL_geq_10 <- NA
    }
    x
  })
  # select the zip vars for and combine the data frames into a single data frame
  combined_data <- loaded_data |>
    map(~ .x |> 
          select(all_of(c(var_list, {{level}}))) |> 
          mutate(across(c({{level}}, state, BLL_geq_5, BLL_geq_10, tested), as.character)) |>
          mutate(year = as.factor(year))) |> 
    bind_rows()
  # return the combined data frame
  combined_data
}

# HIGH-LEVEL wrapper to merge all ZIP states
merge_zip_states <- function(save = FALSE, from_raw = FALSE) {

  # load all zip states
  load_states(zip_states, from_raw)
  # get list of successfully loaded files (of 2 characters)
  loaded_files <- ls() |> str_subset("^.{2}$")
  # merge them
  merged_zip_states <- merge_loaded_data(loaded_files)
  # if save is TRUE, save to CSV in ../processed_data
  if (save == TRUE){
    write_csv(merged_zip_states, "../processed_data/merged_zip_states.csv")
  }
  merged_zip_states
}

# HIGH-LEVEL wrapper to merge all ZIP states #TODO: test this
merge_all_states <- function(save = FALSE, from_raw = FALSE) {
  # load all zip & tract states
  load_states(c(zip_states, tract_states), from_raw)
  # source tract-zip_code.R to aggregate tract_states to zip code level and remove tract state objects
  source("tract-zip_code.R")
  rm(list = tract_states) # -> use "_zip" aggregations
  # get list of successfully loaded files (of 2 characters, OR 2 characters + "_zip")
  loaded_files <- ls() |> str_subset("^.{2}$|^.{2}_zip$")
  # merge them
  merged_all_states <- merge_loaded_data(loaded_files)
  # if save is TRUE, save to CSV in ../processed_data
  if (save == TRUE){
    write_csv(merged_all_states, "../processed_data/merged_all_states.csv")
  }
  merged_all_states
}