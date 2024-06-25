# auxiliary init file for model analytics
require(bayesplot)
require(dplyr)
require(ggplot2)


### data preprocessing functions
zip_info_vars <- c("zip","STATE_ABBR")
tract_info_vars <- c("TRACT","STATE_NAME","COUNTY") 
offset_var <- c("under_yo5_pplE","ped_per_100k")
features <- c("median_annual_incomeE","house_price_medianE","poor_fam_propE","black_ppl_propE", "bp_pre_1959E_prop", "svi_socioeconomic_pctile")

preprocess_pred_data <- function(zip_or_tract_data, info_vars){
    #' selects relevant PREDICTOR variables, drops NAs and scales data
    #' 
    zip_or_tract_data |> select(all_of(c(features, offset_var, info_vars))) |>
    distinct() |>
    # drop NAs
    drop_na() |>
    # drop if poor_fam_propE==0 (missing value in census API)
    filter(poor_fam_propE!=0) |>
    # standardize all features
    mutate(across(all_of(features), ~(. - mean(.))/sd(.)))
}

preprocess_lead_data <- function(lead_data){
    #' preprocesses lead data
    lead_data |> 
        # create indicator if starts with "<" (supressed value) for both tested and BLL_geq_5
        mutate(tested_suppressed = str_detect(tested, "<"),
               BLL_geq_5_suppressed = str_detect(BLL_geq_5, "<")) |>
        # remove "<" from tested and BLL_geq_5
        mutate(tested = str_remove(tested, "<"),
               BLL_geq_5 = str_remove(BLL_geq_5, "<")) |>
        # convert to numeric
        mutate(tested = as.numeric(tested),
               BLL_geq_5 = as.numeric(BLL_geq_5)) |>
        # add state level censoring threshold
        group_by(state) |>
        # get minimum of BLL_geq_5 that is greater than 0
        mutate(ell = min(BLL_geq_5[BLL_geq_5>0], na.rm = TRUE) - 1) |> #Note: I take -1 here, so "<6" will be a 5
        ungroup()
}

final_checks  <- function(merged_data, drop="BLL_geq_10"){
    #' implements final data checks and drops unused outcome column
    # get outcome of interest based on drop (pick the other respectively)
    outcome_of_interest <- ifelse(drop == "BLL_geq_10", "BLL_geq_5", "BLL_geq_10")
    merged_data |>
        filter(under_yo5_pplE>=tested,
               tested>0) |> 
        select(-all_of(drop)) |>
        # drop if NA in any of offset_var, features or drop
        drop_na(any_of(c(features, offset_var, outcome_of_interest)))
}

### functions for STAN model fit instances
get_coefficients <- function(fit){
  fit$summary() |> 
  # rename all of the beta[j] by their feature names
  mutate(variable = ifelse(str_detect(variable, "beta"), paste0(features[as.numeric(str_extract(variable, "[0-9]+"))]), variable)) |>
  # unselect all variables that contain pi_
  filter(!str_detect(variable, "pi_"))
}

plot_betas <- function(fit, title = "Posterior distributions") {
    draws <- fit$draws(format = "draws_df") |>
        # rename column names beta[j] by their feature names
        rename_with(~ (features[as.numeric(str_extract(., "[0-9]+"))]), starts_with("beta"))

    mcmc_areas(draws %>% select(features), prob = 0.8) +
        ggtitle(title)
}

### function for data preparation for STAN model with x's in logit
build_stan_vector_logit_2 <-  function(merged_data, pr_var = 1, logit_features = c("median_annual_incomeE", "poor_fam_propE")){
    list(
        N_obs = merged_data |> filter(!BLL_geq_5_suppressed) |> count() |> pull(n),
        N_cens = merged_data |> filter(BLL_geq_5_suppressed) |> count() |> pull(n),
        K = length(features),
        L = 2, # number of features in logit
        y_obs = merged_data |> filter(!BLL_geq_5_suppressed) |> pull(BLL_geq_5),
        x_obs = merged_data |> filter(!BLL_geq_5_suppressed) |> select(all_of(features)) |> as.matrix(),
        x_cens = merged_data |> filter(BLL_geq_5_suppressed) |> select(all_of(features)) |> as.matrix(),
        w_obs = merged_data |> filter(!BLL_geq_5_suppressed) |> select(logit_features) |> as.matrix(),
        w_cens = merged_data |> filter(BLL_geq_5_suppressed) |> select(logit_features) |> as.matrix(),
        z_obs = merged_data |> filter(!BLL_geq_5_suppressed) |> pull(ped_per_100k),
        z_cens = merged_data |> filter(BLL_geq_5_suppressed) |> pull(ped_per_100k),
        kids_obs = merged_data |> filter(!BLL_geq_5_suppressed) |> pull(under_yo5_pplE),
        kids_cens = merged_data |> filter(BLL_geq_5_suppressed) |> pull(under_yo5_pplE),
        # get suppression bound 
        ell = merged_data |> filter(BLL_geq_5_suppressed) |> pull(ell),
        nhanes_prior_var = pr_var
    )
}