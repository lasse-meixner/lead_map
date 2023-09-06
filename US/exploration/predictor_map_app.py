# This runs a dash app to explore the tract level predictors on an interactive tract map of the US (by state)

# Import packages
import pandas as pd
import geopandas as gpd
import plotly.express as px
import pyproj

import dash
from dash import Input, Output

def get_tract_level_shapefile():
    vars = ["total_ppl_acs20E", "median_annual_incomeE", "house_price_medianE", "poor_fam_propE", "white_ppl_propE", "black_ppl_propE",
            "bp_pre_1939E_prop", "bp_pre_1949E_prop", "bp_pre_1959E_prop", "bp_pre_1979E_prop", "bp_post_1990E_prop", "build_year_median", 
            "under_yo5_ppl_propE", "yo5to9_ppl_propE", "yo10to14_ppl_propE", "yo15to17_ppl_propE", "urban_ppl_prop", "hs_grad_ppl_18to44_propE"]

# TODO: complete variable list, and solve problem of mapping. Perhaps it is easiest to just pull the ACS data with geometries, then separate out the shapefiles: TRACT, STATE, GEOMETRY, continue processing with the rest of the data, and save separately?