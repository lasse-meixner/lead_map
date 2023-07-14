# Description of Datasets Used in U.K. Lead Map Project

This file contains a description of the datasets from which variables used in the U.K. Lead Map project have beeen drawn, as well as description of the variables used. 

For each dataset, there is provided:
- Summary of dataset (including contents; source; and sampling)
- Relevance to project
- Relevant variables (apart from geographical identifiers)
- Link(s) to data

The datasets are placed under one of four categories based on the subject they are (most) informative about: "Built Environment"; "Pollution / Contamination"; "Demographic / Socioeconomic"; and "Geographical Boundaries". 

## Built Environment Data

### [Council Tax Stock of Properties](https://www.gov.uk/government/statistics/council-tax-stock-of-properties-2021)

**Summary**

The Council Tax: Stock of Properties datasets provide counts of domestic properties in each lower layer super output area (LSOA) in England, disaggregated by the council tax band, build period, and type of property. The Council Tax Stock of Properties data is aggregated from Council Tax Valuation Lists, property-level records produced by the Valuation Office Agency (VOA) of HM Revenue Commission (HMRC) for the purposes of banding properties for council tax. All domestic properties in the U.K. are required to have a council tax band, so the Council Tax: Stock of Properties datasets are comprehensive of all U.K. domestic properties. Data is available for each year from 1993 to the present.

**Relevance**

The Council Tax: Stock of Properties data provides information on housing age. Given the age of a house is likely to be informative about the presence within it of lead exposure sources such as lead paint and lead water pipes, housing age may be a predictor of elevated blood lead. 

**Variables**

- bp_*x* (Count of houses with build period *x*, where build periods *x* are: pre 1900, 1900-1918, 1919-1929, 1930-1939, 1945-1954; 1955-1964; 1965-1972; 1973-1982; 1983-1992; 1993-1999; 2000-2008; 2009; 2010; 2011; 2012; 2013; 2014; 2015; 2016; 2017; 2018; 2019; 2020; 2021).

**Download**

Datasets for the years 1993-present containing the relevant build period variables can be downloaded as CSV files in a [zip file](https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/1022509/ctsop4-1-1993-2021__5_.zip). 

### [Energy Performance of Buildings](https://epc.opendatacommunities.org/login)

**Summary**

The Energy Performance of Buildings dataset provides property-level data on a wide range of property attributes relevant to determining a property's level of energy efficiency. This dataset is constructed from property-level Energy Performance Certificates (EPCs) for domestic properties held by the Department for Levelling Up, Housing & Communities. The Energy Performance of Buildings dataset contains a record of all EPCs that have been issued up to the present, sometimes multiple EPCs for a single property. Although since 2008, it has been a legal requirement for any property being constructed, sold, or let to have a valid EPC, properties which have not been constructed, sold, or let since 2008 need not have an EPC. Around 80% of domestic properties in England and Wales are estimated to have an EPC. EPCs are commissioned privately and expire after ten years.

**Relevance**

The Energy Performance of Buildings data provides information about housing characteristics including, but not limited to, housing age. Given such characteristics of a house may be informative about the presence within it of lead exposure sources such as lead paint and lead water pipes, these characteristics may be predictors of elevated blood lead. 

**Variables**

- CONSTRUCTION_AGE_BAND
- NUMBER_HABITABLE_ROOMS
- TENURE
- PROPERTY_TYPE
- BUILT_FORM
- WINDOWS_DESCRIPTION

**Download**

The entire Energy Performance of Buildings dataset can be downloaded, after free registration, as CSV files in a [zip file](https://epc.opendatacommunities.org/files/all-domestic-certificates.zip). 

### [Price Paid](https://www.gov.uk/government/statistical-data-sets/price-paid-data-downloads#october-2021-data-current-month)

**Summary**

The Price Paid dataset provides a record of all property sales registered with HM Land Registry between 1995 and the present, including the property address and value of each sale. Over 25 million sales are recorded in the data. However, properties which have not been sold since 1995 will not appear in the data. 

**Relevance**

The Price Paid data provides information about the value of specific properties, which may in turn be informative about the physical environment and socioeconomic background of the households living in these properties. Given aspects of physical environment and socioeconomic background may be predictors of elevated blood lead, property value may also be a predictor of blood lead. 

**Variables**

- price_paid
- property_type
- deed_date

**Download**

The entire Price Paid dataset can be downloaded as a [CSV file](http://prod.publicdata.landregistry.gov.uk.s3-website-eu-west-1.amazonaws.com/pp-complete.csv) or as a [text file](http://prod.publicdata.landregistry.gov.uk.s3-website-eu-west-1.amazonaws.com/pp-complete.txt).  

### [OS Open Roads](https://osdatahub.os.uk/downloads/open/OpenRoads?_ga=2.1946487.77554106.1640220307-1001437976.1640220307)

**Summary**

The OS Open Roads data provides a mapping of Great Britain's road network, including classification of roads (e.g., as motorways, A-roads, and B-roads). The data is published by the Ordnance Survey (OS), the U.K.'s national mapping agency (a state-owned enterprise). The data is updated twice annually. 

The Major Road Network data, published by the Department for Transport, is a subset of the OS Open Roads data, providing a mapping of only motorways and A-roads.  

**Relevance**

The OS Open Roads data provides information about the proximity of properties and neighborhoods to (major) roads. Given vehicle emissions may be a source of lead exposure, proximity to (major) roads may be a predictor of blood lead.

**Variables**

The OS Open Roads data can be used to compute, for addresses or LSOA centroids:

- Distance from closest major road
- Number of major roads within 50, 100, 200, 300, 400, 500, 1000 meters

**Download**

All of the OS Open Roads data can be downloaded as shapefiles in a [zip file](https://api.os.uk/downloads/v1/products/OpenRoads/downloads?area=GB&format=ESRI%C2%AE+Shapefile&redirect). (Alternative file formats to shapefiles are also available). 

Major Road Network shapefiles alone can also be downloaded as shapefiles in a [zip file](https://data.gov.uk/dataset/95f58bfa-13d6-4657-9d6f-020589498cfd/major-road-network).

## Pollution / Contamination Data

### [Pollution Inventory](https://data.gov.uk/dataset/cfd94301-a2f2-48a2-9915-e477ca6d8b7e/pollution-inventory) 

**Summary**

The Pollution Inventory collates information on mass releases of specified substances to air, controlled waters, sewers, and land, as well as off-site waste transfers from large industrial sites regulated by the Environment Agency. Sites in the data are identified with geographical coordinates. The data is based on annual self-reporting of emissions and transfers by site-operators to the Environment Agency. Pollution Inventory data is available for each year since 1998, when the Pollution Inventory was introduced, to the present. The Pollution Inventory was introduced to take over the function of the Chemical Release Inventory, for which data is available from 1991-98. 

**Relevance**

The Pollution Inventory provides information about the locations of industrial lead emissions. Given industrial lead emissions may be a source of lead exposure, proximity to sites making such emissions may be a predictor of blood lead.

**Variables**

The Pollution Inventory data can be used to compute, for addresses or LSOA centroids:

- Distance from closest site (by industrial sector/subsector of site)
- Number of sites within 50, 100, 200, 300, 400,500,1000 meters (by sector/subsector)
- Cumulative quantity released (kg) within 50, 100, 200, 300, 400, 500, 1000 meters (by emission medium or sector/subsector)

**Download**

Pollution Inventory data for each year since 2013 can be downloaded as [CSV files](https://data.gov.uk/dataset/cfd94301-a2f2-48a2-9915-e477ca6d8b7e/pollution-inventory).

### [Contaminated Land](https://data.gov.uk/search?q=contaminated+land)

See also <https://data.gov.uk/dataset/e3770885-fc05-4813-9e60-42b03ec411cf/contaminated-land-special-sites> for a list of the nationally available data.

**Summary**

Under Part IIA of the Environmental Protection Act 1990, Local Authorities are required to designate and manage as "Contaminated Land" any land where "substances are causing or could cause: significant harm to people, property or protected species; significant pollution of surface waters (for example lakes and rivers) or groundwater; or harm to people as a result of radioactivity". Many local authorities publish registers of Contaminated Land sites under their care. 

**Relevance**

Given some Contaminated Land sites may be sources of lead exposure, proximity to such sites may be a predictor of blood lead.

**Variables**

Contimanted Land data can be used to compute, for addresses or LSOA centroids:

- Distance from closest site
- Number of sites within 50, 100, 200, 300, 400,500,1000 meters 

**Download**

Contaminated Land registers can be downloaded, when published by local authorities, from [data.gov.uk](https://data.gov.uk/search?q=contaminated+land), or directly from local authority websites. 

### [Advanced Soil Geochemical Atlas](https://www.bgs.ac.uk/geology-projects/applied-geochemistry/g-base/advanced-soil-geochemical-atlas/)

**Summary**

The Advanced Soil Geochemical Atlas provides estimates for topsoil concentration (in mg/kg) of 53 different elements (including lead) in 1x1km grid squares covering all of England and Wales. These estimates are based on topsoil samples collected by the British Geological Survey's National Soil Inventory (NSI) sampling campaign, which collected samples 5km apart in a grid across England and Wales. NSI samples were initially collected in 1984, but around one third of samples were updated in 1995.

**Relevance**

The Advanced Soil Geochemical Atlas provides information on the lead content of soil in neighbourhoods across the U.K.. Given lead in soil may be ingested by children, the lead content of soil may be a predictor of elevated blood lead. The lead content of soil in a neighbourhood may also be informative about lead exposure from other sources in that neighbourhood.

**Variables**

- Pb mg/kg

**Download**

The data for all elements in the Advanced Soil Geochemical Atlas can be downloaded as a text files in a [zip file](https://www.bgs.ac.uk/download/advanced-soil-geochemical-atlas-nsi-grids/#). 

## Demographic / Socioeconomic Data

### [U.K. Census (1991, 2001, 2011)](https://www.nomisweb.co.uk/sources/census)

**Summary**

The U.K. Census, managed by the Office for National Statistics (ONS), provides data about various demographic and socioeconomic characteristics of the population. The data is based on census questionnaires returned by households during the census and is intended to be comprehensive of the entire U.K. population. The data made publicly available is aggregated at the level of the Output Area (OA), or, for certain variables which are more sensitive with regard to identifiability, at a less granular geographical level. The Census is conducted every ten years. Data has been made available most recently for the 2011 Census (although a Census was conducted in 2021). 

**Relevance**

The U.K. Census provides information on several demographic and socioeconomic characteristics of neighborhoods which may be predictors of elevated blood lead, given that these characteristics may firstly be informative about children's physical environments and secondly may themselves affect, or be informative about demographic and socioeconomic characteristics which affect, children's lead exposure risk in a given physical environment. 

**Variables**

Variables in the Census aggregate data generally express a count or percentage within the geographical unit at hand of households/persons selecting particular answer choices to particular questions or combinations of questions (for example, count/percentage of persons whose ethnic group is "White - Irish"). Some variables also express a sum across households in the geographical unit at hand of some numerical quantity provided by each household in response to a question (for example, number of children in single-parent households). 

Relevant variables are those concerning:

- Ethnic Group
- Age
- Children in single-parent households
- Children in young parent households
- Tenure
- Occupancy
- Country of birth
- Economic activity
- Migration
- Education
- Occupation
- Industry

(Note: some variables may not be available in all three Censuses, or may be provided in different forms in different Censuses). 

**Download**

The full data for any given Census is available in several hundred separate datasets (tables), covering the whole range of population characteristics and subject areas. 

One can use [Nomis](https://www.nomisweb.co.uk/sources/census), a registration-free data access service provided by the ONS, to download the variables of interest from each census at the desired geographical level. To download the data for a particular variable from a particular census, it is necessary to: 
1. Navigate to the relevant dataset (table) within a particular census.
2. Specify which geographical units the data should be outputted for.
3. Specify which columns from the dataset (table) are desired. 
4. Choose between values and percentages (if the choice is available).
5. Choose whether to consider rural data, urban data, or (as is the default) both (if the choice is available). 

### [English Indices of Multiple Deprivation](https://www.gov.uk/government/statistics/english-indices-of-deprivation-2019) 

**Summary**

The English Indices of Multiple Deprivation provide a set of relative measures of deprivation for LSOAs across England. The aggregated Index of Multiple Deprivation is based on seven different domains of deprivation: Income Deprivation; Employment Deprivation; Education, Skills and Training Deprivation; Health Deprivation and Disability; Crime; Barriers to Housing and Services; and Living Environment Deprivation. An LSOA's score in each of these domains is computed from a set of indicators available for all LSOAs. New indices are published by the Department for Levelling Up, Housing and Communities (formerly known as the Ministry for Housing, Communities and Local Government) every three to five years. 

**Relevance**

The Indices of Deprivation provide information on the socioeconomic characteristics of neighborhoods which may be predictors of elevated blood lead, given that these characteristics may firstly be informative about children's physical environments and secondly may themselves affect, or be informative socioeconomic characteristics which affect, children's lead exposure risk in a given physical environment. 

**Variables**

- Index of Multiple Deprivation (IMD) Score	
- Income Score (rate)

**Download**

The English Indices of Multiple Deprivation can be downloaded at LSOA level in a [CSV file](https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/833978/File_5_-_IoD2019_Scores.xlsx). 

## Geographical Boundaries 

### [Census Support: English Boundary](https://borders.ukdataservice.ac.uk/easy_download.html)

**Summary**

The Census Support: English Boundary datasets map the various geographical units relevant to the collection and aggregation of data from the U.K. Census, from the lowest level of aggregation, the OA, to less granular geographical units such as the LSOA. 

Although the base units for the 1991 Census (Enumeration Districts) were different to those for the 2001 and 2011 Censuses (OAs), it is possible to convert between Enumeration Districts and OAs using the [U.K. Data Service's GeoConvert tool](http://geoconvert.mimas.ac.uk/application/step1credentials.cfm). 

**Relevance**

A mapping of the U.K.'s census geography is necessary for linking datasets and for mapping data. 

**Download**

The Census Support: English Boundary datasets can be downloaded as shapefiles:

- [1991 Enumeration Districts](https://borders.ukdataservice.ac.uk/ukborders/easy_download/prebuilt/shape/England_ed_1991.zip)
- [2001 Output Areas](https://borders.ukdataservice.ac.uk/ukborders/easy_download/prebuilt/shape/England_ua_oa_2001.zip)
- [2001 Lower Layer Super Output Areas](https://borders.ukdataservice.ac.uk/ukborders/easy_download/prebuilt/shape/England_ua_low_soa_2001.zip)
- [2001 Middle Layer Super Output Areas](https://borders.ukdataservice.ac.uk/ukborders/easy_download/prebuilt/shape/England_ua_low_soa_2001.zip)
- [2011 Output Areas](https://borders.ukdataservice.ac.uk/ukborders/easy_download/prebuilt/shape/England_oa_2011.zip)
- [2011 Lower Layer Super Output Areas](https://borders.ukdataservice.ac.uk/ukborders/easy_download/prebuilt/shape/England_lsoa_2011.zip)
- [2011 Middle Layer Super Output Areas](https://borders.ukdataservice.ac.uk/ukborders/easy_download/prebuilt/shape/England_msoa_2011.zip)
 
 Note: 2001 and 2011 units should be the same. 
