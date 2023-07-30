# Scripts
This directory contains scripts for processing the reuters data.


## Source files
This folder contains the code for reading in and cleaning the raw files we received from reuters. Raw files are stored in DropBox. You need the respective folders in your DropBox in order to run this. For more info see ReadMe.md in the raw_files directory.

Each script pertains to one state, and was modified to be able to run from scratch (i.e. each state file can be run independently).

When run, they load the processed data as a tibble into the environment, as well as store a csv file in the processed_data directory (we want to version control those, in case we make changes to the cleaning scripts).

## Running source files:
DropBox authentication will set the working directory into /raw_files. 
Call any script from there, e.g. `source("../scripts/source files/clean-IL.R")`

If you wish to run all states at once, you can source `source("../scripts/merging_functions.R")` and then use the *run_all_states()* function.

## merging_functions.R
This file contains a range of low-level wrapper functions that help clean, process, and merge the data from individual states. 
It also contains two HIGH-level wrappers that call the entire pipeline.

## mergingstates.R

:warning: *Not yet implemented*

This file is a wrapper to merge all states into one tibble at the zip level that can be called using `source("../scripts/mergingstates.R")`.
The logic is implemented in the **merging_functions.R** script.