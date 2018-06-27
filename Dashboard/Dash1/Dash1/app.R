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

GetRestData <- function(uri="http://192.168.0.47:3000/hus/public/tyv") {
  d1 <- GET(uri)
  d2 <- content(d1)
  d3 <- ldply(d2, as.data.frame)
  Pat <- '^(\\S+)\\s+(\\d+)$'
  d4 <- transform(d3, Source=sub(Pat,'\\1',as.character(content)), Value=as.numeric(sub(Pat,'\\2',as.character(content))), Time=ymd_hms(timestamp))
  d5 <- transform(d4, TimeDiff=c(NA, diff(Time)))
  d6 <- transform(d5, perMinute=60*60/TimeDiff)
  plyr::arrange(d6, Time)  
}

require(RPostgres)
library(DBI)
# Connect to a specific postgres database i.e. Heroku
con <- dbConnect(RPostgres::Postgres(),dbname = 'hus', 
                 host = '192.168.0.47', 
                 port = 5432, 
                 user = 'jacob',
                 password = 'jacob')


GetPgData <- function(db=con){
  stm <- sprintf("select * from tyv;")
  d1 <- dbGetQuery(conn=db, statement=stm)  
  Pat <- '^(\\S+)\\s+(\\d+)$'
  d2 <- transform(d1, Source=sub(Pat,'\\1',as.character(content)), Value=as.numeric(sub(Pat,'\\2',as.character(content))), Time=ymd_hms(timestamp))
  d3 <-   plyr::arrange(d2, Time)  
  d5 <- transform(d3, TimeDiff=c(NA, diff(Time)))
  d6 <- transform(d5, perMinute=60*60/TimeDiff)
  d6
}

if(FALSE) { ## Use canned data
    GetData <- function(uri="") {
        d6 <- read.csv("data1_2018-05-23.csv")
        d6 <- plyr::arrange(transform(d6, Time=ymd_hms(Time)), Time)
        Now <- ymd_hms("2018-05-02 21:20:04")
        DateMin <- min(as.Date(d6$Time))
        DateMax <- max(as.Date(d6$Time))
        d6
    }
}

GetData <-GetPgData

flog.debug("Data aquired")

## with(subset(d5), xyplot(Value~Time, scales=list(rot=90), type=c('h','p')))
## with(subset(d6, id>5300), xyplot(perMinute~Time, scales=list(rot=90), type=c('h','p'), main="Strømforbrug i W"))

d0 <- GetData()
DateMin <- min(as.Date(d0$Time))
DateMax <- max(as.Date(d0$Time))


# Define UI for application that draws a histogram
ui <- dashboardPage(
  dashboardHeader(title="Kamstrup reader. Power consumption"),
  dashboardSidebar(
       sidebarMenu(
           menuItem( title = "Controls", sliderInput("slider", "Minutes of data to show:", 1, 100, 50))
         , menuItem(title = "Date to show", dateInput("CenterDate", label="Select date", min=DateMin, max=DateMax, weekstart = 1))
           )
  ),
  dashboardBody(
    # Boxes need to be put in a row (or column)
    fluidRow(
        valueBoxOutput("CurrentW"),
        valueBoxOutput("CurrentTime")
    ),
    fluidRow(
      box(plotOutput("PlotAllData", height = 250))
      ,box(plotOutput("PlotLastHour", height = 250))
      ,box(plotOutput("PlotDay", height = 250))
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
  
    Now <- Sys.time()
    myTimer <- reactiveTimer(10000)
    
    LiveData <- eventReactive(myTimer(), {
        GetData()
    })
    
    CurrentW <- reactive({tail(LiveData(),1)$perMinute})
    
    output$CurrentW <- renderValueBox({ valueBox(sprintf("%.2fW", CurrentW()), "Current Consumption", color="orange")})
    
    output$CurrentTime <- renderValueBox({
        invalidateLater(1L, session)
        valueBox(format(Sys.time()), "Current Time", color="light-blue")})    
    
    output$PlotAllData <- renderPlot({
        with(subset(LiveData()), xyplot(perMinute ~ Time, scales=list(rot=90), type=c('h','p'), main="Power Consuption. All (W)"))
    })
    
    output$PlotLastHour <- renderPlot({
      with(subset(LiveData(), Now - Time > 60*input$slider), xyplot(perMinute~Time, scales=list(rot=90), type=c('h','p'), main=sprintf("Power Consuption. Last %s minutes (W)",input$slider)))
    })
    
    output$PlotDay <- renderPlot({
      with(subset(LiveData(), as.Date(Time) == input$CenterDate), xyplot(perMinute~Time, scales=list(rot=90), type=c('h','p'), main=sprintf("Power Consuption (W). Date: %s",input$CenterDate)))
    })
    
   
}

# Run the application 
shinyApp(ui = ui, server = server)

