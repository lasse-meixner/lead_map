# auxiliary functions to load and preprocess data

require(dplyr)
require(ggplot2)
library(reshape2)

# requires root/init.R

# import lead data
find_and_set_directory("US/lead_data/reuters/scripts")
source("00_merging_functions.R")

# import pred data: check if tract_data and zip_data are loaded, otherwise load them
if (!exists("tract_data") || !exists("zip_data")) {
  find_and_set_directory("US/predictors/processed_data")
  tract_data  <- read_csv("final_tract.csv")
  zip_data  <- read_csv("final_zip.csv")
}

### data preprocessing functions
zip_info_vars <- c("zip","STATE_ABBR")
tract_info_vars <- c("TRACT","STATE_NAME","COUNTY") 
offset_var <- c("under_yo5_pplE","ped_per_100k")
features <- c("median_annual_incomeE","house_price_medianE","poor_fam_propE","black_ppl_propE", "bp_pre_1959E_prop", "svi_socioeconomic_pctile")


# HIGH LEVEL loader for tracts
single_state_tract <- function(state_name, drop_outcome = c(), pred_preprocess_func = NULL, filter_year = NULL){
    # load and assign the state data
    load_state(state_name, from_raw = FALSE) # from 00_merging_functions.R 
    state_data <- get(str_to_lower(state_name)) # (overwritten after merge)
    
    # Apply conditional filtering based on filter_year
    if (!is.null(filter_year)) {
        state_data <- state_data |> filter(year == filter_year)
    }
    
    # preprocess lead data
    state_lead <- state_data |>
        mutate(tract = as.character(tract)) |>
        preprocess_lead_data()
    
    # preprocess pred data
    state_pred <- tract_data |> 
      filter(STATE_ABBR == state_name) |> 
      preprocess_pred_data(info_vars = tract_info_vars, additional_preprocess = pred_preprocess_func)

    # merge
    state_merged <- state_lead |> 
        left_join(state_pred, by = c("tract" = "TRACT")) |> 
        final_checks(drop=drop_outcome)

    # assign merged data to state name (for convenience of further analysis)
    assign(str_to_lower(state_name), state_merged, envir = .GlobalEnv)

    return(state_merged)
}

# HIGH LEVEL loader for zips
single_state_zip <- function(state_name, drop_outcome = c(), pred_preprocess_func = NULL, filter_year = NULL){
    # load and assign the state data
    load_state(state_name, from_raw = FALSE) # from 00_merging_functions.R 
    state_data <- get(str_to_lower(state_name)) # (overwritten after merge)
    
    # Apply conditional filtering based on filter_year
    if (!is.null(filter_year)) {
        state_data <- filter(state_data, year == filter_year)
    }
    
    # preprocess lead data
    state_lead <- state_data |>
        # ensure zip is chr
        mutate(zip = as.character(zip)) |>
        # preprocess lead data
        preprocess_lead_data()
    
    # preprocess pred data
    state_pred <- zip_data |> 
        filter(STATE_ABBR == state_name) |> 
        preprocess_pred_data(info_vars = zip_info_vars, additional_preprocess = pred_preprocess_func)

    # merge
    state_merged <- state_lead |> 
        left_join(state_pred, by = "zip") |> 
        final_checks(drop=drop_outcome)
    
    # assign merged data to state name (for convenience of further analysis)
    assign(str_to_lower(state_name), state_merged, envir = .GlobalEnv)

    return(state_merged)
}

### auxiliary functions for high level wrapper above

preprocess_pred_data <- function(zip_or_tract_data, info_vars, additional_preprocess = NULL){
    #' selects relevant PREDICTOR variables, drops NAs and scales data
    #' 
    pp_data <- zip_or_tract_data |> 
        select(all_of(c(features, offset_var, info_vars))) |>
        distinct() |>
        # drop NAs
        drop_na() |>
        # drop if poor_fam_propE==0 (missing value in census API)
        filter(poor_fam_propE!=0)

    # additional preprocessing
    if (!is.null(additional_preprocess) && is.function(additional_preprocess)) {
        pp_data <- additional_preprocess(pp_data)
    }

    # find all additional features added by additional_preprocess (must contain any of features in the name)
    additional_features <- pp_data |> select(-all_of(c(features, offset_var, info_vars))) |> names() |> str_subset(paste0(features, collapse = "|"))
    print(paste("Additional features added:", additional_features))

    # standardize all features
    pp_data |>
        mutate(across(all_of(c(features, additional_features)), ~(. - mean(.))/sd(.)))
}

preprocess_lead_data <- function(lead_data){
    #' preprocesses lead data
    
    # Dynamically check for the presence of BLL_geq_5 and BLL_geq_10
    has_bll_geq_5 <- "BLL_geq_5" %in% names(lead_data)
    has_bll_geq_10 <- "BLL_geq_10" %in% names(lead_data)
    
    # Combine all mutate operations and process BLL_geq_5 and BLL_geq_10 if present
    lead_data <- lead_data |> 
        mutate(tested_suppressed = str_detect(tested, "<"),
               tested = as.numeric(str_remove(tested, "<")),
               BLL_geq_5_suppressed = if(has_bll_geq_5) str_detect(BLL_geq_5, "<") else NA,
               BLL_geq_5 = if(has_bll_geq_5) as.numeric(str_remove(BLL_geq_5, "<")) else NA,
               BLL_geq_10_suppressed = if(has_bll_geq_10) str_detect(BLL_geq_10, "<") else NA,
               BLL_geq_10 = if(has_bll_geq_10) as.numeric(str_remove(BLL_geq_10, "<")) else NA) |>
        group_by(state) |>
        mutate(ell_5 = if(has_bll_geq_5) min(BLL_geq_5[BLL_geq_5 > 0], na.rm = TRUE) - 1 else NA,
               ell_10 = if(has_bll_geq_10) min(BLL_geq_10[BLL_geq_10 > 0], na.rm = TRUE) - 1 else NA) |>
        ungroup()
    
    # Remove columns that are entirely NA
    lead_data <- lead_data[, colSums(is.na(lead_data)) < nrow(lead_data)]
    
    return(lead_data)
}

final_checks  <- function(merged_data, drop="BLL_geq_10"){
    #' implements final data checks and optionally drop outcome variable
    merged_data |>
        filter(under_yo5_pplE>=tested,
               tested>0) |> 
        select(-all_of(drop))
        # drop if NA in any of offset_var, features or outcomes
        # get presence of outcomes by substr BLL_geq_*
    outcome_vars <- merged_data |> names() |> str_subset("BLL_geq_") |> str_remove("_suppressed") |> unique()

    merged_data |> drop_na(any_of(c(features, offset_var, outcome_vars)))
}

