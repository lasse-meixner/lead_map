# This runs a dash app to explore the tract level predictors on an interactive tract map of the US (by state)

# Import packages
import pandas as pd
import geopandas as gpd
import plotly.express as px
import pyproj
import sys

import dash
from dash import Input, Output

def get_tract_merged_shapefile():
    # try loading shapefile, if not, stop programm and prompt to first run get_tract_geometries.R
    try:
        tracts = gpd.read_file("../predictors/raw_data/shapefiles/us_tracts.shp") # get the downsampled file
    except FileNotFoundError("Shapefile not found in ../predictors/raw_data/shapefiles/: Please run get_tract_geometries.R first."):
        sys.exit(1)

    # check type of TRACT is INT and sort by TRACT
    tracts["TRACT"] = tracts["TRACT"].astype(int)
    tracts.sort_values(by="TRACT", inplace=True)
    tracts.to_crs(pyproj.CRS.from_epsg(4326), inplace=True)
    
    # load combined_tract.csv
    df = pd.read_csv("../predictors/processed_data/combined_tract.csv")
    # check type of TRACT is INT and sort by TRACT
    df["TRACT"] = df["TRACT"].astype(int)
    df.sort_values(by="TRACT", inplace=True)
    
    # get list of predictor names of interest
    area_predictors = ["total_ppl_acs20E", "median_annual_incomeE", "house_price_medianE", "poor_fam_propE", "white_ppl_propE", "black_ppl_propE",
            "bp_pre_1939E_prop", "bp_pre_1949E_prop", "bp_pre_1959E_prop", "bp_pre_1979E_prop", "bp_post_1990E_prop", "build_year_median", 
            "under_yo5_ppl_propE", "yo5to9_ppl_propE", "yo10to14_ppl_propE", "yo15to17_ppl_propE", "urban_ppl_prop", "hs_grad_ppl_18to44_propE"]
    df = df[["TRACT", "COUNTY", "STATE", "REPORTING_YEAR"] + area_predictors]
    
    #TODO: handle YEARS in tri: select all entries that have REPORTING_YEAR as NA or == 2015
    df = df[df["REPORTING_YEAR"].isna() | (df["REPORTING_YEAR"] == 2015)]

    # merge
    merged = tracts.merge(df, left_on="TRACT", right_on="TRACT", how="left")
    # drop
    del tracts, df

    return merged, area_predictors

# load merged file from tract.shp and combined_tract.csv
merged, area_predictors = get_tract_merged_shapefile()

# Create app
app = dash.Dash(__name__)

# Create app layout

#TODO: add elements to the layout and lesgo
# could try US as a whole or by state (comparison?) - or both in two different tabs?
# other elements: dropdowns for different predictors
# other elements: predictor histograms
# other elements: correlation graphs

app.layout = dash.html.Div([
    dash.html.H1("US Predictors Exploration"),
    dash.html.Div([
        dash.html.Div([
        dash.html.H2("Select Predictor"),
        dash.dcc.Dropdown(
            id="predictor",
            options=[{"label": x, "value": x} for x in area_predictors],
            value=area_predictors[0],
            clearable=True,
            searchable=True
            ),
        ]),
        # add test input for searching a certain state
        dash.html.Div([
            dash.html.H2("Search for State"),
            dash.dcc.Input(
                id="search",
                type="text",
                placeholder="Search for State",
                value="Texas"
            )
        ]),
        dash.html.Div([
            # loading spinner
            dash.dcc.Loading(
            dash.dcc.Graph(id="choropleth")
        )
        ])
    ])
])

# Create app callback
# NOTE: Plotting the whole of US is slow, so this is tried, but there is the option of subsetting data by string matching of the STATE_NAME
@app.callback(
    Output("choropleth", "figure"),
    Input("predictor", "value"),
    Input("search", "value")
)
def update_chloropleth(predictor, search):
    # subset data based on whether substring is in name IF search is not empty
    if len(search) == 0:
        merged_sub = merged.copy()
    else:
        merged_sub = merged[merged["STATE_x"].str.contains(search)]
    # make a chloropleth map using the geometry column and the selected predictor 
    fig = px.choropleth_mapbox(
        merged_sub,
        hover_data=["COUNTY_x", "TRACT", predictor],
        geojson=merged_sub.geometry,
        locations=merged_sub.index,
        color = predictor,
        color_continuous_scale="Viridis",
        range_color=(merged_sub[predictor].min(), merged_sub[predictor].max()),
        mapbox_style="carto-positron",
        zoom=5,
        opacity=0.5,
        labels={predictor: predictor},
        # center on US
        center={"lat": 37.0902, "lon": -95.7129}
    )
    fig.update_layout(margin={"r":0,"t":0,"l":0,"b":0})
    return fig
    
# Run app
if __name__ == "__main__":
    app.run_server(debug=True)



