# NOTE: This might have been copied from Jay?

# This script will compute road counts and road lengths per MSOA, disaggregated by type of road

# Read in relevant packages

required_packages <- c("tidyverse", "magrittr", "sf", "terra", "tm", "readxl", "tmap")
lapply(required_packages, require, character.only = TRUE)

# Read in data and do a bit of cleaning

sf_msoa <- read_sf("data_raw/uk/shapefiles/msoa/england_msoa_2011.shp") %>%
  rename("msoa11cd" = "code",
         "msoa_name" = "name") %>%
  select(-label)

# Read in MSOA land areas to compute densities at the end
land_area_msoa <- read_csv("data_raw/uk/shapefiles/msoa_land_area/SAM_MSOA_DEC_2011_EW.csv") %>%
  rename("msoa11cd" = "MSOA11CD",
         "msoa_name" = "MSOA11NM",
         "area" = "AREALHECT") %>%
  filter(substr(msoa11cd, 1, 1) == "E") %>%
  dplyr::select(msoa11cd, msoa_name, area)

# TODO:
major_roads <- read_sf("../prep-for-ALSPAC/data/Major_Road_Network_2018_Open_Roads/Major_Road_Network_2018_Open_Roads.shp") %>%
  dplyr::select(id, road = roadClas_1, geometry) %>%
  mutate(road_type = "major")

strategic_roads_raw <- read_sf("../prep-for-ALSPAC/data/strategic_roads_england/HAPMS_network_20160929.shp")

strategic_roads <- strategic_roads_raw %>%
  dplyr::select(id = sect_label, road = roa_number, geometry) %>%
  mutate(road_type = "strategic")

st_crs(strategic_roads) <- st_crs(major_roads)

# NOTE: A LOT OF THE STRATEGIC ROAD NAMES ALSO APPEAR IN MAJOR ROAD NAMES (ALTHOUGH NOT THE SAME SEGMENTS)
# We also need to replace some missing road names (having found out the names by pasting geometry elements into Google Maps)
major_and_strategic_roads <- rbind(major_roads, strategic_roads)
major_and_strategic_roads$road[is.na(major_and_strategic_roads$road)] <- road_name_replacements <- c("A15", "A15", "A15", "A59")

# Can read in Open Roads data for whole of the UK using similar code to for EPCs
# But takes an infeasibly long time
# open_roads_dir <- "../prep-for-ALSPAC/data/open_roads/data"
# open_roads <- list.files(open_roads_dir, full.names = TRUE) %>%
#   str_subset(pattern = "RoadLink.shp") %>%
#   lapply(read_sf) %>%
#   do.call(rbind, .)

# Instead of reading in open roads data for the whole country, we read it in just for the zone containing the study area (ST)
# Note, we have done no filtering of the Open Roads data to remove segments built after the study period
open_roads_ST <- read_sf("../prep-for-ALSPAC/data/open_roads/data/ST_RoadLink.shp") %>%
  dplyr::select(id = identifier, road = roadNumber, geometry, road_type = class, primary) %>%
  mutate(road_type = ifelse(!(road_type %in% c("Motorway", "A Road", "B Road")), "Other", road_type),
         road_type = str_replace(road_type, " ", "_"),
         primary = ifelse(primary == "true", "primary", "non_primary"))

# Read in study area and construct sf object of study area MSOAs as we'll use this for filtering the last two roads sf outputs,
# which only really make sense in the context of the study area 
# (i.e., no meaning to filtering roads outside of the study area based on when they were built relative to the study period)

alspac_study_area <- read_sf("data_raw/uk/shapefiles/study_area_buffer/study_area_buffer.shp")

sf_msoa_study_area <- st_filter(sf_msoa, alspac_study_area, .predicate = st_intersects) 


         
#################### Create a "filtered" version of the major_and_strategic_roads sf object
# The goal is essentially to create an sf object of Major and Strategic roads in study area MSOAs
# containing only roads which existed during the study period
# Even though we do almost exactly this in the clip_data_alspac script,
# we can't just read in the roads_clip.shp output from the clip_data_alspac script because that only contains roads in the 
# study area with 1km buffer, rather than roads in all MSOAs with some part intersecting the study area with 1km buffer (which is what we 
# mean by "study area MSOAs"
# Here we achieve this goal, except for cases where a Major Road is in an MSOA which intersects the study area with 1km buffer, but the road 
# is not actually in the study area with 1km buffer, AND was built after the study period

##### Pasting Jay's stuff from clip_data_alspac with some adjustments
# The point of this section is to remove some road segments we know came after the study area, as described above

major_and_strategic_roads_vect <- vect(major_and_strategic_roads)

roads_values <- values(major_and_strategic_roads_vect) %>%
  as_tibble

#restrict attention to the A4174
A4174 <- subset(major_and_strategic_roads_vect, major_and_strategic_roads_vect$road == "A4174")
#extract geometries and turn into a tibble
A4174_geom <- geom(A4174) %>%
  as_tibble
plot(A4174) #Colliters Way is basically everything between the roundabout near (355000, 170000) to partway down the road around (357000, 169000).  We need to determine the ID's that correspond to these parts of the roads

A4174_geom_filter <- A4174_geom %>% 
  filter(x < 357500) %>% # restrict attention to only the parts of the A4174 that we care about.  
  pull(geom) %>%
  unique

plot(A4174[A4174_geom_filter]) #plot restricted A4174
for(index in A4174_geom_filter) { #plot indices corresponding to each geom.
  text(A4174[index], index) 
}
# from the plot above, we can eyeball the indices that correspond to Colliter's Way.  We hard-code them in the vector below 
indices_to_pull <- c(173:181, 238:244)
plot(A4174[indices_to_pull]) #plot the geoms we want to remove as a sanity check.  Looks good.
ids_to_remove <- A4174$id[indices_to_pull] 

`%notin%` <- Negate(`%in%`)

major_and_strategic_roads_vect_filtered <- major_and_strategic_roads_vect[major_and_strategic_roads_vect$id %notin% ids_to_remove]

######################### A4320: a particular subsection of this road was built during the study period, and completed in 1994.  This road is a less complex shape, so we do not need to mess with object indices to identify the part we want to remove - we just choose a vertical cutoff, and remove all of the road below it. 

A4320 <- subset(major_and_strategic_roads_vect, major_and_strategic_roads_vect$road == "A4320")
plot(A4320, col = 'blue')

A4320_geom <- geom(A4320) %>%
  as_tibble
A4320_geom_filter <- A4320_geom %>%  # pull geom ID's to be removed
  filter(y < 172500 ) %>% 
  pull(geom) %>%
  unique

plot(A4320[A4320_geom_filter]) #plot the part of A4320 to remove.  Looks good
indices_to_pull <- A4320_geom_filter
ids_to_remove <- A4320$id[indices_to_pull] 

major_and_strategic_roads_vect_filtered <- major_and_strategic_roads_vect_filtered[major_and_strategic_roads_vect_filtered$id %notin% ids_to_remove]

######################### Strategic roads data tells us when road segments were built. Remove all road segments built 1996 onwards

ids_to_remove <- strategic_roads_raw %>%
  filter(start_date > as.Date("1996-01-01")) %>%
  pull(sect_label)

major_and_strategic_roads_vect_filtered <- major_and_strategic_roads_vect_filtered[major_and_strategic_roads_vect_filtered$id %notin% ids_to_remove]

major_and_strategic_roads_filtered <- st_as_sf(major_and_strategic_roads_vect_filtered)



######################### ROAD COUNT AND LENGTH FOR MSOAS
# Now we calculate the road counts and road lengths by MSOA

# Here we have a function which will take a given roads file (containing different types of roads)
# and will process it into road lengths of each type in each MSOA, either buffering the MSOAs or not (depending on 
# whether or not the buffer argument to the function is TRUE).
# Note also that the national argument to the function controls which MSOA sf object is used - the one for the whole 
# country, or for just the study area. If you make the mistake of using the whole country MSOA sf object with roads data for just 
# the study area, you will end up in a situation where some of your NAs (those for MSOAs in areas covered by the roads data)  
# represent zeroes, while others represent actual missing values (i.e., for MSOAs in areas not covered by the roads data) 

# If the buffer argument is TRUE, the variable names (aside from msoa11cd and msoa_name) will end in _buffered to indicate that 
# they are for buffered MSOAs
# But few other adjustments need to be made outside the function also for different variables

get_road_lengths_msoa <- function(road_data, road_type_col, national, buffer) {
  
  if (national == TRUE) {
    
    msoa_file <- sf_msoa
    
  } else {
    
    msoa_file <- sf_msoa_study_area
    
  }
  
  if (buffer == TRUE) {
    
    msoa_file <- st_transform(msoa_file, crs = 7801) %>%
      st_buffer(., dist = 3000) %>%
      st_transform(crs = 27700)
    
  }
  
  road_lengths_msoa <- st_intersection(road_data, msoa_file) %>% 
    # this function breaks each line into components corresponding to which segments of the line lie in each of the polygons in spatial_pollution_clip_for_join.  That is, if a line in roads_clip_prefilter lies across two MSOAs in spatial_pollution_clip_for_join, the function will split it into two separate geometries: each corresponding to whichever MSOA it lies in. Thus roads_by_msoa is bigger than roads_clip_prefilter
    # This gives us road segment x MSOA pairs as rows
    # Each row contains information about a road segment in major_roads
    # There can be multiple rows for a single roads_msoa road segment. This will be the case if the road segment intersects multiple MSOAs
    # For each road segment x MSOA pair row the geometry column describes the geometry of the section of that road segment which passes 
    # through that MSOA
    mutate(length_measured_m = as.numeric(st_length(geometry))) %>%
    # For each road segment x MSOA pair row, compute the length of the section of that road segment which passes 
    # through that MSOA
    group_by(msoa11cd, !!sym(road_type_col)) %>%
    summarize(msoa_name = unique(msoa_name),
              road_length_m = sum(length_measured_m),
              road_count = length(unique(road))) %>%
    # for each MSOA, sum the length of all road segments in that MSOA
    # and count the number of unique road names which appear amongst the road names of road segments in that MSOA
    st_drop_geometry() %>%
    # We don't require the geometry for this object
    
    pivot_wider(names_from = !!sym(road_type_col), values_from = road_length_m:road_count) %>%
    # pivot to create columns for different types of roads
    
    left_join(msoa_file, .) %>%
    mutate(across(.cols = where(is.numeric), .fns = ~ifelse(is.na(.), 0, .))) %>%
    # Any MSOA without roads will have NA in the road_count and road_length columns. Those NAs actually represent 0s
    st_drop_geometry()
  
  if (buffer == TRUE) {
    
    road_lengths_msoa <- road_lengths_msoa %>%
      rename_with(.fns = ~paste(., "_buffered", sep = ""), .cols = -c("msoa11cd", "msoa_name"))
    
  }
  
  road_lengths_msoa
  
}

# Get road lengths and counts for non-buffered MSOAs

major_and_strategic_roads_msoa <- get_road_lengths_msoa(major_and_strategic_roads,
                                                        road_type_col = "road_type", 
                                                        national = TRUE,
                                                        buffer = FALSE)

major_and_strategic_roads_filtered_msoa <- get_road_lengths_msoa(major_and_strategic_roads_filtered,
                                                                 road_type_col = "road_type", 
                                                                 national = FALSE,
                                                                 buffer = FALSE) %>%
  rename_with(.fn = ~paste(., "_study_period", sep = ""),
              .cols = contains("road"))

m_a_b_roads_msoa_study_area <- get_road_lengths_msoa(open_roads_ST, 
                                                     road_type_col = "road_type", 
                                                     national = FALSE,
                                                     buffer = FALSE) %>%
  dplyr::select(-road_count_Other)
  
primary_roads_msoa_study_area <- get_road_lengths_msoa(open_roads_ST, 
                                                       road_type_col = "primary", 
                                                       national = FALSE,
                                                       buffer = FALSE) %>%
  dplyr::select(-road_count_non_primary)

# Get road lengths and counts for buffered MSOAs
# 
# major_and_strategic_roads_msoa_buffer <- get_road_lengths_msoa(road_data = major_and_strategic_roads, 
#                                                                road_type_col = "road_type", 
#                                                                national = TRUE,
#                                                                buffer = TRUE)
# 
# major_and_strategic_roads_filtered_msoa_buffer <- get_road_lengths_msoa(road_data = major_and_strategic_roads_filtered, 
#                                                                  road_type_col = "road_type", 
#                                                                  national = FALSE,
#                                                                  buffer = TRUE) %>%
#   rename_with(.fn = ~paste(., "_study_period", sep = ""),
#               .cols = -c("msoa11cd", "msoa_name"))
# 
# primary_roads_msoa_study_area_buffer <- get_road_lengths_msoa(road_data = open_roads_ST, 
#                                                               road_type_col = "road_type", 
#                                                               national = FALSE,
#                                                               buffer = TRUE) %>%
#   dplyr::select(-road_count_Other_buffer)
# 
# primary_roads_msoa_study_area_buffer <- get_road_lengths_msoa(road_data = open_roads_ST, 
#                                                                road_type_col = "primary", 
#                                                                national = FALSE,
#                                                                buffer = TRUE) %>%
#   dplyr::select(-road_count_non_primary_buffer)

# Merge roads variables from above dataframes along with MSOA land area and geometry to compute neighbours variables and densities
roads_land_area_msoa_sf <- left_join(major_and_strategic_roads_msoa, major_and_strategic_roads_filtered_msoa) %>%
  left_join(., m_a_b_roads_msoa_study_area) %>%
  left_join(., primary_roads_msoa_study_area) %>%
  dplyr::select(-contains("count"), contains("count")) %>%
  left_join(., land_area_msoa) %>%
  left_join(., sf_msoa) %>%
  st_as_sf() # %>%
  # left_join(., major_and_strategic_roads_msoa_buffer) %>%
  # left_join(., major_and_strategic_roads_filtered_msoa_buffer) %>%
  # left_join(., m_a_b_roads_msoa_study_area_buffer) %>%
  # left_join(., primary_roads_msoa_study_area_buffer)

# Identify each MSOA's neighbours (by their index numbers in the roads_land_area_msoa_sf object)
neighbours_msoa <- st_intersects(roads_land_area_msoa_sf, roads_land_area_msoa_sf)

# Sum road lengths and counts across each MSOA and its neighbours and take densities 
# Select out non-density columns, but keep area denominator

roads_msoa <- roads_land_area_msoa_sf %>%
  mutate(across(.cols = c(road_length_m_major:road_count_primary,
                          area), 
                .fns = ~sapply(neighbours_msoa, function(n){sum(.x[n], na.rm = TRUE)}),
                .names = "{.col}_neighbours")) %>%
  # Take densities, making sure to divide greater MSOA variables by the greater MSOA area
  mutate(across(.cols = road_length_m_major:road_count_primary, 
                .fns = ~./area, 
                .names = "{.col}_density"),
         across(.cols = road_length_m_major_neighbours:road_count_primary_neighbours, 
                .fns = ~./area_neighbours, 
                .names = "{.col}_density")) %>%
  st_drop_geometry() %>%
  dplyr::select(-c(road_length_m_major:road_count_primary, road_length_m_major_neighbours:road_count_primary_neighbours))


roads_msoa %>%
  write_csv("data_processed/roads_msoa.csv")


rm(major_roads, strategic_roads_raw, strategic_roads, major_and_strategic_roads, open_roads_ST, major_and_strategic_roads_filtered,
   major_and_strategic_roads_msoa, major_and_strategic_roads_filtered_msoa, m_a_b_roads_msoa_study_area, primary_roads_msoa_study_area)










############### OLD WORK, BEFORE CREATING THE FUNCTION TO COVER ALL FOUR OF THESE CHUNKS
# 
# major_and_strategic_roads_msoa <- st_intersection(major_and_strategic_roads, sf_msoa) %>% # this function breaks each line into components corresponding to which segments of the line lie in each of the polygons in spatial_pollution_clip_for_join.  That is, if a line in roads_clip_prefilter lies across two MSOAs in spatial_pollution_clip_for_join, the function will split it into two separate geometries: each corresponding to whichever MSOA it lies in. Thus roads_by_msoa is bigger than roads_clip_prefilter
#   # This gives us road segment x MSOA pairs as rows
#   # Each row contains information about a road segment in major_roads
#   # There can be multiple rows for a single roads_msoa road segment. This will be the case if the road segment intersects multiple MSOAs
#   # For each road segment x MSOA pair row the geometry column describes the geometry of the section of that road segment which passes 
#   # through that MSOA
#   mutate(length_measured_m = as.numeric(st_length(geometry))) %>%
#   # For each road segment x MSOA pair row, compute the length of the section of that road segment which passes 
#   # through that MSOA
#   group_by(msoa11cd, road_type) %>%
#   summarize(msoa_name = unique(msoa_name),
#             road_length_m = sum(length_measured_m),
#             road_count = length(unique(road))) %>%
#   # for each MSOA, sum the length of all road segments in that MSOA
#   # and count the number of unique road names which appear amongst the road names of road segments in that MSOA
#   st_drop_geometry() %>%
#   # We don't require the geometry for this object because we'll get it in the left_join below
#   
#   pivot_wider(names_from = road_type, values_from = road_length_m:road_count) %>%
#   # pivot to create columns for different types of roads
#   
#   left_join(sf_msoa, .) %>%
#   mutate(across(.cols = where(is.numeric), .fns = ~ifelse(is.na(.), 0, .))) %>%
#   # Any MSOA without roads will have NA in the road_count and road_length columns. Those NAs actually represent 0s
#   st_drop_geometry()
# 
# ######## Same thing as above, but with the filtered version of the roads sf object
# # See the notes above on what EXACTLY "filtering" the roads sf object means in this context 
# # Also, filtered to study area MSOAs, because the study period only really makes sense in the context of the study area
# 
# major_and_strategic_roads_filtered_msoa <- st_intersection(major_and_strategic_roads_filtered, sf_msoa_study_area) %>% # this function breaks each line into components corresponding to which segments of the line lie in each of the polygons in spatial_pollution_clip_for_join.  That is, if a line in roads_clip_prefilter lies across two MSOAs in spatial_pollution_clip_for_join, the function will split it into two separate geometries: each corresponding to whichever MSOA it lies in. Thus roads_by_msoa is bigger than roads_clip_prefilter
#   # This gives us road segment x MSOA pairs as rows
#   # Each row contains information about a road segment in major_roads
#   # There can be multiple rows for a single roads_msoa road segment. This will be the case if the road segment intersects multiple MSOAs
#   # For each road segment x MSOA pair row the geometry column describes the geometry of the section of that road segment which passes 
#   # through that MSOA
#   mutate(length_measured_m = as.numeric(st_length(geometry))) %>%
#   # For each road segment x MSOA pair row, compute the length of the section of that road segment which passes 
#   # through that MSOA
#   group_by(msoa11cd, road_type) %>%
#   summarize(msoa_name = unique(msoa_name),
#             road_length_m = sum(length_measured_m),
#             road_count = length(unique(road))) %>%
#   # for each MSOA, sum the length of all road segments in that MSOA
#   # and count the number of unique road names which appear amongst the road names of road segments in that MSOA
#   st_drop_geometry() %>%
#   # We don't require the geometry for this object because we'll get it in the left_join below
#   rename_with(.fn = ~paste(., "_study_period", sep = ""),
#               .cols = road_length_m:road_count) %>%
#   
#   pivot_wider(names_from = road_type, values_from = road_length_m_study_period:road_count_study_period) %>%
#   # pivot to create columns for different types of roads
#   
#   left_join(sf_msoa_study_area, .) %>%
#   mutate(across(.cols = where(is.numeric), .fns = ~ifelse(is.na(.), 0, .))) %>%
#   # Any MSOA without roads will have NA in the road_count and road_length columns. Those NAs actually represent 0s
#   st_drop_geometry()
# 
# ######## Same thing as above, but with the Open Roads data, using road class
# # Note, we have done nothing here to account for the fact that some roads were built after the study period
# # Note also, this is a template we can apply to the Open Roads data for the whole country if we want to
# 
# m_a_b_roads_msoa_study_area <- st_intersection(open_roads_ST, sf_msoa_study_area) %>% # this function breaks each line into components corresponding to which segments of the line lie in each of the polygons in spatial_pollution_clip_for_join.  That is, if a line in roads_clip_prefilter lies across two MSOAs in spatial_pollution_clip_for_join, the function will split it into two separate geometries: each corresponding to whichever MSOA it lies in. Thus roads_by_msoa is bigger than roads_clip_prefilter
#   # This gives us road segment x MSOA pairs as rows
#   # Each row contains information about a road segment in major_roads
#   # There can be multiple rows for a single roads_msoa road segment. This will be the case if the road segment intersects multiple MSOAs
#   # For each road segment x MSOA pair row the geometry column describes the geometry of the section of that road segment which passes 
#   # through that MSOA
#   mutate(length_measured_m = as.numeric(st_length(geometry))) %>%
#   # For each road segment x MSOA pair row, compute the length of the section of that road segment which passes 
#   # through that MSOA
#   group_by(msoa11cd, road_type) %>%
#   summarize(msoa_name = unique(msoa_name),
#             road_length_m = sum(length_measured_m),
#             road_count = length(unique(road))) %>%
#   # for each MSOA, sum the length of all road segments in that MSOA
#   # and count the number of unique road names which appear amongst the road names of road segments in that MSOA
#   st_drop_geometry() %>%
#   # We don't require the geometry for this object because we'll get it in the left_join below
#   
#   pivot_wider(names_from = road_type, values_from = road_length_m:road_count) %>%
#   # pivot to create columns for different types of roads
#   
#   dplyr::select(-road_count_Other) %>%
#   # Given the number of NAs amongst these road names, the road count isn't very meaningful
#   left_join(sf_msoa_study_area, .) %>%
#   mutate(across(.cols = where(is.numeric), .fns = ~ifelse(is.na(.), 0, .))) %>%
#   # Any MSOA without roads will have NA in the road_count and road_length columns. Those NAs actually represent 0s
#   st_drop_geometry()
# 
# ######## Same thing as above, but with the Open Roads data, using primary road or not
# 
# primary_roads_msoa_study_area <- st_intersection(open_roads_ST, sf_msoa_study_area) %>% # this function breaks each line into components corresponding to which segments of the line lie in each of the polygons in spatial_pollution_clip_for_join.  That is, if a line in roads_clip_prefilter lies across two MSOAs in spatial_pollution_clip_for_join, the function will split it into two separate geometries: each corresponding to whichever MSOA it lies in. Thus roads_by_msoa is bigger than roads_clip_prefilter
#   # This gives us road segment x MSOA pairs as rows
#   # Each row contains information about a road segment in major_roads
#   # There can be multiple rows for a single roads_msoa road segment. This will be the case if the road segment intersects multiple MSOAs
#   # For each road segment x MSOA pair row the geometry column describes the geometry of the section of that road segment which passes 
#   # through that MSOA
#   mutate(length_measured_m = as.numeric(st_length(geometry))) %>%
#   # For each road segment x MSOA pair row, compute the length of the section of that road segment which passes 
#   # through that MSOA
#   group_by(msoa11cd, primary) %>%
#   summarize(msoa_name = unique(msoa_name),
#             road_length_m = sum(length_measured_m),
#             road_count = length(unique(road))) %>%
#   # for each MSOA, sum the length of all road segments in that MSOA
#   # and count the number of unique road names which appear amongst the road names of road segments in that MSOA
#   st_drop_geometry() %>%
#   # We don't require the geometry for this object because we'll get it in the left_join below
#   
#   pivot_wider(names_from = primary, values_from = road_length_m:road_count) %>%
#   # pivot to create columns for different types of roads
#   
#   dplyr::select(-road_count_non_primary) %>%
#   # Given the number of NAs amongst these road names, the road count isn't very meaningful
#   left_join(sf_msoa_study_area, .) %>%
#   mutate(across(.cols = where(is.numeric), .fns = ~ifelse(is.na(.), 0, .))) %>%
#   # Any MSOA without roads will have NA in the road_count and road_length columns. Those NAs actually represent 0s
#   st_drop_geometry()









# tm_shape(alspac_study_area) +
# tm_borders(lwd = 2) +
# tm_shape(open_roads_ST) +
# tm_lines(col = "road_type",
#          palette = "Dark2") +
#   tm_shape(sf_msoa_study_area %>% filter(msoa11cd == "E02004634")) +
#   tm_borders(lwd = 2)
