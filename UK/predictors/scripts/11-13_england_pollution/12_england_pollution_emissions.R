# This script will compute, for each MSOA, lead emissions via different mediums annually and cumulatively for each year since 1993
# At the end of the script, we will have the above information in wide format with MSOA rows
# We will merge this data with the annual polluter count data (also in wide format with MSOA rows) from script 11

# NOTE: THIS IS COPIED AND PASTED AS FAR AS POSSIBLE FROM JAY'S CODE, SO CONVENTIONS ARE DIFFERENT TO OTHER SCRIPTS IN THIS PROJECT

######################### Load all required packages and datasets
required.packages <- c("tidyverse", "magrittr", "sf", "terra", "tm", "readxl")
lapply(required.packages, require, character.only = TRUE)

`%notin%` <- Negate(`%in%`)

# check if sf_msoa is already in memory (in case prior script has been run), otherwise, read it in
if (exists("sf_msoa")) {
  print("sf_msoa already in memory")
} else {
    sf_msoa <- read_sf("../prep-for-ALSPAC/data/England_msoa_2011/england_msoa_2011.shp")
}

# check if mapping is already in memory (in case prior script has been run), otherwise, read it in
if (exists("mapping")) {
  print("mapping already in memory")
} else {
  mapping <- drive_get("Lead_Map_Project/US/predictors/postcode_centroids_2020.csv") |>
    drive_read_string() |>
    read_csv()
}

# check if pollution is already in memory (in case prior script has been run), otherwise, read it in
if (exists("pollution")) {
  print("pollution already in memory")
} else {
  gdrive_get_file("1992_2008 Pollution Inventory Dataset.xlsx")
  pollution <- read_excel("../raw_data/1992_2008 Pollution Inventory Dataset.xlsx") %>%
  as_tibble()
}


##################################################
# first, clean pollution data

pollution_clean <- pollution %>%
  filter(Substance %in% c("Metals - Group 3 (As+Cr+Cu+Mn+Ni+Pb+Sn)",
                          "Metals - Grp 4(As+Cd+Cr+Co+Cu+Mn+Ni+Pb+Sb+Sn+Tl+V)" ,     
                          "Metals - Group 2 (As+Cr+Co+Cu+Mn+Ni+Pb+Sb+Sn+V)",
                          "Metals - Group 5 (Cr+Cu+Mn+Pb)",
                          "Lead"## ,
                          ## "Lead 210" Lead 210 is a type of radioactive pollution.  Not what we want.
  ),
  !Year == 1992
  ) %>%
  select(year = Year,
         pcd = `Site postcode`,
         address = `Site address`,
         route = Route,
         description = `Recovery or Disposal description`,
         quantity = `Quantity Released`,
         unit = Unit) %>%
  mutate(quantity_kg = case_when( # convert to kg
    unit == "kg" ~ quantity,
    unit == "g"  ~ quantity/1000,
    unit == "mg" ~ quantity/1000000,
    unit == "t"  ~ quantity*1016.05
  )) %>% #1016.05 kilograms per Imperial Ton
  select(-c(quantity, unit))

######################### Format postcodes and fix typos
pollution_clean$pcd <- str_remove_all(pollution_clean$pcd, pattern = fixed(" "))

typos <- c( "B981UB", "BB3ORR", "LE13OJG", "PL4OPX", "PO39JG", "SO509NZ", "ST17OXR", "TN259QB", "TN328AY")
corrections <- c("B987UB", "BB30RR", "LE130JG", "PL40PX", "PO139JG", "SO506NZ", "ST170XR", "TN249QB", "TN388AY")
for(index in 1:length(typos)){
  pollution_clean$pcd[pollution_clean$pcd %in% typos[index]] <- corrections[index]
}
#########################

######################### Begin constructing the desired variables
############ classify both controlled waters and wastewater as "water"
pollution_list <- pollution_clean %>%
  mutate(route = case_when(
    route == "Controlled Waters" ~ "Water",
    route == "Wastewater" ~ "Water",
    route == "Air" ~ "Air",
    route == "Land" ~ "Land",
    route == "Disposal - other" ~ "Disposal")) %>%
  split(.$route)

######################### for each route, construct counts by postcode and year of unique polluting addresses and total emissions in kg.  Then to get cumulative amounts, drop grouping by year and do cumulative sums by postcode only. (Jul 28 '22, 2pm, change the point at which we compute cumulative emissions.  Previously, we were computing the cumulative emissions by postcode and then spatially aggregating to the MSOA level.  This led to some discrepancies in the MSOA per-year emissions and cumulative numbers for some reason.  Now, we compute only per-year emissions at postcode level, do spatial join, then comput the cumulative numbers with the resulting msoa-level series.)  This ensures that the MSOA yearly series add up to the cumulative series in the final output.
pollution_list %<>% purrr::map(~ group_by(., pcd, year) %>%
                                 summarize(n = length(unique(address)),
                                           emissions_by_year = sum(quantity_kg)) %>%
                                 ungroup ## %>%
                               ## group_by(pcd) %>%
                               ## mutate(cumulative_emissions = cumsum(emissions_by_year))
)

######################### Begin constructing variables.  Inelegant, but straightforward approach. Distinguish between onsite emissions and total emissions.

pollution_list_onsite <- pollution_list
pollution_list_onsite$Disposal <- NULL


# total onsite emissions: collapse pollution_list_onsite to a single dataframe.  Then recalculate sums for yearly and cumulative emissions (this time aggregating across routes)
pollution_totals_onsite <- Map(cbind, pollution_list_onsite, route = names(pollution_list_onsite)) %>%
  do.call("rbind",.) %>%
  group_by(pcd, year) %>%
  summarize(emissions_by_year = sum(emissions_by_year)) %>%
  ungroup ## %>% 
## group_by(pcd) %>%
## mutate(cumulative_emissions = cumsum(emissions_by_year))


# total emissions: collapse pollution_list to a single dataframe.  Then recalculate sums for yearly and cumulative emissions (this time aggregating across routes).  These totals include pollution from offsite disposal!!!
pollution_totals <- Map(cbind, pollution_list, route = names(pollution_list)) %>%
  do.call("rbind",.) %>%
  group_by(pcd, year) %>%
  summarize(emissions_by_year = sum(emissions_by_year)) %>%
  ungroup ## %>%
## group_by(pcd) %>%
## mutate(cumulative_emissions = cumsum(emissions_by_year))

# begin loading final storage object and rename variables
export <- pollution_totals
rm(pollution_totals)
export_totals_onsite <- pollution_totals_onsite
rm(pollution_totals_onsite)
export_route_breakdown <- pollution_list
rm(pollution_list)

export_route_breakdown$Air %<>%
  rename(emissions_yearly_air = emissions_by_year## ,
         ## `picumairall250mb-picumair2kmb` = cumulative_emissions
  ) %>%
  select(-n)

export_route_breakdown$Land %<>%
  rename(emissions_yearly_land = emissions_by_year## ,
         ## `picumlandall250mb-picumland2kmb` = cumulative_emissions
  ) %>%
  select(-n)

export_route_breakdown$Water %<>%
  rename(emissions_yearly_water = emissions_by_year## ,
         ## `picumwaterall250mb-picumwater2kmb` = cumulative_emissions
  ) %>%
  select(-n)

export_totals_onsite %<>%
  rename(emissions_total_yearly_onsite = emissions_by_year## ,
         ## `picumonsitetotalall250mb-picumonsitetotal2kmb` = cumulative_emissions
  )

export %<>%
  rename(emissions_total_yearly = emissions_by_year## ,
         ## `picumtotalall250mb-picumtotal2kmb` = cumulative_emissions
  )

export <- left_join(export, export_totals_onsite)
export <- left_join(export, export_route_breakdown$Air)
export <- left_join(export, export_route_breakdown$Land)
export <- left_join(export, export_route_breakdown$Water)

rm(export_totals_onsite, export_route_breakdown)


################################################## For the spatial join: map polluter postcodes to their centroids

mapping$pcd <- str_remove_all(mapping$pcd, pattern = fixed(" "))

export_spatial <- left_join(export, mapping, by = "pcd") %>%
  select(colnames(export), oseast1m, osnrth1m) %>%
  mutate(osnrth1m = as.numeric(osnrth1m)) %>% #typo in dataset - one of the entries in osnrth1m is non-numeric for some reason.
  vect(c("oseast1m", "osnrth1m")) %>%
  st_as_sf
st_crs(export_spatial) <- st_crs(sf_msoa)

######################### execute spatial join, and aggregate from postcode to MSOA level

# Attach an MSOA code to each emitting facility in each year
emissions_w_msoa <- st_join(export_spatial, sf_msoa) %>%
  # we no longer need the geometry, and it takes ages to summarise
  st_drop_geometry()

# Create a panel with emissions data for all MSOA x year combinations which recorded emissions
emissions_panel_some_msoas_some_years <- emissions_w_msoa %>%
  group_by(code, year) %>%
  summarize(across(starts_with("emissions"), ~ sum(.x, na.rm = TRUE))) %>%
  ungroup() 

# Create a df with every MSOA x every year as rows so that you can build panel for all MSOA x year combinations with 
# NAs in the relevant cells when no emissions were recorded in a given year in a given MSOA

all_english_msoas <- sf_msoa %>%
  st_drop_geometry() %>%
  dplyr::select(code, name)

pollution_data_years <- seq(from = 1993, to = 2008) %>%
  as.data.frame() %>%
  rename("year" = 1)

all_msoas_all_years <- merge(all_english_msoas, pollution_data_years)

# Join all_msoas_all_years with emissions_panel so that we have an object with NAs for MSOA x year combinations with no emissions
emissions_panel_all_msoas_all_years <- left_join(all_msoas_all_years, emissions_panel_some_msoas_some_years)

# set imputed NA values to zero
emissions_panel_all_msoas_all_years[is.na(emissions_panel_all_msoas_all_years)] <- 0

# Get cumulative emissions values

emissions_panel_all_msoas_all_years %<>% group_by(code) %>%
  mutate( emissions_cumulative_air = cumsum(emissions_yearly_air),
          emissions_cumulative_land= cumsum(emissions_yearly_land),
          emissions_cumulative_water= cumsum(emissions_yearly_water),
          emissions_total_cumulative_onsite= cumsum(emissions_total_yearly_onsite),
          emissions_total_cumulative= cumsum(emissions_total_yearly))

######################### reshape to wide-format for linkage: need a bijection between rows and MSOA

emissions_panel_wide <- emissions_panel_all_msoas_all_years %>%
  pivot_wider(names_from = year, values_from = starts_with("emissions")) %>%
  as_tibble

## Merge with Polluter Panel for counts of polluters by MSOA.

emissions_polluter_counts_msoa <- left_join(emissions_panel_wide, polluter_counts_panel_wide) %>%
  rename("msoa11cd" = "code",
         "msoa_name" = "name")

rm(emissions_panel_wide, polluter_counts_panel_wide, emissions_panel_all_msoas_all_years, all_msoas_all_years, emissions_panel_some_msoas_some_years, emissions_w_msoa, export_spatial)