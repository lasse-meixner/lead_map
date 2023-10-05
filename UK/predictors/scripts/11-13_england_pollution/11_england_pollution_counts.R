# This script will compute, for each MSOA, lead polluter counts for each year since 1993
# At the end of the script, we will have the above information in wide format with MSOA rows, 
# to merge in the next script with MSOA emissions data (also in wide format with MSOA rows)

# NOTE: THIS IS COPIED AND PASTED AS FAR AS POSSIBLE FROM JAY'S CODE, SO CONVENTIONS ARE DIFFERENT TO OTHER SCRIPTS IN THIS PROJECT

######################### Load all required packages and datasets
required.packages <- c("tidyverse", "magrittr", "sf", "terra", "tm", "readxl")
lapply(required.packages, require, character.only = TRUE)

`%notin%` <- Negate(`%in%`)

# check if sf_msoa is already in memory (in case prior script has been run), otherwise, read it in
if (exists("sf_msoa")) {
  print("sf_msoa already in memory")
} else {
  sf_msoa <- read_sf("../raw_data/shapefiles/msoa/england_msoa_2011.shp")
}

# TODO: This csv is only the pointer to the Git LFS file. Need to move this to GDrive!
mapping <- drive_get("Lead_Map_Project/US/predictors/postcode_centroids_2020.csv") |>
  drive_read_string() |>
  read_csv()

# read pollution inventory
gdrive_get_file("1992_2008 Pollution Inventory Dataset.xlsx")
pollution <- read_excel("../raw_data/1992_2008 Pollution Inventory Dataset.xlsx") %>%
  as_tibble()

##################################################
# first, construct counts of polluters in each postcode (by year), count by address

pollution_count <- pollution %>%
  filter(Substance %in% c("Metals - Group 3 (As+Cr+Cu+Mn+Ni+Pb+Sn)",
                          "Metals - Grp 4(As+Cd+Cr+Co+Cu+Mn+Ni+Pb+Sb+Sn+Tl+V)" ,     
                          "Metals - Group 2 (As+Cr+Co+Cu+Mn+Ni+Pb+Sb+Sn+V)",
                          "Metals - Group 5 (Cr+Cu+Mn+Pb)",
                          "Lead")
         ) %>%
  select(year = Year, pcd = `Site postcode`, address = `Site address`) %>%
  group_by(pcd, year) %>%
  summarize(n = length(unique(address))) %>%
  filter(!is.na(pcd)) #remove sites with NA postcodes for now

pollution_count$pcd <- str_remove_all(pollution_count$pcd, pattern = fixed(" "))

typos <- c( "B981UB", "BB3ORR", "LE13OJG", "PL4OPX", "PO39JG", "SO509NZ", "ST17OXR", "TN259QB", "TN328AY")
corrections <- c("B987UB", "BB30RR", "LE130JG", "PL40PX", "PO139JG", "SO506NZ", "ST170XR", "TN249QB", "TN388AY")
for(index in 1:length(typos)){
  pollution_count$pcd[pollution_count$pcd %in% typos[index]] <- corrections[index]
}

######################### map polluter postcodes to their centroids

mapping$pcd <- str_remove_all(mapping$pcd, pattern = fixed(" "))

spatial_pollution_count <- left_join(pollution_count, mapping, by = "pcd") %>%
  select(pcd, year, polluter_count = n, oseast1m, osnrth1m) %>%
  mutate(osnrth1m = as.numeric(osnrth1m)) %>% #typo in dataset - one of the entries in osnrth1m is non-numeric for some reason.
  vect(c("oseast1m", "osnrth1m")) %>%
  st_as_sf
st_crs(spatial_pollution_count) <- st_crs(sf_msoa)

######################### execute spatial join

spatial_polluter_counts <- st_join(sf_msoa, spatial_pollution_count)

polluter_counts <- spatial_polluter_counts %>% 
  group_by(code, year) %>%
  st_drop_geometry() %>%
  summarize(name = unique(name),
            polluter_count = sum(polluter_count))

######################### clean panel: we expand each code so that there is a full set of time-series observations between 1993 and 2008 for every MSOA
min_year <- min(polluter_counts$year, na.rm = TRUE)
max_year <- max(polluter_counts$year, na.rm = TRUE)
sample_years <- min_year:max_year
clean <- polluter_counts %>%
  split(.$code) #list of dataframes by MSOA

# the idea here is to loop through the list of MSOAs.  For each, construct a dataframe consisting of NA observations for years which do not already have observations. Add these dummy rows to the dataframe, and add the corresponding years.  To see better how this works with the two different kinds of cases (empty and nonempty observations), consider indices 1 and 10.
for(index in 1:length(clean)) {
  df <- clean[[index]] #tmp dataframe
  
  years <- df$year #years with data
  years_to_add <- sample_years[sample_years %notin% years] #years without data
  
  indices_to_add <- seq(1, length(years_to_add)) + length(na.omit(years)) #set of dataframe indices that need to be added to get the full sample.  i.e, if there is no data in the MSOA, this is 1:17.  If there are two observations, this is 3:17
  observation_to_add <- df[1,] %>% 
    mutate(year = NA, polluter_count = NA) #take the first row and set year and polluter_count = NA
  
  df[indices_to_add,] <- observation_to_add #add dummies
  df$year[is.na(df$year)] <- years_to_add #add years
  
  clean[[index]] <- df %>% #assign to list
    arrange(year)
}

polluter_counts_panel <- clean %>%
  do.call("rbind",.) 

polluter_counts_panel$polluter_count[is.na(polluter_counts_panel$polluter_count)] <- 0

polluter_counts_panel_wide <- polluter_counts_panel %>%
  pivot_wider(names_from = year, values_from = polluter_count)
colnames(polluter_counts_panel_wide) %<>% as.numeric %>%
  na.omit %>%
  paste0("polluter_count_", .) %>%
  c("code", "name", .)

# Remove 1992 column (given we choose to treat 1992 data as almost entirely incomplete)
# Note, we have to remove it here rather than removing those facility records right at the beginning because 
# doing that introduces issues in the for loop earlier in the script
polluter_counts_panel_wide %<>% select(-contains("1992"))

rm(pollution, pollution_count, spatial_pollution_count, spatial_polluter_counts, polluter_counts, polluter_counts_panel)
