# In this file, we crosswalk tracts to ZIPs for US states that have BLLS at the ZIP level

library(tidyverse)
library(httr)
library(jsonlite)
library(purrr)

# get metadata from ~US root
metadata  <- fromJSON("../../metadata.json")
# extract required metadata (lists)
zip_states <- metadata$zip_states
id_variables <- metadata$id_variables
ratio_variables <- metadata$proportion_variables
count_variables <- metadata$count_variables


# first, load the combined tract file (otherwise take the latest one from drive)
combined_tract <- read_csv("../processed_data/combined_tract.csv")


# auxiliary function to crosswalk both counts and ratios for a particular ZIP state
# for Details about the API and or the crosswalking logic, see the ReadMe file
crosswalk_ZIP <- function(state_abbr, combined_tract){
    
    ## API SETUP
    # load key, and set up url for USPS API
    key  <- Sys.getenv("USPS_API_KEY")
    url <- "https://www.huduser.gov/hudapi/public/usps"
    
    ## RATIO Variables
    # get all ratio variables based on matching_variables.json and select state sub tibble
    combined_tract_selected <- combined_tract |>
        select(all_of(c(id_variables, ratio_variables))) |>
        filter(STATE_ABBR == state_abbr)
    # get type = 1: ZIP-TRACT (proportions & ratios)
    response <- httr::GET(url, query = list(type = 1, query = state_abbr), add_headers(Authorization = paste("Bearer", key)))
    # check if reponse has error:
    if (httr::http_error(response)) {
        stop("Error: ", httr::content(response, "text"))
    }
    # get output and transform into tibble
    output <- httr::content(response, as = "text") |>
      fromJSON(flatten = TRUE) |>
      pluck("data") |>
      as_tibble() |>
      unnest_wider(results) |> 
      rename(TRACT = geoid) |> 
      select(TRACT, zip, res_ratio)
    
    # merge with predictor data
    tb_crosswalked_ratios <- combined_tract_selected |>
      left_join(output, by = "TRACT") |> 
      distinct() |> 
      relocate(res_ratio, .after = TRACT) |> 
      relocate(zip, .after = TRACT) 
      
    
    # group by zip, and for all columns take the weighted AVERAGE with "res_ratio"
    crosswalked_ratios <- tb_crosswalked_ratios |>
        group_by(zip) |>
        summarise(across(all_of(ratio_variables), ~ weighted.mean(., w = res_ratio, na.rm = TRUE)))
    
    ## COUNT Variables
    # get all count variables based on matching_variables.json and select state sub tibble
    combined_tract_selected <- combined_tract |>
        select(all_of(c(id_variables, count_variables))) |>
        filter(STATE_ABBR == state_abbr)
    
    # get type = 2: TRACT-ZIP (counts)
    response <- httr::GET(url, query = list(type = 6, query = state_abbr), add_headers(Authorization = paste("Bearer", key)))
    # check if reponse has error:
    if (httr::http_error(response)) {
        stop("Error: ", httr::content(response, "text"))
    }
    # get output and transform into tibble
    output <- httr::content(response, as = "text") |>
      fromJSON(flatten = TRUE) |>
      pluck("data") |>
      as_tibble() |>
      unnest_wider(results) |> 
      rename(TRACT = tract,
             zip = geoid) |> 
      select(TRACT, zip, res_ratio)

    # merge with predictor data
    tb_crosswalked_counts <- combined_tract_selected |>
      left_join(output, by = "TRACT") |> 
      distinct() |> 
      relocate(res_ratio, .after = TRACT) |> 
      relocate(zip, .after = TRACT)

    # group by zip, and for all columns take the weighted SUM with "res_ratio"
    crosswalked_counts <- tb_crosswalked_counts |> 
      group_by(zip) |> 
      summarise(across(all_of(count_variables), ~ sum(. * res_ratio, na.rm = TRUE)))

    ## join counts and ratios at zip level
    crosswalked_zip_st <- crosswalked_counts |>
      left_join(crosswalked_ratios, by = "zip") |>
      mutate(STATE_ABBR = state_abbr) |> 
      relocate(STATE_ABBR)
      

    return(crosswalked_zip_st)
}


## script main loop
# purrr over all ZIP states and map_df the resulting tibbles
crosswalked_zip <- map_df(zip_states, \(x) {
    crosswalk_ZIP(state_abbr = x, combined_tract = combined_tract)
})

# save to disk
crosswalked_zip |>
    write_csv("../processed_data/crosswalked_zip.csv")

# save to Gdrive
source("00_gdrive_utils.R")
drive_upload_w_tstamp("crosswalked_zip")
