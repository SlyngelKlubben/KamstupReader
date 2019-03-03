#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)

library(plyr)
library(dplyr)
library(ggplot2)
library(lattice)
library(plotly)
library(futile.logger)
library(yaml)
library(openxlsx)

## Local funcs
source("lib.R")


if(file.exists("config.yml")) {
    Conf <- yaml.load_file("config.yml") ## add symlink locally
    flog.info("Read config. Using db on %s", Conf$db$host)
} else {
    stop("Needs config file to find database")
}
pg.new(Conf)

## get Date Range
DateRange <-  pg.get(q="select min(timestamp), max(timestamp) from tyv")

Day1 <- as.Date(DateRange$min)
Day2 <- as.Date(DateRange$max)

## process
## dat.in <- dev.last(device="", limit=NA)
## dat <- dev.trans(dat.in)


## El
## el <- kamstrup.power(subset(dat, Source=="Kamstrup" & Value > 1))



# Define UI for application that draws a histogram
ui <- fluidPage(
   
   # Application title
   titlePanel("Explore Data"),
   
   # Sidebar with a slider input for number of bins 
   sidebarLayout(
      sidebarPanel(width = 2,
         dateInput("date",
                   "Select Day",
                   min = Day1,
                   max = Day2,
                   value = Day2,
                   weekstart=1)
       , hr()
       , downloadButton("downloadWater", "Water Data")
       , downloadButton("downloadPower", "Power Data")
      ),
      
      # Show a plot of the generated distribution
      mainPanel(
          tabsetPanel(
              tabPanel("Water",
                       plotlyOutput("water_rate")
                     , plotlyOutput("water_total")
                     , dataTableOutput("water_table")  
                       )
             ,tabPanel("Power",
                       plotlyOutput("power")
                     , plotlyOutput("kWh")
                     , dataTableOutput("power_table")  
                       )
              )
      )
   )
)

# Define server logic required to draw a histogram
server <- function(input, output) {

    Dat <- reactive({
        req(input$date)
        dat.day(date=input$date, table=Conf$db$table) 
    })

    Water <- reactive({
        req(Dat())
        dat.water(Dat())
    })

    WaterRate <- reactive({
        req(Water())
        water.rate(Water())
    })

    Power <- reactive({
        kamstrup.power(subset(Dat(), Source=="Kamstrup" & Value > 1))
    })
    
   output$water_rate <- renderPlotly({
      req(input$date) 
      p1 <- ggplot(data=WaterRate(), aes(x=Time, y=L_per_min)) + geom_point()+ geom_step() + ggtitle(sprintf("Water Flow %s", input$date))
      ggplotly(p1)
      })
    output$water_total <- renderPlotly({
     req(input$date) 
     p1 <- ggplot(transform(Water(), Liter = Total_Liter - Total_Liter[1]), aes(x=Time, y=Liter)) + 
        geom_step() + ggtitle(sprintf("Water Consumed %s", input$date))
     ggplotly(p1)
    })
    output$water_table <- renderDataTable({
        req(input$date)
        Water()
    }, options = list(pageLength = 10)
    )
    output$downloadWater <- downloadHandler(
        filename = function() sprintf("water_%s.xlsx",input$date)
      , content = function(file) write.xlsx(x=Water(), file)
    )
    
    output$power <- renderPlotly({
        req(input$date)
        p1 <- ggplot(dat=Power(), aes(x = Time, y=PowerW)) +  geom_step() + ggtitle(sprintf("Power consumption %s", input$date))
      ggplotly(p1)
    })
    output$kWh <- renderPlotly({
        req(input$date)
        p1 <- ggplot(dat=Power(), aes(x = Time, y=kWh)) +  geom_line() + ggtitle(sprintf("Energy consumption %s", input$date))
      ggplotly(p1)
    })
    output$power_table <- renderDataTable({
        req(input$date)
        Power()
    }, options = list(pageLength=10)
    )   
    output$downloadPower <- downloadHandler(
        filename = function() sprintf("power_%s.xlsx",input$date)
      , content = function(file) write.xlsx(x=Power(), file)
    )
}

# Run the application 
app <- shinyApp(ui = ui, server = server)
runApp(app)
