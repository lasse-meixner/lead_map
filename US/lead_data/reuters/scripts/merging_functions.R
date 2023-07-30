library(dplyr)
library(tidyverse)

# try to set to source files, then stopifnot
tryCatch(setwd("../scripts/source files/"), error = function(e) e$message)
stopifnot(endsWith(getwd(), "source files"))

## This script contains functions to merge the data from the individual states into one dataframe

# list of zip states
zip_states <- c("AL", "AZ", "IL", "NY", "RI", "LA", "NJ", "VT", "CA", "FL", "IO", "CT",
                "SC", "DC", "MI", "GA", "NM", "MO", "OK", "TX", "TN", "VA", "KS")

# list of tract states
tract_states <- c("OH", "PA", "CO", "MD", "MA", "MN", "NYC", "NC", "IN", "OR", "NH")

# list of variables for zip merge
zip_var_list <- c("state", "year", "zip", "BLL_geq_5", "BLL_geq_10", "tested")

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
  # check first if data exists in environment
  if (exists(str_to_lower(state_str)) == FALSE) {
    if (from_raw) {
      # try to source the file, otherwise throw error
      tryCatch(source(paste0("clean-", state_str, ".R")),
                error = function(e) {
                  print(paste0("Error loading ", state_str, " file: ", e$message))
                })
    } else {
      # check if the corresponding CSV file exists
      file_path <- paste0("../../processed_files/", str_to_lower(state_str), ".csv")
      if (file.exists(file_path)) {
        # read the CSV file and assign it to the global environment, and do not return anything
        data <- read_csv(file_path)
        assign(str_to_lower(state_str), data, envir = .GlobalEnv)
      } else {
        # try to source the file, otherwise throw error
        tryCatch(source(paste0("clean-", state_str, ".R")),
                  error = function(e) {
                    print(paste0("Error loading ", state_str, " file: ", e$message))
                  })
      }
    }
  } else {
    print(paste0(state_str, " already loaded"))
  }
}

# auxiliary function to merge SELECTED data that is in memory
merge_loaded_data <- function(states_list) {
  # get list of loaded data frames
  loaded_data <- mget(states_list, envir = .GlobalEnv)
  # select the zip vars for and combine the data frames into a single data frame
  combined_data <- loaded_data |>
    map(~ .x %>%
          select(all_of(zip_var_list)) %>%
          mutate(across(c(BLL_geq_5, BLL_geq_10, tested), as.character))) |>
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