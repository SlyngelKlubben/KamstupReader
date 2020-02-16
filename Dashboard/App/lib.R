## Functions: These should go into separate file later
pg.new <- function(Conf = list(db=list(host="192.168.0.47",port=5432, db="hus", user="jacob", pw="jacob"))) {
    library(futile.logger)
    flog.trace("pg.new")
    library(DBI)
    library(RPostgreSQL)
    con <- dbConnect(RPostgreSQL::PostgreSQL(),
                     dbname = Conf$db$db, 
                     host = Conf$db$host, 
                     port = Conf$db$port, 
                     user = Conf$db$user,
                     password = Conf$db$pw)
    .pg <<- con
    con
}
pg.close <- function(con=.pg) {
    ##  dbDisconnect(con)
    ## https://stackoverflow.com/a/50795602
    lapply(dbListConnections(drv = dbDriver("PostgreSQL")), function(x) {dbDisconnect(conn = x)})
}
pg.get <- function(q, con=.pg) {
    library(futile.logger)
    library(magrittr)
    flog.trace("pg.get")
    stmt <- paste(q, ";") %>% sub(';+$',';', .)
    flog.debug(stmt)
    dbGetQuery(conn=con, statement=stmt)  
}

dat.day <- function(date, table=Conf$db$vandtable, con=.pg){
    ## Get data from date
    library(futile.logger)
    flog.trace("dat.day")
    stmt <- sprintf("SELECT * FROM %s where timestamp >= '%s' AND timestamp < '%s' ORDER BY id DESC", table, as.Date(date), as.Date(date)+1)
    res <- pg.get(q=stmt, con=con)
    if(nrow(res) == 0)
        return(NULL)
    dev.trans(res)
}

dev.last <- function(device='Kamstrup', table=Conf$db$eltable,limit=10, con=.pg) {
    ## Get latest data on device
    library(futile.logger)
    flog.trace("dev.last")
    stmt <- sprintf("SELECT * FROM %s where content LIKE '%s%%' ORDER BY id DESC", table, device)
    if(!is.na(limit))
        stmt <- sprintf("%s LIMIT %s", stmt, limit)
    res <- pg.get(q=stmt, con=con)
    if(nrow(res) == 0)
        return(NULL)
    dev.trans(res)
}

get.sensors.all <- function(con = .pg) {
    ## Get sensor names and locations at TimePoint
    stmt <- "select id, mac, name, location, start_date, ST_AsText(location) as location_txt from sensor_location  order by id desc"
    res <- pg.get(q=stmt, con=con)
    res
}
get.sensors.current <- function(TimePoint=Sys.time(), con = .pg) {
    ## Get sensor names and locations at TimePoint
    stmt <- sprintf("select distinct on (mac) id, mac, name, location, start_date, ST_AsText(location) as location_txt from sensor_location order by mac, start_date desc", TimePoint)
    stmt <- sprintf("select distinct on (mac) id, mac, name, location, start_date, ST_AsText(location) as location_txt from sensor_location where start_date <= '%s' order by mac, start_date desc", TimePoint)
    res <- pg.get(q=stmt, con=con)
    res
}

dev.trans <- function(dat, tz.in="Europe/Copenhagen", tz.out="Europe/Copenhagen") {
    ## todo: get tz from conf
    library(lubridate)
    library(futile.logger)
    flog.trace("dev.trans")
    ## use in dev.last to 
    Pat <- '^(\\S+):.*\\s+(\\d+)$'
    res <- transform(dat,
                     Source=sub(Pat,'\\1',as.character(content)),
                     Value=as.numeric(sub(Pat,'\\2',as.character(content))),
                     ## Time=with_tz(ymd_hms(timestamp), tzone=tz.in))
                     Time=ymd_hms(timestamp))
    ## transform(plyr::arrange(res, id), TimeDiffSec=c(NA, diff(Time)), TimeDiff=c(NA,diff(timestamp)))
    res <- transform(res, TimeSec = as.numeric(Time))
    res <- transform(res, TimeMin = floor(TimeSec/60))
    res <- transform(res, MAC = ifelse(is.na(MAC), as.character(senid), as.character(MAC)))
    # , 
    #                  temperature = ifelse(is.na(temperature), temp, temperature),
    #                  humidity = ifelse(is.na(humidity), humi, humidity),
    #                  pressure = ifelse(is.an(pressure), press, pressure))
    # plyr::arrange(res, id)
}

kamstrup.power <- function(dat) {
    ## input from dev.last
    ## Kamstrup sends 1 per Wh
    library(futile.logger)
    flog.trace("kamstrup.power")
    if(is.null(dat) || nrow(dat)==0) return(NULL)
    ## only one per second. Mine sends sometimes multiple per second, andwe do not use that much power!
    library(dplyr)
    dat <- dat %>% group_by(Time) %>% filter(row_number() == 1)
    dat <- transform(subset(dat, Source=="Kamstrup" & Value > 1), TimeDiffSec=c(NA, diff(Time)), TimeDiff=c(NA,diff(timestamp)))
    dat <- transform(dat, PowerW=60*60/TimeDiffSec, kWh = cumsum(Value > 1)/1000) ## not more than one per second
    if( "power_w" %in%names(dat))
        dat <- transform(dat, power_w = as.numeric(as.character(power_w)))
    dat
}

kamstrup.power.rate <- function(dat) {
  ## input from dev.last
  ## Kamstrup sends 1 per Wh
    library(futile.logger)
    flog.trace("kamstrup.power.rate")
  library(dplyr)
  if(is.null(dat) || nrow(dat)==0) return(NULL)
  dat %>% group_by(TimeMin) %>% mutate(Wh_per_min = n()) %>% filter(row_number()==1) %>% mutate(W = Wh_per_min*60)
}



sensus620.flow <- function(dat) {
    ## Sensus620 reader configured to 1 per dL
    library(futile.logger)
    flog.trace("sensus620.flow")
    if(is.null(dat) || nrow(dat)==0) return(NULL)
    dat <- transform(subset(dat, Source=="Sensus620" ), TimeDiffSec=c(NA, diff(Time)), TimeDiff=c(NA,diff(timestamp)))
    transform(dat, Water_L_per_Min = 6/TimeDiff, Water_L_per_Min2 = 6/TimeDiffSec, L_per_Min = Value/90/TimeDiffSec*60)
}

sensus620.sec.last.L <- function(con=.pg, liter=1) {
    ## Sensus620 reader configured to 1 per dL
    ## Seconds for last liter
    library(futile.logger)
    flog.trace("sensus620.sec.last.L")
    d1 <- dev.last("Sensus", limit=10*liter,con=con) %>% head(1)
    Now <- Sys.time()
    as.numeric(Sys.time()) - as.numeric(d1$Time)
}

dev.last.hour <- function(con=.pg, hour=1, table=Conf$db$vandtable, device="Sensus620", tz="Europe/Copenhagen") {
    library(futile.logger)
    flog.trace("dev.last.hour")
    Now.utc <- lubridate::with_tz(Sys.time(), tz)
    Res <- pg.get(q=sprintf("SELECT * FROM %s where timestamp >= (NOW() - INTERVAL '%s hours') AND  content LIKE '%s%%'", table, hour, device))
    if(nrow(Res) > 0)
        return(dev.trans(Res))
    NULL
}

dat.water <- function(dat) {
    library(futile.logger)
    flog.trace("dev.water")
    # v1 <- subset(dat, Source =="Sensus620")
    # v2 <- sensus620.flow(v1)
    # v3 <- transform(v2, Total_Liter = cumsum(Value)/90, TimeSec = as.numeric(Time))
    # v4 <- transform(v3, TimeMin = floor(TimeSec/60))
    # vand <- v4
    vand <- subset(dat, Source =="Sensus620") %>%
        sensus620.flow() %>%
        mutate(Total_Liter = cumsum(Value)/90, TimeSec = as.numeric(Time)) %>%
        mutate(TimeMin = floor(TimeSec/60))
    
    vand
}

    
water.rate <- function(vand) {
    ## Vand
    library(futile.logger)
    flog.trace("water.rate")
    vandRate <- vand %>% group_by(TimeMin) %>%  mutate( L_per_min = sum(Value)/90) %>% filter(row_number()==1) %>% ungroup()
    vandRate
}

plot.envi <- function(dat, ver = "facet") {
    d2 <- reshape2::melt(dat, id.var= c("id","timestamp","MAC", "Time", "TimeSec", "TimeMin"), measure.var=c("temperature","humidity","pir","pressure","light"))
    if(ver == "facet") {
        p2 <- ggplot(d2, aes(x = timestamp, y=value, color=MAC)) + geom_line() + facet_grid(variable~., scales="free")
        ## p2 <- p2 + theme_bw()
        ## p2 <- p2 + theme(panel.background = element_blank())
        ## p2 <- p2 + theme(panel.background = element_rect(fill="transparent"))
        return(p2)
    } else {
        pT <-  ggplot(subset(d2, variable == "temperature"), aes(x = timestamp, y=value, color=MAC)) + geom_line() 
        pH <- ggplot(subset(d2, variable == "humidity"), aes(x = timestamp, y=value, color=MAC)) + geom_line()
        
    }
    p2
}

plot.envi_part <- function(dat, Part = "temperature") {
    ggplot(dat, aes_string(x="timestamp", y=Part, color = "MAC")) + geom_line()
}

