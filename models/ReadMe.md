# Content overview
This directory contains exploratory notebooks and STAN models for fitting poisson regression models to censored data.

## Notebooks
The notebooks where constructed in the following order with the aim of iteratively building up the STAN model complexity.
- `Rhode_Island.qmd`
  Demonstrates fitting a model to uncensored ZIP level Rhode Island data (single X) & a model to artificially censored ZIP level Rhode Island data (single X).
- `poisson_regression_censoring.qmd`
  Demonstrates fitting a model to censored (55% of observations) TRACT level Massachusetts data, both for a single X as well as multiple X's.

## STAN models
These are STAN models used in the notebooks. They are listed in increasing order of complexity
- `poisson_single_X`
  STAN model for fitting a poisson regression with offset on data without censoring (single X)
- `poisson_single_X_suppression`
  Adds suppression to the poisson_single_X model
- `poisson_many_X_suppression`
  Generalizses the poisson_single_X_suppression model to multiple X's

## Other files
- `search_initialization_grid.R`
  Auxiliary R script for grid searching over intialization values.