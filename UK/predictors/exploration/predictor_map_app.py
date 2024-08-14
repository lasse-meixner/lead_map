# This runs a dash app to explore the MSOA level predictors on an interactive MSOA map of England

# Import packages
import pandas as pd
import geopandas as gpd
import plotly.express as px
import pyproj

import dash
from dash import Input, Output


def get_msoa_merged_shapefile():
    msoa = gpd.read_file("../raw_data/shapefiles/msoa/england_msoa_2011_simple.shp") # get the downsampled file
    msoa.to_crs(pyproj.CRS.from_epsg(4326), inplace=True)
    msoa.rename({"code":"msoa11cd", "name":"msoa_name"}, axis=1, inplace=True)
    df = pd.read_csv("../processed_data/combined_msoa.csv")

    # get list of predictor names
    cols = df.columns[3:]
    # merge
    merged = msoa.merge(df, left_on="msoa11cd", right_on="msoa11cd", how="left")
    del msoa, df

    return merged, cols

# auxiliary function to compute empirical quantile in [0,1] and average for risk score
def compute_risk_score(df, predictors):
    # get copy of df
    df_copy = df.copy()
    # compute empirical quantiles by passing through ECDF
    for p in predictors:
        df_copy[p + "_decile"] = df_copy[p].rank(pct=True)
    # compute risk score by taking equal weighting
    df_copy["risk_score"] = df_copy[[p + "_decile" for p in predictors]].mean(axis=1)
    # pass through its own ECDF again
    df_copy["risk_score"] = df_copy["risk_score"].rank(pct=True)
    return df_copy

# load merged file from england_msoa_2011.shp and combined_msoa.csv
merged, cols = get_msoa_merged_shapefile()

# Create app
app = dash.Dash(__name__)

# Create app layout
app.layout = dash.html.Div([
    dash.html.H1("UK Predictors Exploration"),
    # add text input for searching
    dash.html.Div([
        dash.html.H3("Search for MSOA"),
        dash.dcc.Input(
            id="search",
            type="text",
            placeholder="Search for MSOA",
            value="Oxford",
            style={'fontSize': '20px'}
        )
    ]),
    dash.html.Br(),
    dash.html.Div([
        dash.dcc.Tabs([
            dash.dcc.Tab(label = "MSOA predictor map", children=[
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
                dash.html.Div([
                    # loading spinner
                    dash.dcc.Loading(
                    dash.dcc.Graph(id="choropleth")
                    )
                ])
            ]),
            dash.dcc.Tab(label = "Decile Risk Score Map", children=[
                dash.html.Div([
                dash.html.H3("Select Predictors"),
                dash.dcc.Dropdown(
                    id="predictors",
                    options=[{"label": x, "value": x} for x in cols],
                    value=[cols[0]],
                    multi=True,
                    clearable=True,
                    searchable=True
                    ),
                ]),
                dash.html.Div([
                    # loading spinner
                    dash.dcc.Loading(
                    dash.dcc.Graph(id="choropleth_risk")
                    )
                ])
            ])
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
    # subset data based on whether substring is in name IF search is not empty
    if len(search) == 0:
        merged_sub = merged
    else:
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

@app.callback(
    Output("choropleth_risk", "figure"),
    Input("predictors", "value"),
    Input("search", "value")
)
def update_choropleth_risk(predictors, search):
    # subset data based on whether substring is in name IF search is not empty
    if len(search) == 0:
        merged_sub = merged
    else:
        merged_sub = merged[merged["msoa_name_x"].str.contains(search)]
    # compute risk score
    merged_sub = compute_risk_score(merged_sub, predictors)
    # plot
    fig = px.choropleth_mapbox(
        merged_sub,
        # add all predictors' deciles
        hover_data=["msoa_name_x", "risk_score"] + [p + "_decile" for p in predictors],
        geojson=merged_sub.geometry,
        locations=merged_sub.index,
        # center on England
        center={"lat": 52.5, "lon": -1.5},
        # size based on browser window
        height=900,
        color="risk_score",
        color_continuous_scale="RdYlBu_r",
        range_color=(merged_sub["risk_score"].min(), merged_sub["risk_score"].max()),
        mapbox_style="carto-positron",
        zoom=6,
        opacity=0.5,
        labels={"risk_score": "Risk Score"}
    )
    fig.update_layout(margin={"r":0,"t":0,"l":0,"b":0})
    return fig

# Run app
if __name__ == "__main__":
    app.run_server(debug=True)