# Content overview
This directory contains exploratory notebooks and STAN models for fitting poisson regression models to censored data.

## Notebooks
The notebooks were written in the following order (iteratively building up the STAN model complexity) as I was trying to make sense of our pogit with censoring. 
- `Rhode_Island.qmd`
  Demonstrates fitting a model to uncensored ZIP level Rhode Island data (single X) & a model to artificially censored ZIP level Rhode Island data (single X).
- `poisson_regression_censoring.qmd`
  Demonstrates fitting a model to censored (55% of observations) TRACT level Massachusetts data, both for a single X as well as multiple X's.
- `poisson_thinned_exclusion.qmd`
  Demonstrates fitting our thinned poisson on some tract data. Encountered identification issues, especially when adding X's to the logit side.
- `poisson_thinned_exclusion_ZIPS.qmd`
  Same as above, but for ZIP states.
- `poisson_thinned_exclusion_v2.qmd`
  Second round of analysis after spending some time going back to simulations and rethinking potential sources of identification issues.


## STAN models
These are the main STAN models used in the notebooks.
- `poisson_single_X`
  STAN model for fitting a poisson regression with offset on data without censoring (single X)
- `poisson_single_X_suppression`
  Adds suppression to the poisson_single_X model
- `poisson_many_X_suppression`
  Generalizes the poisson_single_X_suppression model to multiple X's
- `poisson_thinned_exclusion_x_logit_subset`
  Allows to put several X's also into the logit side.

## Other files
- `search_initialization_grid.R`
  Auxiliary R script for grid searching over intialization values. UPDATE: Ended up being redundant, an issue I thought due to initialization was actually a bug in the model code.