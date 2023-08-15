## read in roads 

temp <- tempfile()
download.file("https://www2.census.gov/geo/tiger/TIGER2021/PRIMARYROADS/tl_2021_us_primaryroads.zip", temp)
unzip(zipfile = temp, exdir = "../raw_data/")
roads <- read_sf("../raw_data/tl_2021_us_primaryroads.shp")

