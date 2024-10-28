# This runs a dash app to explore the MSOA level predictors on an interactive MSOA map of England

# Import packages
import pandas as pd
import numpy as np
import json

import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots

import dash
from dash import Input, Output
import dash_daq as daq

from shapefile_loading import get_msoa_merged_shapefile

# load merged file from england_msoa_2011.shp and combined_msoa.csv
merged, cols = get_msoa_merged_shapefile(path_relative_to_UK="../")

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

# load metadata.json
with open("../metadata.json", "r") as f:
    metadata = json.load(f)

# auxiliary function to look up information from metadata.json
def find_metadata_info(var_name, key = "source_name"):
    assert key in ["source_name", "source_type", "file_link"]
    for source in metadata.get("sources", []):
        if var_name in source.get("variables", []):
            return source.get(key)
    return None

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
                             dash.html.Div([
                    dash.dcc.Dropdown(
                        id="predictor",
                        options=[{"label": x, "value": x} for x in cols],
                        value=cols[0],
                        clearable=True,
                        searchable=True,
                        style={"width": "400px"}
                    ),
                    dash.html.Label("Log Scale:", style={'marginLeft': '20px', 'marginRight': '10px'}),
                    daq.BooleanSwitch(
                        id='log_switch',
                        on=False
                    ),
                    dash.html.Div([
                        # dash.html.H4("Predictor Metadata"),
                        dash.html.Div([
                            dash.html.Label("Data source:", style={'paddingRight': '10px'}),
                            dash.html.Label(id="source_name_single"),
                            dash.html.Br(),  # Line break
                            dash.html.Label("Preprocessing file:", style={'paddingRight': '10px'}),
                            dash.html.Label(id="file_link_single"),
                        ]),
                    ], style={'marginLeft': '20px'})  # Add some margin to separate metadata from dropdown and button
                ], style={  # Add style to put toggle, predictor selection, and metadata in the same row
                    'display': 'flex',
                    'flexDirection': 'row',
                    'alignItems': 'center',
                    'gap': '50px',
                    'width': '100%',
                    'justifyContent': 'center',
                    'padding': '10px'
                }),
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
                    dash.html.Div([
                        dash.dcc.Dropdown(
                            id="predictors",
                            options=[{"label": x, "value": x} for x in cols],
                            value=[cols[0]],
                            multi=True,
                            clearable=True,
                            searchable=True
                        ),
                    ], style={
                        'display': 'flex',
                        'flexDirection': 'row',
                        'alignItems': 'center'
                    })
                ]),
                dash.html.Div([
                    # loading spinner
                    dash.dcc.Loading(
                        dash.dcc.Graph(id="choropleth_risk")
                    )
                ]),
                dash.html.Div([
                    dash.dcc.Loading(
                        dash.dcc.Graph(id="pairsplot")
                    )
                ])
            ])
        ])
    ])
])

# Create app callbacks

@app.callback(
    [Output('source_name_single', 'children'),
     Output('file_link_single', 'children')],
    [Input('predictor', 'value')]
)
def update_metadata_info_tab1(var_name):
    # Fetch or compute the source name and file link based on the input value
    source_name = find_metadata_info(var_name, key = "source_name")
    file_link = find_metadata_info(var_name, key = "file_link")
    # if file link is a list, join them with a "&"
    if isinstance(file_link, list):
        file_link = " & ".join(file_link)
    return source_name, file_link


# NOTE: Plotting the whole of England is too slow, so subset the data by string matching of the name
@app.callback(
    Output("choropleth", "figure"),
    Input("predictor", "value"),
    Input("search", "value"),
    Input("log_switch", "on")
)
def update_choropleth_tab1(predictor, search, log_scale_on):
    # subset data based on whether substring is in name IF search is not empty
    if len(search) == 0:
        merged_sub = merged
    else:
        merged_sub = merged[merged["msoa_name_x"].str.contains(search)]
    # plot
    if log_scale_on:
        merged_sub[predictor] = merged_sub[predictor].apply(lambda x: np.log(x))

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
def update_choropleth_risk_tab2(predictors, search):
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

@app.callback(
    Output("pairsplot", "figure"),
    Input("predictors", "value"),
    Input("search", "value")
)
def update_pairsplot_tab2(predictors, search):
    # subselect relevant area
    if len(search) == 0:
        merged_sub = merged
    else:
        merged_sub = merged[merged["msoa_name_x"].str.contains(search)]
    
    # create pairsplot
    n = len(predictors)
    
    fig = make_subplots(
        rows=n, cols=n,
        shared_xaxes=False,
        shared_yaxes=False,
        vertical_spacing=0.1,
        horizontal_spacing=0.1
    )
    
    for i in range(n):
        for j in range(n):
            if i == j:
                # Diagonal: Density plot
                fig.add_trace(
                    go.Histogram(x=merged_sub[predictors[i]], nbinsx=20, histnorm='probability'),
                    row=i+1, col=j+1
                )
            elif i > j:
                # Lower diagonal: Scatter plot
                fig.add_trace(
                    go.Scatter(x=merged_sub[predictors[j]], y=merged_sub[predictors[i]], mode='markers'),
                    row=i+1, col=j+1
                )
            else:
                # Upper diagonal: Correlation coefficient
                corr_value = merged_sub[predictors[i]].corr(merged_sub[predictors[j]])
                fig.add_trace(
                    go.Scatter(
                        x=[0.5], y=[0.5],
                        text=[f'Corr:{corr_value:.2f}'],
                        mode='text',
                        textfont=dict(
                            size=20  # Increase the font size
                            )
                    ),
                    row=i+1, col=j+1
                )

            # Update axes
            if i == n-1:
                fig.update_xaxes(title_text=predictors[j], row=i+1, col=j+1)
            if j == 0:
                fig.update_yaxes(title_text=predictors[i], row=i+1, col=j+1)

    fig.update_layout(
        width=900, height=900,
        showlegend=False,
        plot_bgcolor='white',
        hovermode="closest"
    )
    
    return fig


# Run app
if __name__ == "__main__":
    app.run_server(debug=True)