# auxiliary functions to create basic descriptives and summary statistics

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
    state_data <- get(str_to_lower(state_name))
    # preprocess lead data
    state_lead <- state_data |>
        # optionally filter year if provided, e.g. 2010
        {
            if (!is.null(filter_year)) {
                . |> filter(year == filter_year)
            } else {
                .
            }
        } |>
        # preprocess lead data
        preprocess_lead_data()
      
    state_pred <- tract_data |> filter(STATE_ABBR == state_name) |> preprocess_pred_data(info_vars = tract_info_vars, additional_preprocess = pred_preprocess_func)

    # merge
    state_merged <- state_pred |> 
        left_join(state_lead, by = c("TRACT" = "tract")) |> 
        final_checks(drop=drop_outcome)
}

# HIGH LEVEL loader for zips
single_state_zip <- function(state_name, drop_outcome = c(), pred_preprocess_func = NULL, filter_year = NULL){
    # load and assign the state data
    load_state(state_name, from_raw = TRUE) # from 00_merging_functions.R 
    state_data <- get(str_to_lower(state_name))
    # preprocess lead data
    state_lead <- state_data |>
        # optionally filter year if provided, e.g. 2010
        {
            if (!is.null(filter_year)) {
                . |> filter(year == filter_year)
            } else {
                .
            }
        } |>
        # ensure zip is chr
        mutate(zip = as.character(zip)) |>
        # preprocess lead data
        preprocess_lead_data()
      
    state_pred <- zip_data |> filter(STATE_ABBR == state_name) |> preprocess_pred_data(info_vars = zip_info_vars, additional_preprocess = pred_preprocess_func)

    # merge
    state_merged <- state_pred |> 
        left_join(state_lead, by = "zip") |> 
        final_checks(drop=drop_outcome)

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
    coord_fixed()
}

# Get spread of (normalized features) in the data
get_spread_plot <- function(state_data, features = c("median_annual_incomeE", "poor_fam_propE")){
    # plot in grid, 3 cols
    state_data |> 
        select(all_of(features)) |> 
        gather() |> 
        ggplot(aes(value)) +
        geom_histogram(bins = 30, alpha = 0.5) +
        facet_wrap(~key, scales = "free") +
        theme_minimal()
}