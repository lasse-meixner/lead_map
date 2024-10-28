# AUXILIARY FUNCTION for loading merged UK shapefile data

# imports
import os
import pandas as pd
import geopandas as gpd
import pyproj

# load shapefile and combined data
def get_msoa_merged_shapefile(path_relative_to_UK = "../"):
    # set paths
    shapefile_path = os.path.join(path_relative_to_UK, "raw_data/shapefiles/msoa/england_msoa_2011_simple.shp")
    msoa_path = os.path.join(path_relative_to_UK, "processed_data/combined_msoa.csv")

    # load data
    msoa = gpd.read_file(shapefile_path) # get the downsampled file
    msoa.to_crs(pyproj.CRS.from_epsg(4326), inplace=True)
    msoa.rename({"code":"msoa11cd", "name":"msoa_name"}, axis=1, inplace=True)
    df = pd.read_csv(msoa_path)

    # get list of predictor names
    cols = df.columns[3:]
    # merge
    merged = msoa.merge(df, left_on="msoa11cd", right_on="msoa11cd", how="left")
    del msoa, df

    return merged, cols