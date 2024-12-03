import pandas as pd
import numpy as np
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots

# dictionary that maps variable names to fancy names for plot legends
fancy_names = {
  "total_kids_2011": "Total kids (2011)",
  "total_ppl_u5_totalpop_prop_2011": "% of kids under 5 among total population (2011)",
  "bp_pre_1992_prop": "% built pre 1992",
  "bp_pre_1954_prop": "% built pre 1954",
  "bp_pre_1939_prop": "% built before 1939",
  "house_price_mean_median_2017to2021": "Average House price (2017-2021)",
  "unemployed_16to74_ppl_prop_2011": "Unemployment rate (2011)",
  "imd_overall_score_2015": "IMD (2015)",
  "median_annual_incomeE": "Median annual income",
  "poverty_rateE": "Poverty rate",
  "black_ppl_prop_2011": "% black people (2011)",
  "no_qual_ppl_w_kids_prop_2011": "% unqualified people (2011)",
  "soil_lead_mean": "Soil lead"
}

# plot function that shows geospatial distribution of predictor across leeds
def plot_chloropleth(variable, df, location = "Leeds", **kwargs):
    # filter for leeds
    leeds = df.loc[df["msoa_name_x"].str.contains(location)]

    # hover data default
    hover_data = kwargs.pop("hover_data", ["msoa_name_x", variable])

    fig = px.choropleth_mapbox(
        leeds,
        hover_data=hover_data,
        geojson=leeds.geometry,
        locations=leeds.index,
        # center on England
        center={"lat": 53.801277, "lon": -1.548567},
        # size based on browser window
        color=variable,
        range_color=(leeds[variable].min(), leeds[variable].max()),
        mapbox_style="carto-positron",
        zoom=9.5,
        opacity=0.4,
        labels={variable: fancy_names.get(variable, variable)},
        **kwargs
    )
    fig.update_layout(margin={"r":0,"t":0,"l":0,"b":0})
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
        pass

    # overlay leeds
    fig.add_trace(go.Histogram(x=leeds[variable], name=location, histnorm='probability', xbins=hist_x_bins))

    # Customize the layout
    fig.update_layout(
        title=f"Histogram of {fancy_names.get(variable, variable)}",
        xaxis_title=fancy_names.get(variable, variable),
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
                            size=16  # Increase the font size
                            )
                    ),
                    row=i+1, col=j+1
                )

            # Update axes
            if i == n-1:
                fig.update_xaxes(
                    title_text = fancy_names.get(variables[j], variables[j]),
                    row=i+1, 
                    col=j+1)
            if j == 0:
                fig.update_yaxes(
                    title_text = fancy_names.get(variables[i], variables[i]),
                    row=i+1, 
                    col=j+1
                    )

    fig.update_layout(
        showlegend=False,
        plot_bgcolor='white',
        hovermode="closest"
    )
    
    return fig

# alternative for pairs: heatmap
def plot_heatmap(variables, df, location="Leeds"):
    # filter for leeds
    leeds = df.loc[df["msoa_name_x"].str.contains(location)]
    
     # compute correlation matrix
    corr_matrix = leeds[variables].corr()
    
    # mask the upper triangle
    mask = np.triu(np.ones_like(corr_matrix, dtype=bool)).T
    corr_matrix = corr_matrix.mask(mask)
    
    fig = go.Figure(data=go.Heatmap(
        z=corr_matrix,
        x=[fancy_names.get(v, v) for v in variables],
        y=[fancy_names.get(v, v) for v in variables],
        colorscale='rdbu',
        zmin=-1,
        zmax=1,
        showscale=True
    ))
    
    fig.update_layout(
        title="Correlation Heatmap",
        plot_bgcolor='white',
        paper_bgcolor='white'
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
        title=f"Empirical CDF of {fancy_names.get(variable, variable)}",
        xaxis_title=fancy_names.get(variable, variable),
        yaxis_title="Proportion of MSOA"
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
def compute_risk_score(df, predictors = {"imd_overall_score_2015":1, "bp_pre_1954_prop": 1, "house_price_mean_median_2017to2021": -1, "soil_lead_mean":1}):
    predictors_list = list(predictors.keys())
    relevant_vars = predictors_list + ["msoa_name_x", "geometry", "total_kids_2011"]
    # get copy of df
    df_copy = df.copy().loc[:, relevant_vars]
    # compute empirical quantiles by passing through ECDF
    for p in predictors_list:
        df_copy[p + "_pctile"] = df_copy[p].rank(pct=True)
        if predictors[p] == -1:
            df_copy[p + "_pctile"] = 1 - df_copy[p + "_pctile"]
    # compute risk score by taking equal weighting
    df_copy["risk_score"] = df_copy[[p + "_pctile" for p in predictors_list]].mean(axis=1)
    # pass through its own ECDF again
    df_copy["risk_score"] = df_copy["risk_score"].rank(pct=True)
    return df_copy


def plot_UK_risk_comparison(data_w_risk_score, locations = ["Leeds", "Manchester", "Liverpool", "Oxford","Cambridge"]):
    # for each location, compute weighted average risk score weighted by "total_kids_2011"
    locations_risk = {}
    for location in locations:
        # compute and add aggregate
        l = data_w_risk_score.loc[data_w_risk_score["msoa_name_x"].str.contains(location)]
        locations_risk[location] = round((l["risk_score"] * l["total_kids_2011"]).sum() / l["total_kids_2011"].sum(), 2)

    # set all dots to blue except "Leeds" is orange
    colors = ["blue"] * len(locations)
    colors[locations.index("Leeds")] = "orange"
    
    # create figure
    fig = go.Figure()

    # add line with arrow cap on y = 1 on [0,1]
    fig.add_annotation(
        x=1,  # End point of the arrow
        y=1,  # End point of the arrow
        ax=0,  # Start point of the arrow
        ay=1,  # Start point of the arrow
        xref="x",
        yref="y",
        axref="x",
        ayref="y",
        arrowhead=2,  # Arrowhead style
        arrowsize=1.5,  # Arrow size
        arrowwidth=2,  # Arrow width
        arrowcolor="grey",  # Arrow color
        opacity=0.5  # Arrow opacity
    )

    # plot as dots along a horizontal line
    fig.add_trace(go.Scatter(
        x=list(locations_risk.values()), 
        y=np.ones(len(locations_risk)), 
        mode='markers', 
        marker=dict(size=20, color=colors), 
        text=list(locations_risk.keys()))
    )
    
    # add annotation for each dot
    for location in locations_risk:
        fig.add_annotation(
            x=locations_risk[location],
            y=1,
            xref="x",
            yref="y",
            text=location,
            showarrow=True,
            xanchor="right",
            font=dict(size=16),
            textangle=70  # Rotate text
        )

    # update layout
    fig.update_layout(
        title="Aggregate Risk Score Comparison",
        xaxis_title="weighted average risk score across MSOAs in each LAD (weighed by nr. of children)",
        plot_bgcolor='white',
        paper_bgcolor='white',
        # hide y axis
        yaxis=dict(showticklabels=False, showline=False, showgrid=False),
        showlegend=False
    )
    return fig
