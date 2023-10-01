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
tract_states <- c("OH", "PA", "CO", "MD", "MA", "MN", "NYC", "NC", "IND", "OR", "NH", "WI")

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
  # check first if data exists in environment
  if (exists(str_to_lower(state_str)) == FALSE) {
    if (from_raw) {
      print(paste0("Building ", state_str, " from raw_data"))
      # try to set wd to ../../raw_data and then source the file script, otherwise catch error
        tryCatch(setwd("../../raw_data"), error = function(e) e$message)
        tryCatch(source(paste0("../scripts/source files/clean-", state_str, ".R")),
                  error = function(e) {
                    print(paste0("Error loading ", state_str, " file: ", e$message))
                  })
    } else {
      print(paste0("Loading ", state_str, " from processed_data"))
      # check if the corresponding CSV file exists
      file_path <- paste0("../../processed_data/", str_to_lower(state_str), ".csv")
      if (file.exists(file_path)) {
        # read the CSV file and assign it to the global environment, and do not return anything
        data <- read_csv(file_path)
        assign(str_to_lower(state_str), data, envir = .GlobalEnv)
      } else { # if the from_disk option fails, try to source anyway:
        print(paste0("No processed file for ", state_str, " found, loading from source files"))
        # try to set wd to ../../raw_data and then source the file script, otherwise catch error
        tryCatch(setwd("../../raw_data"), error = function(e) e$message)
        tryCatch(source(paste0("../scripts/source files/clean-", state_str, ".R")),
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
merge_loaded_data <- function(states_list, level = "zip") {
  # get list of loaded data frames
  loaded_data <- mget(states_list, envir = .GlobalEnv)
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