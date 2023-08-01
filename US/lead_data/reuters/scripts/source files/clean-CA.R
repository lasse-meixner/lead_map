library(dplyr)
library(readxl)

## Load in CA files


         
ca_path <- "BLL_CA_Raw.xlsx"

# if drop_get_from_root function is in env, continue, otherwise source "00_drop_box_access.R"
if (!exists("drop_get_from_root")) {
    source("../00_drop_box_access.R")
}

drop_get_from_root(ca_path)

ca <- read_excel(ca_path) |> 
    rename(zip = ZIP) |>
    mutate(year = 2012,
           state = "CA",
           BLL_geq_5 = as.numeric(BLL_geq_45) * 1.14)|>   # "In 2012", 14% of the results at and above 4.5mcg/dL were in the range 4.5-4.99mcg/dL. Here, I am smoothing this figure over all zips.
    select(-BLL_geq_45)

# save to csv
write_csv(ca, "../processed_files/ca.csv")
