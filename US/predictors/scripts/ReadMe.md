# Scripts

# Data Sources
## DropBox
Raw files not available through APIs are stored on DropBox and will automatically be pulled and loaded into memory when running the scripts.

These are the original download sources:

**Download Social Vulnerability Index data**
https://svi.cdc.gov/Documents/Data/2018_SVI_Data/CSV/SVI2018_US.csv

**Download Census Bureau relationship file for crosswalking between ZCTAs and census tracts**
https://www2.census.gov/geo/docs/maps-data/data/rel/zcta_tract_rel_10.txt



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