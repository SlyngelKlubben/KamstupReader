## ace: R-3.5.0
##
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

rm(list=ls())
if(exists(".pg"))
    rm(".pg")

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
library(DT)

## library(shinycssloaders) ## spinner
## library(shinyBS) ## tooltip

## flog.threshold(TRACE)

## Local funcs
source("lib.R")

## Shiny Modules
source("pg_explorer.R")

if(!file.exists("config.yml")) {
    stop("Needs config file to find database")
}
Conf <- yaml.load_file("config.yml") ## add symlink locally
flog.info("Read config. Using db on %s. tz=%s", Conf$db$profile, Conf$db$timezone)

if( !exists(".pg"))
    pg.new(Conf)

RV <- reactiveValues(relay_pins = pg.relay_pin(), relay_list = pg.relay_list())

NeedTables <- c("el", "vand", "envi", "relay_control", "relay", "relay_pin")



## get Date Range
DateRange <-  pg.get(q=sprintf("select min(timestamp), max(timestamp) from %s", Conf$db$envitable),)

Day1 <- as.Date(DateRange$min)
Day2 <- as.Date(DateRange$max)


# Define UI for application that draws a histogram
ui <- fluidPage(
   
   # Application title
   titlePanel("Explore Data"),
   
   # Sidebar with a slider input for number of bins 
   sidebarLayout(
      sidebarPanel(width = 2,
                   uiOutput("datepicker")
                   , selectInput("day_range", "Days to show", choices=c(1:10), selected = 1)
       , hr()
       , downloadButton("downloadWater", "Water Data")
       , downloadButton("downloadPower", "Power Data")
       , hr()
       , actionButton("update", "Update")
      ),
      
      # Show a plot of the generated distribution
      mainPanel(
          tabsetPanel(
            tabPanel("Enviroment"
                     ## , uiOutput("select_sens")
                     ##, plotlyOutput("envi")
                       ##                     , dataTableOutput("envi_table")
                       , plotlyOutput("envi_temp")
                       , plotlyOutput("envi_hum")
                       , plotlyOutput("envi_pressure")
                       , plotlyOutput("envi_light")
                       , plotlyOutput("envi_pir")
                       )
            , tabPanel("Water",
                       plotlyOutput("water_rate")
                     , plotlyOutput("water_total")
                     , dataTableOutput("water_table")  
                       )
             ,tabPanel("Power",
                       plotlyOutput("powerPlot") ## power
                     , plotlyOutput("kWh")
                     , dataTableOutput("power_table")  
                       )
            , tabPanel("Wifi Signal"
                     , plotlyOutput("wifi_graph")
                     , dataTableOutput("wifi_table")  
                       )
            , tabPanel("Database"
                       , pg_explorerInput("database")
                       )
          , tabPanel("Relays"
                   , DT::dataTableOutput("relay_table")
                   , h3("Select a relay to pin")
                   , uiOutput("relay_pinner")
                   , DT::dataTableOutput("relay_pins")
                       )
            
             ## , tabPanel("Current",
             ##           dashboardBody (
             ##           fluidRow(
             ##             valueBoxOutput("PowerNow")
             ##            ,valueBoxOutput("TempNow")
             ##           )
             ##          #, fluidRow(
             ##          #    valueBoxOutput("Waterflux")
             ##          # )
             ##           ))
              )
      )
   )
)

# Define server logic required to draw a histogram
server <- function(input, output) {

    SelectedRelay <- reactive({RV$relay_list[input$relay_table_rows_selected,]})
    
    output$datepicker <- renderUI({
      dateInput("date",
                "Select Day",
                min = Day1,
                max = Sys.Date(),
                value = Sys.Date(),
                weekstart=1)
    })
  
    output$select_sens <- renderUI({
        Sensors <- unique(EnviDat()$MAC)
        checkboxGroupInput("sensor_selected", "Select sensor", choices=Sensors, selected=Sensors, inline=TRUE)
    })

    VandDat <- reactive({
        req(input$date)
        req(as.numeric(input$day_range))
        dat.day(date=input$date, days = input$day_range, table=Conf$db$vandtable) 
    })
    
    ElDat <- reactive({
      req(input$date)
      dat.day(date=input$date, days =input$day_range, table=Conf$db$eltable) 
    })
    
    EnviDat <- reactive({
      req(input$date)
      dat.day(date=input$date, days =input$day_range, table=Conf$db$envitable) 
    })

    Wifi <- reactive({
        Pdat <- ElDat()
        Wdat <- VandDat()
        Edat <- EnviDat()
        Dat <- plyr::rbind.fill(Pdat, Wdat, Edat)
        plyr::arrange(Dat, plyr::desc(Time), plyr::desc(id)) 
    })

    SensorNames <- reactive({
        sensor_names()
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


    
    ## PowerNow <- eventReactive(input$update, {
    ##   dev.last(device="Kamstrup", limit=5) %>% kamstrup.power()
    ## })

    
    
    output$temp_hum_plot <- renderPlotly({
      req(input$date)
      d1 <- rbind(transform(EnviDat(), value=temp, Var = "Temperature"), 
                  transform(EnviDat(), value=humi, Var = "Humidity"))
      p1 <- ggplot(data = d1, aes(x=timestamp, y=value, color = factor(Var))) + geom_line() + facet_grid( Var ~ ., scales="free")
      ggplotly(p1)
    })

    output$envi_temp <- renderPlotly({
      req(input$date)
      req(d1 <- EnviDat())
      ## if(length(input$sensor_selected) >0)
      ##     d1 <- subset(d1, MAC %in% input$sensor_selected)
      p1 <- plot.envi_part(d1, Part = "temperature")
      ggplotly(p1)
    })

    output$envi_hum <- renderPlotly({
      req(input$date)
      req(d1 <- EnviDat())
      ## if(length(input$sensor_selected) >0)
      ##     d1 <- subset(d1, MAC %in% input$sensor_selected)
      p1 <- plot.envi_part(d1, Part = "humidity")
      ggplotly(p1)
    })

    output$envi_pressure <- renderPlotly({
      req(input$date)
      req(d1 <- EnviDat())
      ## if(length(input$sensor_selected) >0)
      ##     d1 <- subset(d1, MAC %in% input$sensor_selected)
      p1 <- plot.envi_part(d1, Part = "pressure")
      ggplotly(p1)
    })

    output$envi_light <- renderPlotly({
      req(input$date)
      req(d1 <- EnviDat())
      ## if(length(input$sensor_selected) >0)
      ##     d1 <- subset(d1, MAC %in% input$sensor_selected)
      p1 <- plot.envi_part(d1, Part = "light")
      ggplotly(p1)
    })

    output$envi_pir <- renderPlotly({
      req(input$date)
      req(d1 <- EnviDat())
      ## if(length(input$sensor_selected) >0)
      ##     d1 <- subset(d1, MAC %in% input$sensor_selected)
      d2 <-  transform(d1, PIR = ifelse(pir, as.numeric(as.factor(MAC)),as.numeric(as.factor(MAC))-.5))
      p1 <- plot.envi_part(d2, Part = "PIR")
      ggplotly(p1)
    })

    
    output$envi <- renderPlotly({
      req(input$date)
      req(d1 <- EnviDat())
      DateRange <- range(as.Date(d1$Time))
      DateRangeStr <- sprintf("%s - %s", DateRange[1], DateRange[2])        
      if(length(input$sensor_selected) >0)
          d1 <- subset(d1, MAC %in% input$sensor_selected)
      d2 <- reshape2::melt(d1, id.var= c("id","timestamp","MAC", "Time", "TimeSec", "TimeMin"), measure.var=c("temperature","humidity","pir","pressure","light"))
      p2 <- ggplot(d2, aes(x = timestamp, y=value, color=MAC)) + geom_line() + facet_grid(variable~., scales="free")
      ## p2 <- p2 + theme_bw()
      p2 <- p2 + theme(panel.background = element_blank())
      ## p2 <- p2 + theme(panel.background = element_rect(fill="transparent"))
      ggplotly(p2, height = 800)
      
      ## subplot(
      ##     plot_ly(subset(d1, senid == input$sensor_selected[1] , x="timestamp", y="")
      ##     )
    })

    
    output$hum_temp_cor <- renderPlotly({
        req(input$date)
      Dat <- EnviDat()
      DateRange <- range(as.Date(Dat$Time))
      DateRangeStr <- sprintf("%s - %s", DateRange[1], DateRange[2])        
      p1 <- ggplot(Dat, aes(x = temp, y=humi, color = Time)) + geom_point() + ggtitle(sprintf("Humidity vs Temperature, %s", DateRangeStr))
      ggplotly(p1)
    })
    
    output$envi_table <- renderDataTable({
      req(input$date)
      EnviDat()
    }, options = list(pageLength = 10))
    
    output$water_rate <- renderPlotly({
      req(input$date) 
      Dat <- WaterRate()
      DateRange <- range(as.Date(Dat$Time))
      DateRangeStr <- sprintf("%s - %s", DateRange[1], DateRange[2])
      p1 <- ggplot(data=Dat, aes(x=Time, y=L_per_min)) + geom_point()+ geom_step() + ggtitle(sprintf("Water Flow %s", DateRangeStr))
      ggplotly(p1)
      })
    
    output$water_total <- renderPlotly({
        req(input$date)
        Dat <- transform(Water(), Liter = Total_Liter - Total_Liter[1])
        DateRange <- range(as.Date(Dat$Time))
        DateRangeStr <- sprintf("%s - %s", DateRange[1], DateRange[2])
      p1 <- ggplot(Dat, aes(x=Time, y=Liter)) + 
        geom_step() + ggtitle(sprintf("Water Consumed %s", DateRangeStr)) ## input$date
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
        req(Dat <- Power())
        DateRange <- range(as.Date(Dat$Time))
        DateRangeStr <- sprintf("%s - %s", DateRange[1], DateRange[2])
        p1 <- ggplot(dat=Dat, aes(x = Time, y=PowerW)) +  geom_step() + ggtitle(sprintf("Power consumption %s",DateRangeStr))
      ggplotly(p1)
    })
    output$powerPlot <- renderPlotly({
        req(input$date)
        req(Dat <- Power())
        DateRange <- range(as.Date(Dat$Time))
        DateRangeStr <- sprintf("%s - %s", DateRange[1], DateRange[2])        
        p1 <- ggplot(dat=Power(), aes(x = Time, y=pmin(power_w,10000))) +  geom_line() + ggtitle(sprintf("Power consumption %s", DateRangeStr))
      ggplotly(p1)
    })


    output$kWh <- renderPlotly({
        req(input$date)
        p1 <- ggplot(dat=Power(), aes(x = Time, y=kWh)) +  geom_line() + ggtitle(sprintf("Energy consumption %s", input$date))
      ggplotly(p1)
    })
    output$power_table <- renderDataTable({
        req(input$date)
        req(Power())
    }, options = list(pageLength=10)
    )   
    output$downloadPower <- downloadHandler(
        filename = function() sprintf("power_%s.xlsx",input$date)
      , content = function(file) write.xlsx(x=Power(), file)
    )

    ## output$PowerNow <- renderValueBox({
    ##   req(input$update)
    ##   dat1 <- tail(PowerNow(),1)
    ##   with(dat1,flog.trace("Kamstrup: Used: %sW at %s",PowerW, Time))
    ##   valueBox(
    ##     sprintf("%.0fW",dat1$PowerW), sprintf("Power. %s",dat1$Time),
    ##     color="orange"
    ##   )
    ## })
    
    output$TempNow <- renderValueBox({
      req(input$update)
      dat1 <- tail(EnviDat(),1)
      valueBox(
        sprintf("%.2fc",dat1$temp), sprintf("%s %%",dat1$humi),
        color="orange"
      )
    })

    output$wifi_graph<- renderPlotly({
      req(input$date)
      req(Dat <- Wifi())
      plot.wifi(Dat)
    })
    output$wifi_table <- renderDataTable({
      req(input$date)
      req(Dat <- Wifi())
      Dat
    })
    
    ## For Database Tab
    callModule(pg_explorer, "database")

    ## Relay tab
    output$relay_table <- DT::renderDataTable({
        MissedTables <- setdiff(NeedTables,  pg.tables()$table_name)        
        validate(need(length(MissedTables) == 0 , sprintf("Missing Tables: %s", paste(MissedTables,collapse =", "))))
        ## pg.relay_list() 
        RV$relay_list
    }, selection = "single", options= list(dom="t", ordering = FALSE))

    ## Control table
    output$relay_pinner <- renderUI({
        tagList(
            h3(sprintf("Pin State of relay: %s", input$relay_table_rows_selected)),
            radioButtons("pin_state", "State", choices=c("On", "Off")),
            datetimeSlider("pin_expire", "Until", From = Sys.time(), To = Sys.time() + 86400, Width="100%"),
            actionButton("pin_me", "Pin Relay")            
            )
    })

    ## Pinned relays
    output$relay_pins <- DT::renderDataTable({
        ## Todo: eventreactive on pin_me
        RV$relay_pins
        }, selection = "none")

    ## Set pin
    observeEvent(input$pin_me, {
        flog.trace("Selected row = %s", input$relay_table_rows_selected)
        validate(need(input$relay_table_rows_selected, message="Select a relay to pin"))
        Relay <- SelectedRelay()
        pg.set_pin(mac = Relay$relay_mac, state = input$pin_state, expire = input$pin_expire, tz = Conf$db$timezone)
        RV$relay_pins <- pg.relay_pin()
        RV$relay_list <- pg.relay_list() 
    })
}


# Run the application 
app <- shinyApp(ui = ui, server = server)

