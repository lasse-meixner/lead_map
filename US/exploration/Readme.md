# This folder is for exploratory data analysis on data from US states.

## `predictor_map_app.py`
This runs a local web app for exploration of the predictor dataset.
### Instructions to run predictor_map_app.py
Install [miniconda](https://docs.conda.io/en/latest/miniconda.html) if you don't already have it. Then:
1. If you haven't already (can check with `conda env list`), install the required packages using conda into a new environment using `conda env create -f environment.yml`
2. Activate the new environment using `conda activate lead_map`
3. Run the app using `python predictor_map_app.py`

The app depends on a shapefile file from the `raw_data/` directory that can be created by sourcing `get_tract_geometries.R`. If this file is missing, the app will throw an appropriate error message during launch.

## `compute_descriptives.R`
TODO: