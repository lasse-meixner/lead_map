## General Rules on Raw Data
Feel free to use this as temporary storage for DropBox downloads. If you run any of the predictor scripts that rely on external files they will automatically be downloaded in here (see scripts/00_drop_box_access.R) before being loaded into memory.
Please do not commit any large raw files into this directory!
Instead, save them to DropBox and point to the remote file in the scripts.
This is to avoid bloating the git repository with raw data we have no intention of version controlling.

## Exception
For quick-and-easy mapping purposes, we keep a **downsampled** shapefile of all England MSOAs. This is a 5% sample of the original shapefile, and is stored in the `shapefiles` folder for convenience, since this might be of use in interactive sessions. The original shapefile is too large to be stored in the repository, and is downloaded from DropBox when needed (see scripts/00_drop_box_access.R) for computation/modelling.