# Scripts
This directory contains scripts for processing and merging the reuters data (BLLs in the US).


## Source files
This folder contains the code for reading in and cleaning the raw files we received from reuters. Raw files are stored in the project's associated Google Drive directory. For more info see ReadMe.md in the raw_data directory.

Each script pertains to one state, and can be run from scratch (i.e. each state file can be run independently, only requiring GDrive authentication). To authenticate, run `source("00_gdrive_utils.R)` in `scripts` and follow the instructions.

When run, they load the processed data as a tibble into the environment, as well as store a csv file in the processed_data directory.

All source files compute the following variables for each state: 
- state
- year
- zip (/or tract)
- tested
- BLL_geq_5
- BLL_geq_10 (if present)

Suppression for tested, BLL_geq_5, and BLL_geq_10 varies from state to state, and is encoded differently in the raw files. We do not want to get rid of the information contained in suppressed counts, even though they are a bit harder to handle.
The source scripts take care of this, by representing suppression consistently as follows: 

- "\<X" means the value is suppressed, and moreover a non-zero number lower than X.
  
In some states, the number of tested (and/or BLL_geq_5) is computed from suppressed variables themselves. In this case, the number is correspondingly represented as:

- "\<X&\>Y", where X is the upper bound of the suppressed range, and Y is the lower bound.

This representation of suppression across all states' data could allow us to parse and handle suppression consistently all the way down the pipeline.

## merging_functions.R
This file contains a range of low-level wrapper functions that help clean, process, and merge the data from individual states. 
It also contains two HIGH-level wrappers that call the entire cleaning and merging pipeline.

## Running source files:
Make sure to set the working directory to the `source_files` directory.
Call any script from there, e.g. `source("clean-IL.R")`

If you wish to run all states at once (though this should not ever be required, all data loading functions for analysis will automatically source the cleaning scripts if the processed file is not present), you can use the *run_all_states()* function after `source("../scripts/merging_functions.R")`.


## mergingstates.R

This file is a wrapper to merge all states into one tibble at the zip level that can be called using `source("../scripts/mergingstates.R")`.
The logic is implemented in the **merging_functions.R** script.
