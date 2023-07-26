# This runs a dash app to explore the MSOA level predictors on an interactive MSOA map of England

# Import packages
import pandas as pd
import geopandas as gpd
import plotly.express as px
import pyproj

import dash
from dash import Input, Output

def get_msoa_merged_shapefile():
    msoa = gpd.read_file("../raw_data/shapefiles/msoa/england_msoa_2011.shp") #10s load
    msoa.to_crs(pyproj.CRS.from_epsg(4326), inplace=True)
    msoa.rename({"code":"msoa11cd", "name":"msoa_name"}, axis=1, inplace=True)
    df = pd.read_csv("../processed_data/combined_msoa.csv")

    # get list of predictor names
    cols = df.columns[3:]
    # merge
    merged = msoa.merge(df, left_on="msoa11cd", right_on="msoa11cd", how="left")
    del msoa, df

    return merged, cols

# load merged file from england_msoa_2011.shp and combined_msoa.csv
merged, cols = get_msoa_merged_shapefile()

# Create app
app = dash.Dash(__name__)

# Create app layout
app.layout = dash.html.Div([
    dash.html.H1("UK Predictors Exploration"),
    dash.html.Div([
        dash.html.Div([
        dash.html.H3("Select Predictor"),
        dash.dcc.Dropdown(
            id="predictor",
            options=[{"label": x, "value": x} for x in cols],
            value=cols[0],
            clearable=True,
            searchable=True
            ),
        ]),
        # add text input for searching
        dash.html.Div([
            dash.html.H3("Search for MSOA"),
            dash.dcc.Input(
                id="search",
                type="text",
                placeholder="Search for MSOA",
                value="Oxford"
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
# NOTE: Plotting the whole of England is too slow, so subset the data by string matching of the name
@app.callback(
    Output("choropleth", "figure"),
    Input("predictor", "value"),
    Input("search", "value")
)
def update_choropleth(predictor, search):

    # subset data based on whether substring is in name
    merged_sub = merged[merged["msoa_name_x"].str.contains(search)]
    # plot
    fig = px.choropleth_mapbox(
        merged_sub,
        hover_data=["msoa_name_x", predictor],
        geojson=merged_sub.geometry,
        locations=merged_sub.index,
        # center on England
        center={"lat": 52.5, "lon": -1.5},
        # size based on browser window
        height=900,
        color=predictor,
        color_continuous_scale="Viridis",
        range_color=(merged_sub[predictor].min(), merged_sub[predictor].max()),
        mapbox_style="carto-positron",
        zoom=6,
        opacity=0.5,
        labels={predictor: predictor}
    )
    fig.update_layout(margin={"r":0,"t":0,"l":0,"b":0})
    return fig

# Run app
if __name__ == "__main__":
    app.run_server(debug=True)