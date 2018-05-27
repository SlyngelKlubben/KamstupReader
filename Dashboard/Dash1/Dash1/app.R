#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(shinydashboard)


## Get data
library(jsonlite)
library(httr)
library(plyr)
library(lubridate)
library(lattice)
library(futile.logger)

GetData <- function(uri="http://192.168.0.47:3000/hus/public/tyv") {
  d1 <- GET(uri)
  d2 <- content(d1)
  d3 <- ldply(d2, as.data.frame)
  Pat <- '^(\\S+)\\s+(\\d+)$'
  d4 <- transform(d3, Source=sub(Pat,'\\1',as.character(content)), Value=as.numeric(sub(Pat,'\\2',as.character(content))), Time=ymd_hms(timestamp))
  d5 <- transform(d4, TimeDiff=c(NA, diff(Time)))
  d6 <- transform(d5, perMinute=60*60/TimeDiff)
  plyr::arrange(d6, Time)  
}

if(FALSE) { ## Use canned data
  flog.debug("Start getting data...")
  d1 <- GET("http://192.168.0.47:3000/hus/public/tyv")
  d2 <- content(d1)
  d3 <- ldply(d2, as.data.frame)
  Pat <- '^(\\S+)\\s+(\\d+)$'
  d4 <- transform(d3, Source=sub(Pat,'\\1',as.character(content)), Value=as.numeric(sub(Pat,'\\2',as.character(content))), Time=ymd_hms(timestamp))
  d5 <- transform(d4, TimeDiff=c(NA, diff(Time)))
  d6 <- transform(d5, perMinute=60*60/TimeDiff)
  Now <- Sys.Date()
  DateMin <- min(as.Date(d6$Time))
  DateMax <- max(as.Date(d6$Time))
} else {
##  d6 <- read.csv("Dash1/data1_2018-05-23.csv")
  d6 <- read.csv("data1_2018-05-23.csv")
  d6 <- transform(d6, Time=ymd_hms(Time))
  Now <- ymd_hms("2018-05-02 21:20:04")
  DateMin <- min(as.Date(d6$Time))
  DateMax <- max(as.Date(d6$Time))
}

flog.debug("Data aquired")

## with(subset(d5), xyplot(Value~Time, scales=list(rot=90), type=c('h','p')))
## with(subset(d6, id>5300), xyplot(perMinute~Time, scales=list(rot=90), type=c('h','p'), main="Strømforbrug i W"))




# Define UI for application that draws a histogram
ui <- dashboardPage(
  dashboardHeader(title="Kamstrup reader. Power consumption"),
  dashboardSidebar(),
  dashboardBody(
    # Boxes need to be put in a row (or column)
    fluidRow(
        valueBoxOutput("CurrentW"),
        valueBoxOutput("CurrentTime")
    ),
    fluidRow(
      box(plotOutput("PlotAllData", height = 250)),
      box(plotOutput("PlotLastHour", height = 250))
      , box(
        title = "Controls",
        sliderInput("slider", "Minutes of data to show:", 1, 100, 50))
      , box(title = "Date to show", dateInput("CenterDate", label="Select date", min=DateMin, max=DateMax, weekstart = 1))
      , box(actionButton("go", "Update"))
      )
  )
)

# Define server logic required to draw a histogram
server <- function(input, output,session) {
  
  ## LiveData <- observeEvent  
  # observeEvent(input$go, {
  #     d6 <<- GetData()
  #     flog.debug("Clicked!")
  # })
  
    myTimer <- reactiveTimer(1000)
    
    LiveData <- eventReactive(myTimer(), {
        GetData()
    })
    
    CurrentW <- reactive({tail(LiveData(),1)$perMinute})
    
    output$CurrentW <- renderValueBox({ valueBox(sprintf("%.2fW", CurrentW()), "Current Consumption", color="orange")})
    
    output$CurrentTime <- renderValueBox({
        invalidateLater(1L, session)
        valueBox(format(Sys.time()), "Current Time", color="light-blue")})    
    
    output$PlotAllData <- renderPlot({
        with(subset(LiveData()), xyplot(perMinute~Time, scales=list(rot=90), type=c('h','p'), main="Power Consuption. All (W)"))
    })
    
    output$PlotLastHour <- renderPlot({
        with(subset(LiveData(), Now - Time < 60*input$slider), xyplot(perMinute~Time, scales=list(rot=90), type=c('h','p'), main=sprintf("Power Consuption. Last %s minutes (W)",input$slider)))
    })
  
   
}

# Run the application 
shinyApp(ui = ui, server = server)

