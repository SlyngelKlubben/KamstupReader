## library(RPostgreSQL)
## drv <- dbDriver("PostgreSQL")
## con <- dbConnect(drv, dbname="hus", host="192.168.0.47",user="jacob",password="jacob")

library(jsonlite)
library(httr)
library(plyr)
library(lubridate)
library(lattice)
d1 <- GET("http://192.168.0.47:3000/hus/public/tyv")
d2 <- content(d1)
d3 <- ldply(d2, as.data.frame)
Pat <- '^(\\S+)\\s+(\\d+)$'
d4 <- transform(d3, Source=sub(Pat,'\\1',as.character(content)), Value=as.numeric(sub(Pat,'\\2',as.character(content))), Time=ymd_hms(timestamp))
d5 <- transform(d4, TimeDiff=c(NA, diff(Time)))
d6 <- transform(d5, perMinute=60*60/TimeDiff)

with(subset(d5), xyplot(Value~Time, scales=list(rot=90), type=c('h','p')))
with(subset(d6, id>5300), xyplot(perMinute~Time, scales=list(rot=90), type=c('h','p'), main="Strømforbrug i W"))

write.csv(file=sprintf("data1_%s.csv", Sys.Date()), d6)
