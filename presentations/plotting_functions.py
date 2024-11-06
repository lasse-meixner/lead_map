import pandas as pd
import numpy as np
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots

# plot function that shows geospatial distribution of predictor across leeds
def plot_chloropleth(variable, df, location = "Leeds"):
    # filter for leeds
    leeds = df.loc[df["msoa_name_x"].str.contains(location)]

    fig = px.choropleth_mapbox(
        leeds,
        hover_data=["msoa_name_x", variable],
        geojson=leeds.geometry,
        locations=leeds.index,
        # center on England
        center={"lat": 53.801277, "lon": -1.548567},
        # size based on browser window
        color=variable,
        color_continuous_scale="Viridis",
        range_color=(leeds[variable].min(), leeds[variable].max()),
        mapbox_style="carto-positron",
        zoom=9.5,
        opacity=0.4,
        labels={variable: variable}
    )
    #fig.update_layout(margin={"r":0,"t":0,"l":0,"b":0})
    return fig

# plot function that compares variable distribution selected location (e.g. leeds) with rest of UK
def plot_histograms(variable, df, location="Leeds", other_location = "UK", n_bins=16):
    # filter for leeds
    leeds = df.loc[df["msoa_name_x"].str.contains(location)]

    # check if variable containts "*prop"
    if "prop" in variable:
        bin_edges = np.linspace(0, 1, num=11)
    else:
        # Compute custom bin edges using the UK data vector
        bin_edges = np.histogram_bin_edges(df[variable], bins=n_bins)

    # Create a Plotly figure
    fig = go.Figure()
    hist_x_bins = dict(start=bin_edges[0], end=bin_edges[-1], size=(bin_edges[1] - bin_edges[0]))


    # Add histograms to the figure with normalization to show proportions and custom bin edges
    if other_location == "UK":
        fig.add_trace(go.Histogram(x=df[variable], name="UK", histnorm='probability', xbins=hist_x_bins))
    elif isinstance(other_location, str) and other_location != "UK":
        other = df.loc[df["msoa_name_x"].str.contains(other_location)]
        fig.add_trace(go.Histogram(x=other[variable], name=other_location, histnorm='probability', xbins=hist_x_bins))
    else:
        fig.add_trace(go.Histogram(x=leeds[variable], name=location, histnorm='probability', xbins=hist_x_bins))

    # overlay leeds
    fig.add_trace(go.Histogram(x=leeds[variable], name=location, histnorm='probability', xbins=hist_x_bins))

    # Customize the layout
    fig.update_layout(
        title=f"Histogram of {variable}",
        xaxis_title=variable,
        yaxis_title="Proportion",
        barmode='overlay'
        # todo: add tick markers
    )

    # Set the opacity for better visualization
    fig.update_traces(opacity=0.75)

    return fig

def plot_pairs(variables, df, location="Leeds"):
    # filter for leeds
    leeds = df.loc[df["msoa_name_x"].str.contains(location)]
    
    # create pairsplot
    n = len(variables)
    
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
                    go.Histogram(x=leeds[variables[i]], nbinsx=20, histnorm='probability'),
                    row=i+1, col=j+1
                )
            elif i > j:
                # Lower diagonal: Scatter plot
                fig.add_trace(
                    go.Scatter(x=leeds[variables[j]], y=leeds[variables[i]], mode='markers'),
                    row=i+1, col=j+1
                )
                
                # Calculate regression line
                x = leeds[variables[j]]
                y = leeds[variables[i]]
                m, b = np.polyfit(x, y, 1)
                fig.add_trace(
                    go.Scatter(x=x, y=m*x + b, mode='lines', line=dict(color='red')),
                    row=i+1, col=j+1
                )
            else:
                # Upper diagonal: Correlation coefficient
                corr_value = leeds[variables[i]].corr(leeds[variables[j]])
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
                fig.update_xaxes(
                    title_text=variables[j], 
                    row=i+1, 
                    col=j+1)
            if j == 0:
                fig.update_yaxes(
                    title_text=variables[i], 
                    row=i+1, 
                    col=j+1)

    fig.update_layout(
        showlegend=False,
        plot_bgcolor='white',
        hovermode="closest"
    )
    
    return fig


# plot function that compares empirical CDF of variable in selected location (e.g. leeds) with rest of UK
def plot_CDFs(variable, df, location="Leeds"):
    # filter for leeds
    leeds = df.loc[df["msoa_name_x"].str.contains(location)]

    # create common axis
    x = np.linspace(df[variable].min(), df[variable].max(), num=100)

    # Compute the empirical CDF for the UK and Leeds
    y_uk = np.searchsorted(np.sort(df[variable]), x, side='right') / len(df)
    y_leeds = np.searchsorted(np.sort(leeds[variable]), x, side='right') / len(leeds)
    
    # Create a Plotly figure
    fig = go.Figure()
    fig.add_trace(go.Scatter(x=x, y=y_uk, mode='lines', name='UK'))
    fig.add_trace(go.Scatter(x=x, y=y_leeds, mode='lines', name=location))

    # Customize the layout
    fig.update_layout(
        title=f"Empirical CDF of {variable}",
        xaxis_title=variable,
        yaxis_title="Proportion of MSOA",
    )

    return fig


def plot_risk_score(predictors, df, location = "Leeds"):
    # filter for leeds
    leeds = df.loc[df["msoa_name_x"].str.contains(location)]
    # compute risk score
    merged_sub = compute_risk_score(leeds, predictors)
    # plot
    fig = px.choropleth_mapbox(
        merged_sub,
        # add all predictors' deciles
        hover_data=["msoa_name_x", "risk_score"] + [p + "_pctile" for p in predictors],
        geojson=merged_sub.geometry,
        locations=merged_sub.index,
        # center on England
        center={"lat": 53.801277, "lon": -1.548567},
        color="risk_score",
        color_continuous_scale="RdYlBu_r",
        range_color=(merged_sub["risk_score"].min(), merged_sub["risk_score"].max()),
        mapbox_style="carto-positron",
        zoom=9.5,
        opacity=0.4,
        labels={"risk_score": "Risk Score"}
    )
    fig.update_layout(margin={"r":0,"t":0,"l":0,"b":0})
    return fig

## auxiliary function to compute risk score
def compute_risk_score(df, predictors):
    relevant_vars = predictors + ["msoa_name_x", "geometry"]
    # get copy of df
    df_copy = df.copy().loc[:, relevant_vars]
    # compute empirical quantiles by passing through ECDF
    for p in predictors:
        df_copy[p + "_pctile"] = df_copy[p].rank(pct=True)
    # compute risk score by taking equal weighting
    df_copy["risk_score"] = df_copy[[p + "_pctile" for p in predictors]].mean(axis=1)
    # pass through its own ECDF again
    df_copy["risk_score"] = df_copy["risk_score"].rank(pct=True)
    return df_copy