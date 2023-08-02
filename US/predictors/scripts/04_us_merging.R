# US merging 

# Merge SVI data (the only US non-census, non-spatial data) with census data sf object

data_zcta <- left_join(acs_dec_zcta, svi_zcta, by = c("GEOID" = "ZCTA5"))
