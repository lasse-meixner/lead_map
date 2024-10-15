# merging data for our exlusion restriction: ratio of pediatricians to kids (2023 from the ABP)
# This is done after crosswalking in the pipeline because we want to match it to the crosswalked data (it's in counties, so coarser than tracts, and most ZIPs)

# 1 for tracts: find the county within which the tract sits, and join the county-level ratio.
# 2 for ZIPs: crosswalk counties to zips. Then join averaged county-level ratio.

require(tidyverse)
require(googledrive)
require(readxl)

library(purrr)
library(usmap)
library(httr)
library(jsonlite)


# try download file from gdrive into raw_data
gdrive_get_file("2023_Pediatrician_State_and_County_Data.xlsx")

# read file
pediatricians  <- read_excel("../raw_data/2023_Pediatrician_State_and_County_Data.xlsx", sheet = "3.GP County - Maintaining Certs", skip = 1)

# keep the info we need
pediatricians_mod <- pediatricians |>
    rename(
        County = "County Name",
        ped_per_100k = "The combination of those certified in General Pediatrics (alone) and those certified in both General Pediatrics and in another ABMS specialty") |>
    # the data includes the ratio we want, as well as the count of <18, which we drop to avoid double crosswalking efforts for ZIP states
    filter(Measure %in% c("Per 100,000 Children"),
           State != "U.S. Total") |>
    select(State, County, ped_per_100k)


# for each state: get the fips code for each county in the pediatrician data using usmap::fips
pediatricians_zip <- map_df(unique(pediatricians_mod$State), function(x) {
  tryCatch({
    pediatricians_mod %>%
      filter(State == x) %>%
      mutate(FIPS = fips(state = x, county = County))
  }, error = function(e) {
    # If there's an error (can't find a county so returns shorter list), run fips for each county separately
    pediatricians_mod %>%
      filter(State == x) %>%
      mutate(FIPS = map_chr(County, ~ tryCatch(fips(state = x, county = .x), 
                                            error = function(e) NA)))
  })
})

# get metadata on tract and ZIP states
metadata  <- fromJSON("../../metadata.json")
zip_states <- names(metadata$states)[sapply(metadata$states, function(x) x$geography == "zip")]
tract_states <- names(metadata$states)[sapply(metadata$states, function(x) x$geography == "tract")]

# get tract data and add county FIPS (the first 5 digits of the tract FIPS) then join pediatrician data
final_tract <- read_csv("../processed_data/combined_tract.csv")  |>
    filter(STATE_ABBR %in% tract_states) |>
    mutate(FIPS = substr(TRACT, 1, 5)) |>
    left_join(pediatricians_zip, by = "FIPS")


# get crosswalking information for ZIP -> county
crosswalk_zip_to_county  <- function(state_abbr, zip_data){
    # get api info
    key  <- Sys.getenv("USPS_API_KEY")
    url <- "https://www.huduser.gov/hudapi/public/usps"

    # get type = 2: COUNTY-ZIP (for ratio)
    response <- httr::GET(url, query = list(type = 2, query = state_abbr), add_headers(Authorization = paste("Bearer", key)))
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
    rename(FIPS = geoid) |> 
    select(zip, FIPS, res_ratio)

    # join res_ratio to zip data (expands for multi-county ZIPs) and take weighted average for ped_per_100k
    crosswalked_ratios <- zip_data |> 
        filter(STATE_ABBR == state_abbr) |>
        left_join(output, by = "zip") |> 
        left_join(pediatricians_zip, by = "FIPS")|>
        distinct() |> 
        group_by(zip) |>
        summarize(ped_per_100k = weighted.mean(ped_per_100k, w = res_ratio, na.rm = TRUE))
    
    # join back to original zip data
    crosswalked_ratios <- zip_data |> 
        filter(STATE_ABBR == state_abbr) |>
        left_join(crosswalked_ratios, by = "zip")

    # make sure that final data has the same number of rows as the original data
    stopifnot(nrow(crosswalked_ratios) == nrow(zip_data |> filter(STATE_ABBR == state_abbr)))
    
    return(crosswalked_ratios)
}

# purrr over zips states and crosswalk
zip_data <- read_csv("../processed_data/crosswalked_zip.csv")

final_zip <- map_df(unique(zip_data$STATE_ABBR), \(x) {
    crosswalk_zip_to_county(state_abbr = x, zip_data = zip_data)
})

# save final files to disk
final_tract |> write_csv("../processed_data/final_tract.csv")
final_zip |> write_csv("../processed_data/final_zip.csv")

# push to Gdrive
gdrive_upload_w_tstamp("final_tract")
gdrive_upload_w_tstamp("final_zip")

