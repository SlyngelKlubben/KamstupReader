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
library(shinydashboard)
library(reshape2)

## Local funcs
source("lib.R")


if(file.exists("config.yml")) {
    Conf <- yaml.load_file("config.yml") ## add symlink locally
    flog.info("Read config. Using db on %s", Conf$db$profile)
} else {
    stop("Needs config file to find database")
}
pg.new(Conf)

## get Date Range
DateRange <-  pg.get(q=sprintf("select min(timestamp), max(timestamp) from vand", Conf$db$vandtable))

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
                   uiOutput("datepicker")
         # dateInput("date",
         #           "Select Day",
         #           min = Day1,
         #           max = textOutput("today"),
         #           value = textOutput("today"),
         #           weekstart=1)
       , hr()
       , downloadButton("downloadWater", "Water Data")
       , downloadButton("downloadPower", "Power Data")
       , hr()
       , actionButton("update", "Update")
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
            , tabPanel("Enviroment"
                     , uiOutput("select_sens")
                     , plotlyOutput("envi")
##                     , dataTableOutput("envi_table")
                       )
             , tabPanel("Current",
                       dashboardBody (
                       fluidRow(
                         valueBoxOutput("PowerNow")
                        ,valueBoxOutput("TempNow")
                       )
                      #, fluidRow(
                      #    valueBoxOutput("Waterflux")
                      # )
                       ))
              )
      )
   )
)

# Define server logic required to draw a histogram
server <- function(input, output) {

    output$datepicker <- renderUI({
      dateInput("date",
                "Select Day",
                min = Day1,
                max = Sys.Date(),
                value = Sys.Date(),
                weekstart=1)
    })
  
    output$select_sens <- renderUI({
        Sensors <- unique(EnviDat()$senid)
        checkboxGroupInput("sensor_selected", "Select sensor", choices=Sensors, selected=Sensors, inline=TRUE)
    })

    VandDat <- reactive({
        req(input$date)
        dat.day(date=input$date, table=Conf$db$vandtable) 
    })
    
    ElDat <- reactive({
      req(input$date)
      dat.day(date=input$date, table=Conf$db$eltable) 
    })
    
    EnviDat <- reactive({
      req(input$date)
      dat.day(date=input$date, table=Conf$db$envitable) 
    })

    Water <- reactive({
        req(VandDat())
        dat.water(VandDat())
    })

    WaterRate <- reactive({
        req(Water())
        water.rate(Water())
    })
    
    EnviRate <- reactive({
      req(EnviDat())
      dat.envi(EnviDat())
    })

    Power <- reactive({
        kamstrup.power(subset(ElDat(), Source=="Kamstrup" & Value > 1))
    })

    PowerNow <- eventReactive(input$update, {
      dev.last(device="Kamstrup", limit=5) %>% kamstrup.power()
    })
    
    output$temp_hum_plot <- renderPlotly({
      req(input$date)
      d1 <- rbind(transform(EnviDat(), value=temp, Var = "Temperature"), 
                  transform(EnviDat(), value=humi, Var = "Humidity"))
      p1 <- ggplot(data = d1, aes(x=timestamp, y=value, color = factor(Var))) + geom_line() + facet_grid( Var ~ ., scales="free")
      ggplotly(p1)
    })
        
    output$envi <- renderPlotly({
      req(input$date)
      d1 <- EnviDat()
      if(length(input$sensor_selected) >0)
          d1 <- subset(d1, senid %in% input$sensor_selected)
      d2 <- reshape2::melt(d1, id.var= c("id","timestamp","senid", "Time", "TimeSec", "TimeMin"), measure.var=c("temp","humi","pir","press","light"))
      p2 <- ggplot(d2, aes(x = timestamp, y=value, color=senid)) + geom_line() + facet_grid(variable~., scales="free")
      ggplotly(p2, height = 800)
    })

    output$hum_temp_cor <- renderPlotly({
      req(input$date) 
      p1 <- ggplot(EnviDat(), aes(x = temp, y=humi, color = Time)) + geom_point() + ggtitle(sprintf("Humidity vs Temperature, %s", input$date))
      ggplotly(p1)
    })
    
    output$envi_table <- renderDataTable({
      req(input$date)
      EnviDat()
    }, options = list(pageLength = 10))
    
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

    output$PowerNow <- renderValueBox({
      req(input$update)
      dat1 <- tail(PowerNow(),1)
      with(dat1,flog.trace("Kamstrup: Used: %sW at %s",PowerW, Time))
      valueBox(
        sprintf("%.0fW",dat1$PowerW), sprintf("Power. %s",dat1$Time),
        color="orange"
      )
    })
    
    output$TempNow <- renderValueBox({
      req(input$update)
      dat1 <- tail(EnviDat(),1)
      valueBox(
        sprintf("%.2fc",dat1$temp), sprintf("%s %%",dat1$humi),
        color="orange"
      )
    })
    
}

# Run the application 
app <- shinyApp(ui = ui, server = server)

