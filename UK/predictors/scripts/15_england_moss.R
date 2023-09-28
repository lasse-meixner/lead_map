require(tidyverse)
library(readxl)
library(sf)
library(magrittr)
library(tmap)
library(nngeo)
library(data.table)
library(grid)
library(ggpubr)

# Read in data
# We only need the MSOA boundaries at the end, for mapping. Same for the MSOA to LA lookup and ALSPAC study area

gdrive_get_file("moss_survey.xlsx")

moss_survey_sf <- read_excel("../raw_data/moss_survey.xlsx") %>%
  st_as_sf(coords = c("Longitude", "Latitude"), crs = 4326) %>%
  st_transform(crs = 27700) %>%
  rename("geometry_moss_sample" = "geometry",
         "moss_lead" = "Pb (ug/g)") %>%
  mutate(Moss = case_when(Moss == "Hylocomium splendens" ~ "Hylocomium",
                          Moss == "Pleurozium schreberi" ~ "Pleurozium",
                          Moss == "Hypnum cupressiforme" ~ "Hypnum",
                          Moss == "Pseudoscleropodium purum" ~ "Pseudoscleropodium",
                          TRUE ~ Moss)) %>%
  # Get rid of outliers by year (BEFORE OR AFTER COLLAPSING CLUSTERS?)
  group_by(Year) %>%
  filter(!moss_lead %in% boxplot.stats(moss_lead)$out) %>%
  ungroup()

# if centroids_population_msoa is not already in memory, read it in
if (exists("centroids_population_msoa")) {
  print("centroids_population_msoa already in memory")
} else {
  centroids_population_msoa <- drive_get("Lead_Map_Project/UK/predictors/raw_data/msoa_population_centroids.csv") |>
    drive_read_string() |>
    read_csv() |>
    dplyr::select(-objectid) %>%
    filter(substr(msoa11cd, 1, 1) == "E") %>%
    st_as_sf(coords = c("X", "Y"),
             crs = 27700) %>%
    rename("geometry_msoa_centroid" = "geometry")
}

# Create four different data frames of moss samples (one for each wave of the survey) 
# with which we'll perform the same exercise to compute moss variables for each wave of the survey 
# Do the same thing to create three more dataframes which are the same as above, except using only Pleurozium and Hylocomium mosses
# (note, can't do this for 1995 because we don't know moss types)

# All mosses

moss_survey_sf_1990 <- moss_survey_sf %>%
  filter(Year == "1990")

moss_survey_sf_1995 <- moss_survey_sf %>%
  filter(Year == "1995")

moss_survey_sf_2000 <- moss_survey_sf %>%
  filter(Year == "2000")

moss_survey_sf_2005 <- moss_survey_sf %>%
  filter(Year == "2005")

# Pleurozium and Hylocomium mosses only

moss_survey_sf_1990_pl_hy <- moss_survey_sf %>%
  filter(Year == "1990", 
         Moss %in% c("Pleurozium", "Hylocomium"))

moss_survey_sf_2000_pl_hy <- moss_survey_sf %>%
  filter(Year == "2000", 
         Moss %in% c("Pleurozium", "Hylocomium"))

moss_survey_sf_2005_pl_hy <- moss_survey_sf %>%
  filter(Year == "2005",
         Moss %in% c("Pleurozium", "Hylocomium"))


# Function will turn a given set of moss samples into MSOA-level moss variables for England
# The second argument allows to adjust whether we want to use the nearest 10 samples (like Gronqvist and Nielsen) or a different number

compute_moss_msoa <- function(survey_wave, n_sample = 10, cluster_distance = 250) {

  # First, we need to "collapse" each cluster of nearby samples so that it is represented by a single representative sample
  # which will have a location and moss_lead value which are the mean of all samples in the cluster

  # Generate matrix giving distance of each sample from all others in meters
  inter_sample_distances <- st_distance(survey_wave, survey_wave)
  
  # Cluster all points using a hierarchical clustering approach
  hc <- hclust(as.dist(inter_sample_distances), method="complete")
  
  # Define the distance threshold, in this case 40 m
  d = cluster_distance
  
  # Define clusters based on a tree "height" cutoff "d" and add them to the sf object of samples
  # We can then use these clusters to group samples
  survey_wave$clust <- cutree(hc, h=d)
  
  # Collapse clusters
  # Unfortunately, summarizing cluster geometry is not as simple as just using the mean() function on the geometry column
  # Instead, we have to create columns for the x and y coordinates; drop the geometry column; find the mean x and y coordinate in 
  # each cluster; and then use these to reconstruct the geometry column
  moss_survey_sf_year <- survey_wave %>%
    filter(!is.na(moss_lead)) %>%
    mutate(x = st_coordinates(.)[, 1],
           y = st_coordinates(.)[, 2]) %>%
    st_drop_geometry() %>%
    group_by(clust) %>%
    summarise(moss_lead = mean(moss_lead),
              x = mean(x),
              y = mean(y)) %>%
    # Note, index numbers are for clusters
    mutate(index = row_number()) %>%
    st_as_sf(coords = c("x", "y")) %>%
    rename("geometry_moss_sample" = "geometry")
  
  st_crs(moss_survey_sf_year) <- st_crs(centroids_population_msoa)
  
  # First, we need to find the 10 nearest moss samples to each MSOA centroid
  
  # This tells you, for each MSOA centroid, the 10 nearest moss samples
  nn <- st_nn(centroids_population_msoa, moss_survey_sf_year, k = n_sample) %>%
    as.data.frame() %>% 
    t()
  rownames(nn) <- c(1:nrow(nn))
  colnames(nn) <- paste("moss_index_", c(1:10), sep = "")
  nn %<>% as_tibble()
  
  centroids_msoa_moss_index <- cbind(centroids_population_msoa, nn) %>%
    as_tibble()
  
  # Now, for each MSOA centroid we need to get the actual moss data from the 10 nearest samples (which we identified for each 
  # MSOA centroid above)
  
  # Here we create a list of 10 different data frames
  # The first contains the data for the nearest sample to the MSOA centroid (along with columns describing the MSOA centroid of course),
  # the second contains the data for the second nearest sample to the MSOA centroid, and so on
  moss_dfs_list <- lapply(colnames(nn), function(x) {
    
    moss_survey_sf_lapply <- moss_survey_sf_year %>%
      rename(!!sym(x) := "index")
    
    left_join(centroids_msoa_moss_index, moss_survey_sf_lapply) %>%
      dplyr::select(!(moss_index_1:moss_index_10))
    
  })
  
  # Now, we can either present the data in wide format (unwieldy) or long format (less unwieldy)
  # In wide format, we'll have a row for each MSOA
  # In long format, we'll have a row for each MSOA x sample pairing
  
  # Wide format
  # Here, we adjust the column names in each of the 10 data frames above so that the column names in the first data frame, which contains the 
  # moss data for each row's nearest sample, end in _1; the column names in the second data frame end in _2 and so on
  # We merge all of these data frames to get a single data frame with columns describing each MSOAs 1st through 10th nearest moss sample
  # i <- 1
  # centroid_msoa_moss_samples_data_wide <- moss_dfs_list[[i]] %>%
  #   rename_with(~paste(., i, sep = "_"), .cols = 4:7)
  # for (i in c(2:10)) {
  #   
  #   moss_samples_set <- moss_dfs_list[[i]] %>%
  #     rename_with(~paste(., i, sep = "_"), .cols = 4:7)
  #   
  #   centroid_msoa_moss_samples_data_wide <- left_join(centroid_msoa_moss_samples_data_wide, moss_samples_set)
  #   
  # }
  
  # Long format
  # Here, we add an extra column to each of the 10 data frames stating whether it contains nearest, second nearest etc. samples
  # Then we rbind the 10 dataframes
  i <- 1
  centroid_msoa_moss_samples_data_long <- moss_dfs_list[[i]] %>%
    mutate(sample_no = i)
  
  for (i in c(2:10)) {
    
    moss_samples_set <- moss_dfs_list[[i]] %>%
      mutate(sample_no = i)
    
    centroid_msoa_moss_samples_data_long <- rbind(centroid_msoa_moss_samples_data_long, moss_samples_set)
    
  }
  
  # Work with long format data, compute distance of each MSOA's nearest samples from its centroid
  
  centroid_msoa_moss_samples_data_long <- centroid_msoa_moss_samples_data_long %>%
    mutate(centroid_distance = st_distance(st_geometry(geometry_msoa_centroid), 
                                           st_geometry(geometry_moss_sample), 
                                           by_element = TRUE) %>% as.numeric(),
           inverse_centroid_distance = 1 / centroid_distance)
  
  moss_msoa <- centroid_msoa_moss_samples_data_long %>%
    group_by(msoa11cd) %>%
    summarise(moss_lead_mean_idw = weighted.mean(moss_lead, inverse_centroid_distance, na.rm = TRUE),
              moss_sample_dist_mean = mean(centroid_distance))
              
  
  list(moss_msoa, moss_survey_sf_year)

}

# Moss MSOA objects using all mosses

moss_1990 <- compute_moss_msoa(moss_survey_sf_1990)
moss_msoa_1990 <- moss_1990[[1]] %>%
  rename_with(~paste(., "_1990", sep = ""), .cols = contains("moss"))
moss_survey_sf_1990_clean <- moss_1990[[2]]

moss_1995 <- compute_moss_msoa(moss_survey_sf_1995)
moss_msoa_1995 <- moss_1995[[1]] %>%
  rename_with(~paste(., "_1995", sep = ""), .cols = contains("moss"))
moss_survey_sf_1995_clean <- moss_1995[[2]]

moss_2000 <- compute_moss_msoa(moss_survey_sf_2000)
moss_msoa_2000 <- moss_2000[[1]] %>%
  rename_with(~paste(., "_2000", sep = ""), .cols = contains("moss"))
moss_survey_sf_2000_clean <- moss_2000[[2]]

moss_2005 <- compute_moss_msoa(moss_survey_sf_2005)
moss_msoa_2005 <- moss_2005[[1]] %>%
  rename_with(~paste(., "_2005", sep = ""), .cols = contains("moss"))
moss_survey_sf_2005_clean <- moss_2005[[2]]

# Moss MSOA objects using only Pleurozium and Hylocomium mosses

moss_1990_pl_hy <- compute_moss_msoa(moss_survey_sf_1990_pl_hy)
moss_msoa_1990_pl_hy <- moss_1990_pl_hy[[1]] %>%
  rename_with(~paste(., "_1990_pl_hy", sep = ""), .cols = contains("moss"))

moss_2000_pl_hy <- compute_moss_msoa(moss_survey_sf_2000_pl_hy)
moss_msoa_2000_pl_hy <- moss_2000_pl_hy[[1]] %>%
  rename_with(~paste(., "_2000_pl_hy", sep = ""), .cols = contains("moss"))

moss_2005_pl_hy <- compute_moss_msoa(moss_survey_sf_2005_pl_hy)
moss_msoa_2005_pl_hy <- moss_2005_pl_hy[[1]] %>%
  rename_with(~paste(., "_2005_pl_hy", sep = ""), .cols = contains("moss"))

# Merge all moss MSOA objects

moss_msoa <- left_join(moss_msoa_1990, moss_msoa_1995) %>%
  left_join(., moss_msoa_2000) %>%
  left_join(., moss_msoa_2005) %>%
  left_join(., moss_msoa_1990_pl_hy) %>%
  left_join(., moss_msoa_2000_pl_hy) %>%
  left_join(., moss_msoa_2005_pl_hy)

moss_msoa %>%
  write_csv("../processed_data/moss_msoa.csv")

rm(moss_1990, moss_1995, moss_2000, moss_2005)
rm(moss_msoa_1990, moss_msoa_1995, moss_msoa_2000, moss_msoa_2005)
rm(moss_survey_sf_1990, moss_survey_sf_1995, moss_survey_sf_2000, moss_survey_sf_2005)
rm(moss_survey_sf_1990_pl_hy, moss_survey_sf_2000_pl_hy, moss_survey_sf_2005_pl_hy)
rm(moss_1990_pl_hy, moss_2000_pl_hy, moss_2005_pl_hy)
rm(moss_msoa_1990_pl_hy, moss_msoa_2000_pl_hy, moss_msoa_2005_pl_hy)
