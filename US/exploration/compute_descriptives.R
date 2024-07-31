# Script that computes relevant descriptives and summary statistics for each state's data

# imports
library(tidyverse)
library(jsonlite)
library(modelsummary)
library(kableExtra)
source("../../init.R")

### metadata

# get metadata from ~US root
metadata  <- fromJSON("../metadata.json")
# extract required metadata (lists)
zip_states <- metadata$zip_states
tract_states <- metadata$tract_states
id_variables <- metadata$id_variables
ratio_variables <- metadata$proportion_variables
count_variables <- metadata$count_variables

# run analytics
source("load_and_preprocess.R") # -> single_state_zip, single_state_tract

# auxiliary function to load/accept data
take_state_data <- function(state_name, year = NULL) {
  if (is.character(state_name)) { # accepts either str passed to the loading pipeline or an already loaded df
    # remove obj if present (note: bug proof but is this desireable?)
    if (exists(str_to_lower(state_name))) {
      rm(list = str_to_lower(state_name), envir = .GlobalEnv)
    }
    if (state_name %in% zip_states) {
      return(single_state_zip(state_name, filter_year = year)) # from load_and_preprocess.R
    } else if (state_name %in% tract_states) {
      return(single_state_tract(state_name, filter_year = year)) # from load_and_preprocess.R
    } else {
      stop(sprintf("State %s is not in list of states", state_name))
    }
  } else if (is.data.frame(state_name)) {
    return(state_name)
  } else {
    stop("state_name must be a string or a data frame")
  }
}

# data summary function
data_summary <- function(state_name, year = 2010){
    # load data from string or accept already stored dataframe
    state_data <- take_state_data(state_name, year)

    # Check for the presence of BLL_geq_5 and BLL_geq_10 variables
    has_bll_geq_5 <- "BLL_geq_5" %in% names(state_data)
    has_bll_geq_10 <- "BLL_geq_10" %in% names(state_data)

    # create lead summary statistics table
    lead_summary <- state_data |>
        group_by(year) |>
        summarise(
            n_obs = n(),
            lead_cens_5 = if(has_bll_geq_5) sum(BLL_geq_5_suppressed, na.rm = TRUE) else NA_integer_,
            lead_nocens_5 = if(has_bll_geq_5) sum(!BLL_geq_5_suppressed, na.rm = TRUE) else NA_integer_,
            lead_censR_5 = if(has_bll_geq_5) lead_cens_5 / n_obs else NA_real_,
            lead_cens_10 = if(has_bll_geq_10) sum(BLL_geq_10_suppressed, na.rm = TRUE) else NA_integer_,
            lead_nocens_10 = if(has_bll_geq_10) sum(!BLL_geq_10_suppressed, na.rm = TRUE) else NA_integer_,
            lead_censR_10 = if(has_bll_geq_10) lead_cens_10 / n_obs else NA_real_,
            test_cens = sum(tested_suppressed, na.rm = TRUE),
            test_censR = test_cens / n_obs,
            sup_threshold_5 = if("ell_5" %in% names(state_data)) max(state_data$ell_5, na.rm = TRUE) else NA,
            sup_threshold_10 = if("ell_10" %in% names(state_data)) max(state_data$ell_10, na.rm = TRUE) else NA,
            median_lead_5 = if(has_bll_geq_5) median(BLL_geq_5, na.rm = TRUE) else NA_real_,
            q75_lead_5 = if(has_bll_geq_5) quantile(BLL_geq_5, 0.75, na.rm = TRUE) else NA_real_,
            max_lead_5 = if(has_bll_geq_5) max(BLL_geq_5, na.rm = TRUE) else NA_real_,
            median_lead_10 = if(has_bll_geq_10) median(BLL_geq_10, na.rm = TRUE) else NA_real_,
            q75_lead_10 = if(has_bll_geq_10) quantile(BLL_geq_10, 0.75, na.rm = TRUE) else NA_real_,
            max_lead_10 = if(has_bll_geq_10) max(BLL_geq_10, na.rm = TRUE) else NA_real_
        ) |>
        # drop if all values in a column are NA
        select(where(~!all(is.na(.))))
    
    # predictor overview
    pred_summary <- datasummary_skim(state_data, type = "numeric", histogram = TRUE)
    
    # get density of non-suppressed BLL values for BLL_geq_5 and BLL_geq_10 if they exist
    lead_distribution <- list()
    if (has_bll_geq_5) {
        lead_distribution[[1]] <- state_data |>
            filter(!BLL_geq_5_suppressed) |>
            ggplot(aes(x = BLL_geq_5)) +
            geom_histogram(binwidth = 1) +
            labs(title = "Distribution of non-censored BLL_geq_5 values")
    }
    if (has_bll_geq_10) {
        lead_distribution[[2]] <- state_data |>
            filter(!BLL_geq_10_suppressed) |>
            ggplot(aes(x = BLL_geq_10)) +
            geom_histogram(binwidth = 1) +
            labs(title = "Distribution of non-censored BLL_geq_10 values")
    }

    # get correlation plot of predictors
    pred_correlation <- get_corplot(state_data) # defined below

    return(list(lead_summary, pred_summary, lead_distribution, pred_correlation))
}


lead_count_model_summary <- function(state_name, year = 2010, outcome = "BLL_geq_5", plot=TRUE){
    # load data from string or accept already stored dataframe
    state_data <- take_state_data(state_name, year)

    require(cmdstanr)
    require(bayesplot)

    # load stan model
    find_and_set_directory("lead_map/models")
    stan_model <- cmdstan_model("poisson_many_X_suppression.stan")

    # create stan data with all features based on outcome variable
    if (outcome == "BLL_geq_5") {
      stan_data_many_X <- list(
        N_obs = state_data |> filter(!BLL_geq_5_suppressed) |> count() |> pull(n),
        N_cens = state_data |> filter(BLL_geq_5_suppressed) |> count() |> pull(n),
        K = length(features),
        y_obs = state_data |> filter(!BLL_geq_5_suppressed) |> pull(BLL_geq_5) |> as.numeric(),
        x_obs = state_data |> filter(!BLL_geq_5_suppressed) |> select(all_of(features)),
        x_cens = state_data |> filter(BLL_geq_5_suppressed) |> select(all_of(features)),
        kids_obs = state_data |> filter(!BLL_geq_5_suppressed) |> pull(under_yo5_pplE),
        kids_cens = state_data |> filter(BLL_geq_5_suppressed) |> pull(under_yo5_pplE),
        ell = max(state_data$ell_5, na.rm = TRUE) |> as.integer(),
        zero_sup = all(state_data$zero_sup_BLL_5, na.rm = TRUE) |> as.integer()
      )
    } else if (outcome == "BLL_geq_10") {
      stan_data_many_X <- list(
        N_obs = state_data |> filter(!BLL_geq_10_suppressed) |> count() |> pull(n),
        N_cens = state_data |> filter(BLL_geq_10_suppressed) |> count() |> pull(n),
        K = length(features),
        y_obs = state_data |> filter(!BLL_geq_10_suppressed) |> pull(BLL_geq_10) |> as.numeric(),
        x_obs = state_data |> filter(!BLL_geq_10_suppressed) |> select(all_of(features)),
        x_cens = state_data |> filter(BLL_geq_10_suppressed) |> select(all_of(features)),
        kids_obs = state_data |> filter(!BLL_geq_10_suppressed) |> pull(under_yo5_pplE),
        kids_cens = state_data |> filter(BLL_geq_10_suppressed) |> pull(under_yo5_pplE),
        ell = max(state_data$ell_10, na.rm = TRUE) |> as.integer(),
        zero_sup = all(state_data$zero_sup_BLL_10, na.rm = TRUE) |> as.integer()
      )
    } else {
      stop("Outcome must be either BLL_geq_5 or BLL_geq_10")
    }

    # sample
    fit <- stan_model$sample(
      data = stan_data_many_X,
      seed = 1234,
      chains = 4, 
      parallel_chains = 4,
      refresh = NULL,
      show_messages = FALSE
    )

    # return summary
    fit_summary <- fit$summary() |> 
    # rename all of the beta[j] by their feature names
    mutate(variable = ifelse(str_detect(variable, "beta"), paste0(features[as.numeric(str_extract(variable, "[0-9]+"))]), variable)) |>
    # unselect all variables that contain tilde
    filter(!str_detect(variable, "tilde") & !str_detect(variable, "thinned") & !str_detect(variable, "star"))

    if (plot){
      coef_plot <- fit$draws(format = "draws_df") |>
        rename_with(~features[as.numeric(str_extract(., "[0-9]+"))], starts_with("beta")) |>
        select(features) |>
        mcmc_areas(prob = 0.8) +
        theme_minimal()
    }

    list(table = fit_summary, plot = coef_plot)
}

test_count_model_summary <- function(state_name, year = 2010, plot=TRUE){
    state_data <- take_state_data(state_name, year)

    require(cmdstanr)
    require(bayesplot)
    
    # load stan model
    find_and_set_directory("lead_map/models")
    stan_model <- cmdstan_model("poisson_many_X_suppression.stan")

    # standardize pediatricians per 100k and add to features
    state_data <- state_data |>
        mutate(ped_per_100k = (ped_per_100k - mean(ped_per_100k))/sd(ped_per_100k))
    features_for_testing = c(features, c("ped_per_100k"))

    # create stan data for logistic regression
    stan_data_many_X <- list(
      N_obs = state_data |> filter(!tested_suppressed) |> count() |> pull(n),
      N_cens = state_data |> filter(tested_suppressed) |> count() |> pull(n),
      K = length(features_for_testing),
      y_obs = state_data |> filter(!tested_suppressed) |> pull(tested),
      x_obs = state_data |> filter(!tested_suppressed) |> select(all_of(features_for_testing)),
      x_cens = state_data |> filter(tested_suppressed) |> select(all_of(features_for_testing)),
      kids_obs = state_data |> filter(!tested_suppressed) |> pull(under_yo5_pplE),
      kids_cens = state_data |> filter(tested_suppressed) |> pull(under_yo5_pplE),
      ell = max(state_data$tested_ell, na.rm = TRUE) |> as.integer(),
      zero_sup = all(state_data$zero_sup_tested, na.rm = TRUE) |> as.integer()
    )

    # sample
    fit <- stan_model$sample(
      data = stan_data_many_X,
      seed = 1234,
      chains = 4, 
      parallel_chains = 4,
      refresh = NULL,
      show_messages = FALSE
    )

    # return summary
    fit_summary <- fit$summary() |> 
      # rename all of the beta[j] by their feature names
      mutate(variable = ifelse(str_detect(variable, "beta"), paste0(features[as.numeric(str_extract(variable, "[0-9]+"))]), variable)) |>
      # unselect all variables that contain tilde
      filter(!str_detect(variable, "tilde") & !str_detect(variable, "thinned") & !str_detect(variable, "star"))
    
    if (plot){
      coef_plot <- fit$draws(format = "draws_df") |>
        rename_with(~features_for_testing[as.numeric(str_extract(., "[0-9]+"))], starts_with("beta")) |>
        select(features_for_testing) |>
        mcmc_areas(prob = 0.8) +
        theme_minimal()
    }

    list(table = fit_summary, plot = coef_plot)
}

### Data plotting

# Correlation plot
get_corplot <- function(state_data, features = c("median_annual_incomeE","house_price_medianE","poor_fam_propE","black_ppl_propE", "bp_pre_1959E_prop", "svi_socioeconomic_pctile")){
  # use geomtile to plot correlation matrix
  state_data |> 
    select(all_of(features)) |> 
    cor() |> 
    melt() |>
    ggplot(aes(Var1, Var2, fill = value)) +
    geom_tile() +
    geom_text(aes(label = sprintf("%.2f", value)), color = "black", size = 3) +
    scale_fill_gradient2(low = "blue", high = "red", mid = "white", midpoint = 0, limit = c(-1, 1)) +
    theme_minimal() + 
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    coord_fixed() +
    # hide Var1 Var2 labels
    theme(axis.title.x = element_blank(),
          axis.title.y = element_blank())
}

# Get spread of (normalized features) in the data
get_spread_plot <- function(state_data, features = c("median_annual_incomeE","house_price_medianE","poor_fam_propE","black_ppl_propE", "bp_pre_1959E_prop", "svi_socioeconomic_pctile")){
    # plot in grid, 3 cols
    state_data |> 
        select(all_of(features)) |> 
        gather() |> 
        ggplot(aes(value)) +
        geom_histogram(bins = 30, alpha = 0.5) +
        facet_wrap(~key, scales = "free") +
        theme_minimal()
}