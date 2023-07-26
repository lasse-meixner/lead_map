# wrapper for the pollution scripts

# run all scripts in pollution directory in order by calling source
list.files(path = "11-13_england_pollution", pattern = "*.R", full.names = TRUE) %>%
  map(source)