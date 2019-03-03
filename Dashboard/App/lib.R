## Functions: These should go into separate file later
pg.new <- function(Conf = list(db=list(host="192.168.0.47",port=5432, db="hus", user="jacob", pw="jacob"))) {
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
    stmt <- paste(q, ";") %>% sub(';+$',';', .)
    flog.debug(stmt)
    dbGetQuery(conn=con, statement=stmt)  
}

dat.day <- function(date, table="tyv", con=.pg){
    ## Get data from date
    stmt <- sprintf("SELECT * FROM %s where timestamp >= '%s' AND timestamp < '%s' ORDER BY id DESC", table, as.Date(date), as.Date(date)+1)
    res <- pg.get(q=stmt, con=con)
    if(nrow(res) == 0)
        return(NULL)
    dev.trans(res)
}

dev.last <- function(device='Kamstrup', table="tyv",limit=10, con=.pg) {
    ## Get latest data on device
    stmt <- sprintf("SELECT * FROM %s where content LIKE '%s%%' ORDER BY id DESC", table, device)
    if(!is.na(limit))
        stmt <- sprintf("%s LIMIT %s", stmt, limit)
    res <- pg.get(q=stmt, con=con)
    if(nrow(res) == 0)
        return(NULL)
    dev.trans(res)
}

dev.trans <- function(dat, tz.in="UTC", tz.out="CEST") {
    ## todo: get tz from conf
    library(lubridate)
    ## use in dev.last to 
    Pat <- '^(\\S+):.*\\s+(\\d+)$'
    res <- transform(dat,
                     Source=sub(Pat,'\\1',as.character(content)),
                     Value=as.numeric(sub(Pat,'\\2',as.character(content))),
                     Time=with_tz(ymd_hms(timestamp), tzone="Europe/Copenhagen"))
    transform(plyr::arrange(res, id), TimeDiffSec=c(NA, diff(Time)), TimeDiff=c(NA,diff(timestamp)))
}

kamstrup.power <- function(dat) {
    ## input from dev.last
    ## Kamstrup sends 1 per Wh
    if(is.null(dat) || nrow(dat)==0) return(NULL)
    transform(subset(dat, Source=="Kamstrup" & Value > 1), PowerW=60*60/TimeDiffSec, kWh = cumsum(Value > 1)/1000)
}


sensus620.flow <- function(dat) {
    ## Sensus620 reader configured to 1 per dL
    if(is.null(dat) || nrow(dat)==0) return(NULL)
    transform(dat, Water_L_per_Min = 6/TimeDiff, Water_L_per_Min2 = 6/TimeDiffSec, L_per_Min = Value/90/TimeDiffSec*60)
}

sensus620.sec.last.L <- function(con=.pg, liter=1) {
    ## Sensus620 reader configured to 1 per dL
    ## Seconds for last liter
    d1 <- dev.last("Sensus", limit=10*liter,con=con) %>% head(1)
    Now <- Sys.time()
    as.numeric(Sys.time()) - as.numeric(d1$Time)
}

dev.last.hour <- function(con=.pg, hour=1, table="tyv", device="Sensus620", tz="UTC") {
    Now.utc <- lubridate::with_tz(Sys.time(), tz)
    Res <- pg.get(q=sprintf("SELECT * FROM %s where timestamp >= (NOW() - INTERVAL '%s hours') AND  content LIKE '%s%%'", table, hour, device))
    if(nrow(Res) > 0)
        return(dev.trans(Res))
    NULL
}

dat.water <- function(dat) {
    vand <- subset(dat, Source!="Kamstrup") %>% 
        sensus620.flow() %>%
        mutate(Total_Liter = cumsum(Value)/90, TimeSec = as.numeric(Time)) %>%
        mutate(TimeMin = floor(TimeSec/60))
    
    vand
}

water.rate <- function(vand) {
    ## Vand
    vandRate <- vand %>% group_by(TimeMin) %>%  mutate( L_per_min = sum(Value)/90) %>% filter(row_number()==1)
    vandRate
}