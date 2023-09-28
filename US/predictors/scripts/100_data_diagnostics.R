library(tidyverse)

plot_na_prev <- function(df) {
  na_prev <- df |>
    select(-TRACT) |>
    map_df(~ sum(is.na(.x) | .x == "NaN" | .x == "Inf") / nrow(df))
  
  na_prev |>
    pivot_longer(everything(), names_to = "variable", values_to = "na_prev") |>
    ggplot(aes(x = reorder(variable, na_prev), y = na_prev)) |>
    geom_col() |>
    coord_flip() |>
    labs(x = "Variable", y = "Proportion of NA, NaN or Inf", title = "Proportion of Missingness by variable (CENSUS & ACS)") |>
    theme_bw() |>
    theme(plot.title = element_text(hjust = 0.5))
}