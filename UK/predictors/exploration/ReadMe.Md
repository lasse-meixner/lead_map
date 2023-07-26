# This folder is for exploratory data analysis.

If you create notebooks (prefereably Rmd or ipython), to explore UK predictor data, and have time to comment and document your findings so that they are interesting for other to read, please put them here, as well as miscellaneous material required to run them.

# predictor_map_app.py
This runs a local web app for exploration of the predictor dataset.
## Instructions to run predictor_map_app.py
Install [miniconda](https://docs.conda.io/en/latest/miniconda.html) if you don't already have it. Then:
1. Install the required packages using conda into a new environment using `conda env create -f environment.yml`
2. Activate the new environment using `conda activate lead_map`
3. Run the app using `python predictor_map_app.py`