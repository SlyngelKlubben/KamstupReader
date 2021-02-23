library(shiny)
library(DT)
source("ikea.R")
ui <- fluidPage(
    titlePanel("Ikea Hub"),
    mainPanel(
        DTOutput("devices")
    )
)

server <- function(input, output, state) {
    output$devices <- renderDT(
        device_table(hub_data=my_hub)
    )
}

app <- shinyApp(ui,server)
