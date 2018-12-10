## Shiny app. Second try
## Concept:
### Front-page: current values for each reader
### Detail-pages as tabs
### Detail pages: last day, week, month, year (not as dynamic)
source("lib.R")
## test
pg.new()
t1 <- dev.last(limit=10)

## Config. Read from yaml
library(yaml)
C1 <- list(slyngel="jacob",sensors=list(kamstrup=list(key="Kamstrup",type="El"), Sensus=list(key="Sensus620", type="Vand")))
Conf <- yaml.load_file("config.jacob")


## Shiny app
library(shiny)
library(shinydashboard)
library(glue)

ui <- dashboardPage(
    title= "Dashing Dash"
  , dashboardHeader(title=sprintf("%s Dashboard",Conf$slyngel))
  , dashboardSidebar()
  , dashboardBody (
        ## fluidRow(
        ##     valueBoxOutput("CurrentTime")
        ## )
        fluidRow(
              valueBoxOutput("Power")
        )
        , fluidRow(
              valueBoxOutput("Water")
        ) 
        , fluidRow(
              valueBoxOutput("WaterFlux")
        ) 
        , fluidRow(
              valueBoxOutput("WaterCummHour")
        ) 
    )
)

server <- function(input, output,session) {
    ## Clock
    output$CurrentTime <- renderValueBox({
        invalidateLater(10L, session)
        flog.trace("Get time: %s", Sys.time())
        valueBox(format(Sys.time()), "Current Time", color="light-blue")})        

    output$Power <- renderValueBox({
        invalidateLater(10L, session)
        dat <- dev.last(device="Kamstrup", limit=5) %>% kamstrup.power()
        dat1 <- tail(dat,1)
        with(dat1,flog.trace("Kamstrup: Used: %sW at %s",PowerW, Time))
        valueBox(sprintf("%.0fW",dat1$PowerW), sprintf("Power. %s",dat1$Time), color="orange")})
    
    output$WaterFlux <- renderValueBox({
        invalidateLater(10L, session)
        dat <- dev.last(device="Sensus", limit=5) %>% sensus620.flow()
        dat1 <- tail(dat,1)
        with(dat1,flog.trace("Sensus620: Used: %s L per min at %s",Water_L_per_Min, Time))
        valueBox(sprintf("%.2fL/min",dat1$Water_L_per_Min), sprintf("Water-flow. %s",dat1$Time), color="blue")})    

    output$Water <- renderValueBox({
        invalidateLater(10L, session)
        Res <- sensus620.sec.last.L()/60 
        flog.trace("Sensus620: Minutes since last L at %s",Res, Time)
        valueBox(sprintf("%.2f min",Res), sprintf("Time since last Liter"), color="blue")})    

    output$WaterCummHour <- renderValueBox({
        invalidateLater(10L, session)
        dat1 <- dev.last.hour(device="Sensus620", hour=1)
        HourLiter <- 0.1*nrow(dat1)
        flog.trace("Sensus620: Total L last hour %s",HourLiter)
        valueBox(sprintf("%.2f L",HourLiter), sprintf("Total L last hour"), color="blue")})    

}

# Run the application 
shinyApp(ui = ui, server = server)
