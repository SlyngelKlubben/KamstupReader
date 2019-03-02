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

## Local funcs
source("../lib.R")

DB <- TRUE

## Read data
if(DB) {
    flog.info("Using database")
    if(file.exists("config.local")) {
        library(yaml)
        Conf <- yaml.load_file("config.local") ## add symlink locally
        flog.info("Read config. Using db on %s", Conf$db$host)
    } else {
        stop("Needs config file to find database")
    }
    pg.new(Conf)
    dat.in <- dev.last(device="", limit=NA)
    pg.close()
    flog.info("Got %s rows of data", nrow(dat.in))
} else {
    flog.info("Using file")
    dat.in <- read.csv("../data.dump", skip=1 ) ## Replace get from database
    flog.info("Read %s rows of data", nrow(dat.in))
}

## process
dat <- dev.trans(dat.in)

Day1 <- min(as.Date(dat$Time))
Day2 <- max(as.Date(dat$Time))

## El
el <- kamstrup.power(subset(dat, Source=="Kamstrup" & Value > 1))

## Vand
vand <- subset(dat, Source!="Kamstrup") %>% 
  sensus620.flow() %>%
  mutate(Total_Liter = cumsum(Value)/90, TimeSec = as.numeric(Time)) %>%
  mutate(TimeMin = floor(TimeSec/60))

vandRate <- vand %>% group_by(TimeMin) %>%  mutate( L_per_min = sum(Value)/90) %>% filter(row_number()==1)



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
      ),
      
      # Show a plot of the generated distribution
      mainPanel(
        plotlyOutput("water_rate"),
        plotlyOutput("water_total")
        
      )
   )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
   
   output$water_rate <- renderPlotly({
      req(input$date) 
      p1 <- ggplot(subset(vandRate, as.Date(Time)==input$date), aes(x=Time, y=L_per_min)) + geom_point()+ geom_step() + ggtitle(sprintf("Water Flow %s", input$date))
      ggplotly(p1)
      })
   output$water_total <- renderPlotly({
     req(input$date) 
     p1 <- ggplot(transform(subset(vand, as.Date(Time)==input$date), Liter = Total_Liter - Total_Liter[1]), aes(x=Time, y=Liter)) + 
        geom_step() + ggtitle(sprintf("Water Consumed %s", input$date))
     ggplotly(p1)
   })
   
   
   }

# Run the application 
shinyApp(ui = ui, server = server)

