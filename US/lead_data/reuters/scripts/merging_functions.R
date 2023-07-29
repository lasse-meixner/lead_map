library(dplyr)
library(tidyverse)

setwd("../scripts/source files/")

## This script contains functions to merge the data from the individual states into one dataframe

# list of zip states
zip_states <- c("AL", "AZ", "IL", "NY", "RI", "LA", "NJ", "VT", "CA", "FL", "IO", "CT",
                "SC", "DC", "MI", "GA", "NM", "MO", "OK", "TX", "TN", "VA", "KS")

# list of tract states
tract_states <- c("OH", "PA", "CO", "MD", "MA", "MN", "NYC", "NC", "IN", "OR", "NH")

# auxiliary function to load a list of states in case they are not already in memory
load_states <- function(state_str_list) {
  # for each state in state_str_list, apply load_state function
  state_str_list |> map(load_state)
}

# auxiliary method for single state
load_state <- function(state_str) {
  # check if get(state_str) throws an error
  if (exists(str_to_lower(state_str))  == FALSE) {
  # try to source the file, otherwise throw error
    tryCatch(source(paste0("clean-", state_str, ".R")),
              error = function(e) {
                print(paste0("Error loading ", state_str, " file: ", e$message))
              })
  } else {
    print(paste0(state_str, " already loaded"))
  }
}

# function to merge all ZIP states
merge_zip_states <- function(save = FALSE) {

  # load all zip states
  load_states(zip_states)
  # get list of successfully loaded files (of 2 characters)
  loaded_files <- ls() |> str_subset("^.{2}$")
  # merge them
  merged_zip_states <- loaded_files |>
                          map(get) |> 
                          reduce(full_join, by = c("zip", "year"))
  # if save is TRUE, save to CSV in ../processed_data
  if (save == TRUE){
    write_csv(merged_zip_states, "../processed_data/merged_zip_states.csv")
  }
  merged_zip_states
}

# function to merge all states (zip & tract)
merge_all_states <- function(save = FALSE) {
  # load all zip & tract states
  load_states(c(zip_states, tract_states))
  # source tract-zip_code.R to aggregate tract_states to zip code level and remove tract state objects
  source("tract-zip_code.R")
  rm(list = tract_states) # -> use "_zip" aggregations
  # get list of successfully loaded files (of 2 characters, OR 2 characters + "_zip")
  loaded_files <- ls() |> str_subset("^.{2}$|^.{2}_zip$")
  # merge them
  merged_all_states <- loaded_files |>
                          map(get) |> 
                          reduce(full_join, by = c("zip", "year"))
  # if save is TRUE, save to CSV in ../processed_data
  if (save == TRUE){
    write_csv(merged_all_states, "../processed_data/merged_all_states.csv")
  }
  merged_all_states
}