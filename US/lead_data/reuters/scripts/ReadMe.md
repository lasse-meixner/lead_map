# Scripts
This directory contains scripts for processing the reuters data.

## Source files
This folder contains the code for reading in and cleaning the raw files we received from reuters. Raw files are stored in DropBox. You need the respective folders in your DropBox in order to run this. For more info see ReadMe.md in the raw_files directory.

Each script pertains to one state, and was modified to be able to run from scratch (i.e. each state file can be run independently).

When run, they load the processed data as a tibble into the environment, as well as store a csv file in the processed_data directory (we want to version control those, in case we make changes to the cleaning scripts).

## mergingstates.R

:warning: *Not yet implemented*

This file is a wrapper to merge all states into one tibble at the zip level. 
It tries grabbing the processed data from the processed_data directory, and if it doesn't find it, it runs the respective state's cleaning file.

When required, it performs some additional pre-merging steps, such as aggreggating from tracts to ZIPs.

The resulting tibbles are then merged into one. The resulting tibble is stored in the processed_data directory.