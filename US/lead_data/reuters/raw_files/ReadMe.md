# Raw Files
Raw files lie in the DropBox directory: reuters/Raw Files

The source files automatically grab them from there if run, and download them to this directory before loading into memory. Please do not commit them.

## Authentication
When you run any of the scripts from scratch, it will automatically run code that will prompt authentication with dropbox. This will open a browser window and ask you to log in to dropbox. Once you do, it will save authentication credentials in the background of the directory, that are temporarily valid.
If you find that you are getting errors such as:

```
Error in drop_download(paste0(reuters_drop_box_base_url, path), local_path = paste0("../raw_files/", :
Unauthorized (HTTP 401).
```

Then you will need to reauthenticate. To do this, simply rerun 00_drop_box_access.R. This will prompt you to log in again, and will save new credentials.
