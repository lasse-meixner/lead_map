
# Function to get US census data (Decennial Census and ACS) and feature geometry for a given geographical level

source("00_agg_funcs.R")

get_census_data_us <- function(geography_type, state_str = NULL) {
  
  # First, we get the variables we need from the 2010 Decennial Census
  # We do NOT include the feature geometry (args: geometry=FALSE) in this call. If this is ever changed, consider using shift_geometry() to adjust the feature geometry for Alaska and Hawaii so that they appear under the rest of US on a map
  # Filter out Puerto Rico data (we do this in all of the calls)
  
  dec_2010 <- get_decennial(
    geography = geography_type,
    state = state_str,
    variables = c(urban_ppl_prop = "PCT002002"),
    year = 2010,
    output = "wide",
    geometry = FALSE,
    resolution = "20m") %>%
    filter(substr(GEOID, 1, 2) != 72) %>%
    mutate(urban_ppl_prop = urban_ppl_prop / 100, 
           urban_majority = ifelse(urban_ppl_prop > 0.5, 1, 0))
    # shift_geometry()
  
  # Next we get the variables we need from the 2000 decennial census (age of householder data which isn't available in the 2010 decennial census)
  # These are commented out because they are all missing...
  
  # dec_2000 <- get_decennial(
  #   geography = geography_type,
  #   state = state_str,
  #   variables = c(frp_u24_lone_female_householder_of_fam_prop = "PCT003022",
  #                 frp_25to34_lone_female_householder_of_fam_prop = "PCT003023",
  #                 frp_35to44_lone_female_householder_of_fam_prop = "PCT003024",
  #                 frp_45to54_lone_female_householder_of_fam_prop = "PCT003025",
  #                 frp_55to59_lone_female_householder_of_fam_prop = "PCT003026",
  #                 frp_59to64_lone_female_householder_of_fam_prop = "PCT003027",
  #                 frp_65to74_lone_female_householder_of_fam_prop = "PCT003028",
  #                 frp_75plus_lone_female_householder_of_fam_prop = "PCT003029",
  #                 total_lone_female_householder_of_fam = "PCT003021"),
  #   year = 2000,
  #   output = "wide",
  #   geometry = FALSE) %>%
  #   filter(substr(GEOID, 1, 2) != 72) %>%
  #   mutate(across(.cols = frp_u24_lone_female_householder_of_fam_prop:frp_75plus_lone_female_householder_of_fam_prop, ~. / total_lone_female_householder_of_fam))
  
  # Next we get the variables we need from the 2020 ACS estimates
  # Select out the margin of error columns (the ACS collects a sample from the American population which is 
  # intended to be usable down to the block group level. It is not a survey of the entire population like the decennial census is, 
  # so the ACS data consists of ESTIMATES of population values of variables)
  # If it's useful to have the margin of error columns we can adjust the line where they are selected out 
  # so that they are readded at the end of the data frame (removing the select line altogether would interfere with the rest
  # of the processing)
  
  acs <- get_acs(geography = geography_type,
                 state = state_str,
                 # TODO: Should we not query for an earlier year than the default = 2021?
                 variables = c(median_annual_income = "B06011_001",
                               renter_occupied_hu = "B25003_003",
                               total_occupied_hu = "B25003_001",
                               poor_fam = "B17010_002",
                               total_fam = "B17010_001",
                               lone_parent_female_fam_w_kids = "B11003_016",
                               lone_parent_male_fam_w_kids = "B11003_010",
                               married_fam_w_kids = "B11003_003",
                               # compute total_fam_w_kids as the sum of the above three
                               married_recent_mother = "B13014_003",
                               total_recent_mother = "B13014_002",
                               total_ppl_acs20 = "B01003_001",
                               black_ppl = "B02001_003",
                               white_ppl = "B02001_002",
                               house_price_median = "B25077_001",
                               # note, for the UK you currently get an average of median house price from 1995-2021
                               # here you just have the estimated median value for 2020
                               bp_pre_1939 = "B25034_011", 
                               bp_1940_1949 = "B25034_010", 
                               bp_1950_1959 = "B25034_009",
                               bp_1960_1969 = "B25034_008",
                               bp_1970_1979 = "B25034_007", 
                               bp_1980_1989 = "B25034_006",
                               bp_1990_1999 = "B25034_005", 
                               bp_2000_2009 = "B25034_004",
                               bp_2010_2013 = "B25034_003",
                               bp_post_2014 = "B25034_002", 
                               all_properties = "B25034_001", 
                               build_year_median_dodgy = "B25035_001",
                               # Note, although we get this build_year_median_dodgy variable from the API,
                               # it seems better to just use our own median imputation. The build_year_median_dodgy
                               # column has some unexplained missing values (and weirdly, although fixably, imputes as 0
                               # the median build year for all ZCTAs where the median build year is pre-1939). Our median
                               # imputation agrees with the build_year_median_dodgy column to within one or two years almost always
                               under_yo5_male_ppl = "B01001_003", 
                               yo5to9_male_ppl = "B01001_004",
                               yo10to14_male_ppl = "B01001_005",
                               yo15to17_male_ppl = "B01001_006",
                               under_yo5_female_ppl = "B01001_027",
                               yo5to9_female_ppl = "B01001_028",
                               yo10to14_female_ppl = "B01001_029",
                               yo15to17_female_ppl = "B01001_030",
                               sub_grade_9_ppl_male_18to24 = "B15001_004",
                               sub_grade_9_ppl_male_25to34 = "B15001_012",
                               sub_grade_9_ppl_male_35to44 = "B15001_020",
                               sub_grade_9_ppl_female_18to24 = "B15001_045",
                               sub_grade_9_ppl_female_25to34 = "B15001_053",
                               sub_grade_9_ppl_female_35to44 = "B15001_061",
                               grade_9to12_no_diploma_ppl_male_18to24 = "B15001_005",
                               grade_9to12_no_diploma_ppl_male_25to34 = "B15001_013",
                               grade_9to12_no_diploma_ppl_male_35to44 = "B15001_021",
                               grade_9to12_no_diploma_ppl_female_18to24 = "B15001_046",
                               grade_9to12_no_diploma_ppl_female_25to34 = "B15001_054",
                               grade_9to12_no_diploma_ppl_female_35to44 = "B15001_062",
                               hs_grad_ppl_male_18to24 = "B15001_006",
                               hs_grad_ppl_male_25to34 = "B15001_014",
                               hs_grad_ppl_male_35to44 = "B15001_022",
                               hs_grad_ppl_female_18to24 = "B15001_047",
                               hs_grad_ppl_female_25to34 = "B15001_055",
                               hs_grad_ppl_female_35to44 = "B15001_063",
                               some_college_no_degree_ppl_male_18to24 = "B15001_007",
                               some_college_no_degree_ppl_male_25to34 = "B15001_015",
                               some_college_no_degree_ppl_male_35to44 = "B15001_023",
                               some_college_no_degree_ppl_female_18to24 = "B15001_048",
                               some_college_no_degree_ppl_female_25to34 = "B15001_056",
                               some_college_no_degree_ppl_female_35to44 = "B15001_064",
                               associate_degree_ppl_male_18to24 = "B15001_008",
                               associate_degree_ppl_male_25to34 = "B15001_016",
                               associate_degree_ppl_male_35to44 = "B15001_024", 
                               associate_degree_ppl_female_18to24 = "B15001_049",
                               associate_degree_ppl_female_25to34 = "B15001_057",
                               associate_degree_ppl_female_35to44 = "B15001_065",
                               bachelor_degree_ppl_male_18to24 = "B15001_009",
                               bachelor_degree_ppl_male_25to34 = "B15001_017",
                               bachelor_degree_ppl_male_35to44 = "B15001_025", 
                               bachelor_degree_ppl_female_18to24 = "B15001_050",
                               bachelor_degree_ppl_female_25to34 = "B15001_058",
                               bachelor_degree_ppl_female_35to44 = "B15001_066",
                               graduate_degree_ppl_male_18to24 = "B15001_010",
                               graduate_degree_ppl_male_25to34 = "B15001_018",
                               graduate_degree_ppl_male_35to44 = "B15001_026", 
                               graduate_degree_ppl_female_18to24 = "B15001_051",
                               graduate_degree_ppl_female_25to34 = "B15001_059",
                               graduate_degree_ppl_female_35to44 = "B15001_067",
                               married_sub_hs_recent_mother = "B13014_004",
                               unmarried_sub_hs_recent_mother = "B13014_010",
                               married_hs_grad_recent_mother = "B13014_005",
                               unmarried_hs_grad_recent_mother = "B13014_011",
                               married_some_college_or_associate_degree_recent_mother = "B13014_006",
                               unmarried_some_college_or_associate_degree_recent_mother = "B13014_012",
                               married_bachelor_degree_recent_mother = "B13014_007",
                               unmarried_bachelor_degree_recent_mother = "B13014_013", 
                               married_graduate_degree_recent_mother = "B13014_008",
                               unmarried_graduate_degree_recent_mother = "B13014_014"),
                 output = "wide",
                 year = 2020) %>%
    filter(substr(GEOID, 1, 2) != 72) %>%
    select(-ends_with("M")) %>%
    mutate(renter_occupied_hu_propE = renter_occupied_huE / total_occupied_huE, 
           poor_fam_propE = poor_famE / total_famE,
           total_fam_w_kidsE = lone_parent_female_fam_w_kidsE + lone_parent_male_fam_w_kidsE + married_fam_w_kidsE,
           lone_parent_female_fam_w_kids_propE = lone_parent_female_fam_w_kidsE / total_fam_w_kidsE,
           white_ppl_propE = white_pplE / total_ppl_acs20E, 
           black_ppl_propE = black_pplE / total_ppl_acs20E,
           across(bp_pre_1939E:all_propertiesE, ~. / all_propertiesE, .names = "{.col}_prop"),
           bp_unkwE_prop = all_propertiesE_prop - rowSums(across(bp_pre_1939E_prop:bp_post_2014E_prop)),
           bp_pre_1949E_prop = bp_pre_1939E_prop + bp_1940_1949E_prop,
           bp_pre_1959E_prop = bp_pre_1949E_prop + bp_1950_1959E_prop,
           bp_pre_1954_prop_imputed = bp_pre_1949E_prop + ((bp_pre_1959E_prop - bp_pre_1949E_prop) / 2),
           bp_pre_1979E_prop = bp_pre_1959E_prop + bp_1960_1969E_prop,
           bp_post_1990E_prop = bp_1990_1999E_prop + bp_2000_2009E_prop + bp_2010_2013E_prop + bp_post_2014E_prop,
           # age levels and proportions
           under_yo5_pplE = under_yo5_male_pplE + under_yo5_female_pplE, 
           yo5to9_pplE = yo5to9_male_pplE + yo5to9_female_pplE,
           yo10to14_pplE = yo10to14_male_pplE + yo10to14_female_pplE,
           yo15to17_pplE = yo15to17_male_pplE + yo15to17_female_pplE,
           male_ppl_u17E = rowSums(across(under_yo5_male_pplE:yo15to17_male_pplE)), 
           female_ppl_u17E = rowSums(across(under_yo5_female_pplE:yo15to17_female_pplE)),
           total_ppl_u17E = male_ppl_u17E + female_ppl_u17E, 
           across(.cols = under_yo5_pplE:yo15to17_pplE, .fns = ~. / total_ppl_u17E, .names = "{.col}_prop"),
           male_ppl_u17_propE = male_ppl_u17E / total_ppl_u17E,
           female_ppl_u17_propE = female_ppl_u17E / total_ppl_u17E,
           avg_siblingsE = total_ppl_u17E / total_fam_w_kidsE,
           ppl_18to44E = rowSums(across(sub_grade_9_ppl_male_18to24E:graduate_degree_ppl_female_35to44E)), 
           # CAN SIMPLIFY THIS USING ACROSS (the division that is)
           sub_grade_9_ppl_18to44_propE = rowSums(across(sub_grade_9_ppl_male_18to24E:sub_grade_9_ppl_female_35to44E)) / ppl_18to44E,
           grade_9to12_no_diploma_ppl_18to44_propE = rowSums(across(grade_9to12_no_diploma_ppl_male_18to24E:grade_9to12_no_diploma_ppl_female_35to44E)) / ppl_18to44E,
           hs_grad_ppl_18to44_propE = rowSums(across(hs_grad_ppl_male_18to24E:hs_grad_ppl_female_35to44E)) / ppl_18to44E,
           some_college_no_degree_ppl_18to44_propE = rowSums(across(some_college_no_degree_ppl_male_18to24E:some_college_no_degree_ppl_female_35to44E)) / ppl_18to44E,
           associate_degree_ppl_18to44_propE = rowSums(across(associate_degree_ppl_male_18to24E:associate_degree_ppl_female_35to44E)) / ppl_18to44E,
           bachelor_degree_ppl_18to44_propE = rowSums(across(bachelor_degree_ppl_male_18to24E:bachelor_degree_ppl_female_35to44E)) / ppl_18to44E,
           graduate_degree_ppl_18to44_propE = rowSums(across(graduate_degree_ppl_male_18to24E:graduate_degree_ppl_female_35to44E)) / ppl_18to44E,
           some_college_or_associate_degree_ppl_18to44_propE = some_college_no_degree_ppl_18to44_propE + associate_degree_ppl_18to44_propE,
           bachelor_or_graduate_degree_ppl_18to44_propE = bachelor_degree_ppl_18to44_propE + graduate_degree_ppl_18to44_propE, 
           sub_hs_recent_mother_propE = (married_sub_hs_recent_motherE + unmarried_sub_hs_recent_motherE) / total_recent_motherE,
           hs_grad_recent_mother_propE = (married_hs_grad_recent_motherE + unmarried_hs_grad_recent_motherE) / total_recent_motherE,
           some_college_or_associate_degree_recent_mother_propE = (married_some_college_or_associate_degree_recent_motherE + unmarried_some_college_or_associate_degree_recent_motherE) /  total_recent_motherE,
           bachelor_degree_recent_mother_propE = (married_bachelor_degree_recent_motherE + unmarried_bachelor_degree_recent_motherE) / total_recent_motherE,
           graduate_degree_recent_mother_propE = (married_graduate_degree_recent_motherE + unmarried_graduate_degree_recent_motherE) / total_recent_motherE,
           married_fam_w_kids_propE = married_fam_w_kidsE / total_fam_w_kidsE, 
           married_recent_mother_propE = married_recent_motherE / total_recent_motherE) %>%
    select(!c(renter_occupied_huE:total_recent_motherE, black_pplE, white_pplE, bp_pre_1939E:all_propertiesE,
              under_yo5_male_pplE:unmarried_graduate_degree_recent_motherE, 
              total_fam_w_kidsE, male_ppl_u17E:total_ppl_u17E, ppl_18to44E)) %>%
    relocate(total_ppl_acs20E, .before = median_annual_incomeE) %>%
    relocate(bp_unkwE_prop, .before = all_propertiesE_prop) %>%
    relocate(c(bp_pre_1949E_prop:bp_post_1990E_prop), .after = all_propertiesE_prop) %>%
    relocate(build_year_median_dodgyE, .after = bp_post_1990E_prop) %>%
    # Note, "Inf" arises from a non-zero value divided by zero. NaN arises from zero divided by zero
    # There are a bunch of entries with nothing in them, so lots of zeroes on numerators and denominators
    replace_with_na_all(condition = ~.x %in% c("Inf")) %>%
    mutate(across(.cols = everything(), .fns = ~ifelse(is.nan(.), NA, .)))
  
  # Now impute build-year mean and median
  # As mentioned previously, our build-year median imputation seems more reliable than the one from the API as regards missing values
  # and is similar where values are not missing
  
  # HERE, YOU MAKE THE CHOICE TO SET THE LOWER LIMIT OF PRE-1939 INTERVAL EQUAL TO 1939 AND THE UPPER LIMIT OF THE POST-2014
  # INTERVAL EQUAL TO 2014
  # YOU COULD MAKE DIFFERENT CHOICES
  
  year_bins_us <- acs %>%
    as.data.frame() %>%
    select(bp_pre_1939E_prop:bp_post_2014E_prop) %>%
    colnames()
  
  start_years_us <- year_bins_us[-1] %>%
    .[-9] %>%
    substr(., 4, 7) %>%
    as.numeric() %>%
    c(1939, ., 2014)
  
  end_years_us <- year_bins_us %>%
    str_sub(., -10, -7) %>%
    as.numeric()
  
  year_intervals_us <- cbind(start_years_us, end_years_us)
  
  # HERE YOU CAN DELETE THE THREE OBJECTS USED TO GET year_intervals
  rm(year_bins_us, start_years_us, end_years_us)
  
  mid_years <- rowMeans(year_intervals_us)
  
  year_col_1st <- grep("bp_pre_1939E_prop", colnames(acs))
  year_col_last <- grep("bp_post_2014E_prop", colnames(acs))
  
  # Impute median build years
  
  for (i in c(1:nrow(acs))) {
    vector_of_frequencies <- unlist(acs[i, year_col_1st:year_col_last], use.names = FALSE)
    acs$build_year_median[i] = get_GroupedMedian(vector_of_frequencies, year_intervals_us)
  }
  
  # Impute mean build years
  
  for (i in c(1:nrow(acs))) {
    acs$build_year_mean[i] = sum(as.data.frame(acs)[i, year_col_1st:year_col_last] * mid_years) / sum(as.data.frame(acs)[i, year_col_1st:year_col_last]) # denom should just be one
  }
  
  # Remove all_propertiesE column (equal to 1 for all rows and relocate build_year_median and build_year_mean)
  acs <- acs %>%
    select(-all_propertiesE_prop) %>%
    relocate(build_year_median, build_year_mean, .after = build_year_median_dodgyE)
  
  # Now, we merge the 2010 Decennial Census data with the ACS data
  # (If the 2000 Decennial Census issue gets sorted out, we merge that as well)
  # This creates a data frame with the feature geometry and any predictors you requested from the Decennial Census and the ACS
  
  # If geometries were pulled: Convert it to an sf object so that you can use the feature geometry
  
  acs_dec <- acs |>
    left_join(dec_2010)
    #left_join(dec_2000)
    #st_as_sf()
  
  acs_dec
  
}
