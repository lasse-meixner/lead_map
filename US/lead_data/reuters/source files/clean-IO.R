library(tidyverse)
library(readxl)

setwd(dir = "/Users/peter/Documents/Oxford/Frank RA/Lead Project/Raw Files")
io_path <- 'BLL_IO_Raw.xlsx'
# Read in all sheets and bind into a single tibble
# (based on <https://readxl.tidyverse.org/articles/readxl-workflows.html>)
io <- io_path %>%
  excel_sheets() %>% # Read in the names of all sheets in the .xlsx file
  map_df(~ read_excel(path = io_path, sheet ='Iowa Data')) %>%
  select(- `<5`) %>% 
  rename(year = `Year Tested`,
         zip = `Zip Code`,
         tested = `Total Children Tested`,
         BLL_geq_5 = `>5`,
         BLL_geq_10 = `>10`) %>%
  mutate(tested=replace(tested, tested == "*", "<5"))%>%
  mutate(BLL_geq_5=replace(BLL_geq_5, BLL_geq_5 == "*", "<5"))%>%
  mutate(BLL_geq_10=replace(BLL_geq_10, BLL_geq_10 == "*", "<5"))%>%
  mutate(state = 'IO') %>%
  relocate(state) %>%
  mutate(year = factor(year))