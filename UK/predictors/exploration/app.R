# Exploratory shiny app to interact with predictor data

library(shiny)
library(sf)
library(tmap)
library(htmlwidgets)

# try to run "100_merge_msoa_geography.R", which should create data_msoa_sf. If this fails, prompt to run 17_england_merging.R and return error
tryCatch({
  # check if data_msoa_sf is in memory, otherwise run 100_merge_msoa_geography.R
  if (exists("data_msoa_sf")) {
    print("data_msoa_sf already in memory")
  } else {
    source("../scripts/100_merge_msoa_geography.R")
  }
}, error = function(e) {
  stop(e)
  print("Did you run 17_england_merging.R?")
})


# create UI with selectInput for predictor variable to be plotted
ui <- fluidPage(
  # choices are all names in data_msoa_sf from the 4th column onwards excluding "geography_msoa"
  column(6,
  selectInput("predictor", "Predictor", choices = names(data_msoa_sf)[4:length(names(data_msoa_sf))], selected = "total_ppl_census_2011")
  ),
  column(6,
  textOutput("selection")
  ),
  column(12,
  plotOutput("plot", width = "100%") #TODO: add click events?
  )
)

server <- function(input, output, session) {
  output$selection <- renderText(paste0("Plotting ", input$predictor))
  output$plot <- renderPlot({
    # plot selected predictor variable
    tm_shape(data_msoa_sf) +
      tm_fill(input$predictor, palette = "Blues", title = input$predictor) +
      tm_borders("grey") +
      tm_layout(legend.outside = TRUE)
  }, width = 800, height = 1000)
}

shinyApp(ui, server)