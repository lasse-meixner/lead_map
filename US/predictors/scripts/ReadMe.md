# Scripts

# Data Sources
## Google DRive
Raw files not available through APIs are stored on GoogleDrive and will automatically be pulled and loaded into memory when running the scripts.

These are the original download sources:

**Download Social Vulnerability Index data**
https://svi.cdc.gov/Documents/Data/2018_SVI_Data/CSV/SVI2018_US.csv

All other data sources will be pulled through APIs in-script. 

NB: Should any of these stop working (they shouldn't...), check if there is a copy on GDrive.

## API Keys
Register for the following to API keys:

- USPS API: https://www.huduser.gov/portal/dataset/uspszip-api.html
- US census API: http://api.census.gov/data/key_signup.html

The key for USPS will have to be pasted into the requests, whereas the census functions automatically look it up from your .Renviron file.

```

## Saving API Keys in .Renviron
Saving API Keys in your .Renviron file allows you to use them throughout your scripts without revealing them in your code (for these API keys, this wouldn't be a grave issue, but this is good practice for API keys.)

Here is a nice quick summary of how to do this for R: https://laurenilano.com/posts/api-keys/

TLDR: 
Open or create your .Renviron file in your home directory (on mac: ~/.Renviron) and add the following lines:
USPS_API_KEY="{*your USPS API key*}"
CENSUS_API_KEY="{*your CENSUS API key*}"
```

# Crosswalking
We crosswalk the tracts of all states for which BLL data is only available at the ZIP level.

The relevant crosswalking files are obtained from the [USPS API](https://www.huduser.gov/portal/dataset/uspszip-api.html).
We need different information based on whether we want to crosswalk counts, or proportions:

For counts, we need to know what proportion of each tract intersects with a particular zip (typically, this will be a lot of 1s from all tracts contained in that ZIP, plus some areas of cross-boundary tracts.) We can then get the zip count by simply taking a (weighted) sum of the tract counts. This information is contained in TRACT-TO-ZIP.

For proportions or ratios, we need different information: Here we need to know what proportion of each ZIP is contained in a particular tract. We can then get the overall proportion by taking a (weighted) mean of the tract proportions. This information is contained in ZIP-TO-TRACT.

# Confused?
Some of this code was patched together from work of different people. If anything confuses you, [ask ahead](mailto:lasse.vonderheydt@economics.ox.ac.uk)