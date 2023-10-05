library(dplyr)
library(readxl)

## Load in CA files


         
file_path <- "BLL_CA_Raw.xlsx"


#TODO: set working directory in script?

# check if file exists in raw_data, if not, download it from Gdrive
if (!file.exists(paste0("../../raw_data/",file_path))){
       print("Downloading file from Google Drive...")
       drive_download(
              file = paste0("Lead_Map_Project/US/lead_data/raw_data/", file_path),
              path = paste0("../../raw_data/", file_path),
              overwrite = TRUE
       )
} else {
   print(paste0("File ", file_path ," already in local folder."))
}


ca <- read_excel(paste0("../../raw_data/", file_path)) |> 
    rename(zip = ZIP) |>
    mutate(year = 2012,
           state = "CA",
           BLL_geq_5 = as.numeric(BLL_geq_45) * 1.14)|>   # "In 2012", 14% of the results at and above 4.5mcg/dL were in the range 4.5-4.99mcg/dL. Here, I am smoothing this figure over all zips.
    select(-BLL_geq_45)

# save to csv
write_csv(ca, "../../processed_data/ca.csv")
