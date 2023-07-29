library(readxl)
library(tidyverse)
library(dplyr)


         
#Some Problems
# There is an awkward inconsistency of the name of the column: all other years are labeled "xxxx_Est_Conf_5+", only 2006 was labeled "2006_Conf_Est_5+", so I just changed the name manually to match all other years
# given the existence of suppressed data "1-5", I can't change the format to numeric, so all data are stored as characters as of now
# There are 2 variables "confirmed_tested>=5" and "estimated_tested>=5". I beliece the confirmed data involves multiple testing while the estimated data may contain results drawn from one single test. We need to figure out what to do with the 2 variables. 

ma_path <- 'BLL_MA_Raw.xlsx'

# if drop_get_from_root function is in env, continue, otherwise source "00_drop_box_access.R"
if (exists("drop_get_from_root")) {
    drop_get_from_root(ma_path)
} else {
    source("../00_drop_box_access.R")
    drop_get_from_root(ma_path)
}

ma <- read_excel(ma_path, sheet = "2005-2015 Individual Years", skip = 0) %>%
  mutate_at(vars(contains("Num_Scr")), as.character) %>%
  pivot_longer(cols = contains(c('Conf','Num_Scr')),
               names_sep = 4,
               names_to = c('year', 'measure')) %>%
  pivot_wider(names_from = 'measure',
              values_from = 'value') %>%
  rename( `BLL_geq_5_conf`=`_Conf_Only_5+` ,
          `BLL_geq_5_est`=`_Est_Conf_5+` ,
          `tested`= `_Num_Scr` ,
          town = `County Name`) %>%
  mutate(tract=paste("25", COUNTY, TRACT, sep = ""))%>%
  select(-c(COUNTY, TRACT))%>%
  mutate(state = 'MA') %>%
  relocate(state) %>% 
  select(-`BLL_geq_5_est`,-`_Conf_Est_5+`) %>% ## decision to consider only confirmed instead of eastimed.
  rename(`BLL_geq_5`=`BLL_geq_5_conf`) %>%
  mutate(n=nchar(tract)) %>% 
  filter(n==11) %>%  # get the right granularity of tracts (11 digits)
  select(-n)


# save to csv
write_csv(ma, "../processed_files/ma.csv")