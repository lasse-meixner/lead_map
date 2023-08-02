# Downloading US predictors

# The code in this script downloads raw data for US predictors 
# and look-up tables to the us sub-directory of the data_raw directory 

# Download Social Vulnerability Index data

download.file("https://svi.cdc.gov/Documents/Data/2018_SVI_Data/CSV/SVI2018_US.csv", 
              destfile = "../raw_data/svi_tracts.csv")


# Download Census Bureau relationship file for crosswalking between ZCTAs and census tracts

download.file("https://www2.census.gov/geo/docs/maps-data/data/rel/zcta_tract_rel_10.txt",
              destfile = "../raw_data/tract_zcta_lookup.txt")


# Download HUD/USPS relationship file for crosswalking from zips to census tracts

# Scripts uses the API under this link: https://www.huduser.gov/portal/dataset/uspszip-api.html

# API KEY: eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImp0aSI6IjY1MDZkZjc0NjY2Y2FhN2RiMWRkNWU0NmFkY2ZiZjlkMmU1MzkzOTM0Mjk3Nzk5YWM2MDdiMzc1MzkwMmVlZjJiYTAxMDAyYWZlYjI1NDU5In0.eyJhdWQiOiI2IiwianRpIjoiNjUwNmRmNzQ2NjZjYWE3ZGIxZGQ1ZTQ2YWRjZmJmOWQyZTUzOTM5MzQyOTc3OTlhYzYwN2IzNzUzOTAyZWVmMmJhMDEwMDJhZmViMjU0NTkiLCJpYXQiOjE2OTA5NzQ1NTYsIm5iZiI6MTY5MDk3NDU1NiwiZXhwIjoyMDA2NTkzNzU2LCJzdWIiOiI1NTQwMSIsInNjb3BlcyI6W119.JY3mnI01JF9qsx0N_4MuGhjTa985dP-CUttjjRrcwPPy4OcTl2_5OP257Gv4q6E1cAGlTG7vj1JvBmoLlfHEpQ