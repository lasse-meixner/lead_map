

## Census tract to ZIP code mapping


# try to setwd to the raw_files folder, if cannot change directory, assume already in raw_files folder
tryCatch(setwd(dir = "../raw_files/"),
         error = function(e) 1)

# Crosswalk file to be pulled from DropBox
tract_path <- 'TRACT_ZIP_032010.xlsx'

# if drop_get_from_root function is in env, continue, otherwise source "00_drop_box_access.R"
if (exists("drop_get_from_root")) {
    drop_get_from_root(tract_path)
} else {
    source("../scripts/00_drop_box_access.R")
    drop_get_from_root(tract_path)
}

tracttozip <- read_excel(tract_path) %>% 
  rename(tract=TRACT)


# auxiliary function for tract -> zip crosswalking
# NOTE: This coerces non-numeric entries (e.g. <5, i.e. surpressed values) to NA. 
# Since surpression is more information than NA (namely e.g. that #EXPOSED>0), surpression must be handled for each cleaned file PRIOR to aggregation to avoid losing information.

walk_tracttozip <- function(tb, state_string){
       # if tb does not have "BLL_geq_10" column, fill with NAs
       if(!"BLL_geq_10" %in% colnames(tb)){
              tb <- tb |> 
                     mutate(BLL_geq_5 = NA,
                     tract = as.character(tract)) # cast to character for join
       }
       # perform ZIP aggregation
       zip <- left_join(tb, tracttozip, by = "tract") |>  
              mutate(BLL_geq_5 = as.numeric(BLL_geq_5),
                     BLL_geq_10 = as.numeric(BLL_geq_10),
                     tested=as.numeric(tested)) |>  
              mutate(new_BLL_geq_5 = BLL_geq_5 * RES_RATIO,
                     new_BLL_geq_10 = BLL_geq_10 * RES_RATIO,
                     new_tested = tested * RES_RATIO) |> 
              group_by(ZIP,year) |>  
              summarise(BLL_geq_5 = sum(new_BLL_geq_5,na.rm = TRUE),
                     BLL_geq_10 = sum(new_BLL_geq_10,na.rm = TRUE),
                     tested = sum(new_tested,na.rm = TRUE)) |> 
              rename(zip=ZIP) |> 
              mutate(state=state_string,
                     aggregated = TRUE)
       zip
}


## OH
# TODO: Handle surpression (e.g. <5) in OH data

oh_zip <- walk_tracttozip(oh,"OH")

## PA
# TODO: Handle surpression (e.g. <5) in PA data

pa_zip <- walk_tracttozip(pa,"PA")

## MD 
# TODO: Handle surpression (e.g. <5) in MD data

md_zip <- walk_tracttozip(md,"MD")

## MA
# TODO: Handle surpression (e.g. <5) in MA data

ma_zip <- walk_tracttozip(ma,"MA")

## NYC
# TODO: Handle surpression (e.g. <5) in NYC data

nyc_zip <- walk_tracttozip(track_nyc,"NYC")

## NC
# TODO: Handle surpression (e.g. <5) in NC data. Here for many years most data is surpressed.

nc_zip <- walk_tracttozip(track_nc,"NC")
  
## Indiana
# TODO: Handle surpression (e.g. <5) in IN data
  
ind_zip <- walk_tracttozip(track_ind,"IN")

## OR
# TODO: Handle surpression (e.g. <5) in OR data
or_zip <- walk_tracttozip(or,"OR")

## MN
# TODO: Handle surpression (e.g. <5) in MN data

mn_zip <- walk_tracttozip(track_mn,"MN")

## Colorado
# TODO: Handle surpression (e.g. <5) in CO data

co_zip <- walk_tracttozip(track_co,"CO")


## New Hampshire

nh_zip <- walk_tracttozip(track_nh,"NH")

## Wisconsin 

# TODO: Implement (from State Health Dept. file)
