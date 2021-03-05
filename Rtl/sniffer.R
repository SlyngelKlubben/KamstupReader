## plot signal strength of top n transmitters
## needs rtl_wmbus from https://github.com/xaelsouth/rtl-wmbus
## needs sudo apt install rtl-sdr

## TODO check rtl_sdr is installed
## TODO check rtl_wmbus is installed
## TODO check SDR is connected
library(futile.logger)
library(ggplot2)
library(gridExtra) ## grid.arrange(p1,p2, nrow=2)

logfile <- sprintf("/tmp/mbus_%s.out", Sys.Date())
cmd <- sprintf("rtl_sdr -f 868.95M -s 1600000 - 2>/dev/null | rtl_wmbus >> %s &", logfile)
system(cmd, intern=FALSE) ## run in background

toNum <- function(x) as.numeric(as.character(x))

parse_wmbus <- function(File) {
    d1 <- try(read.delim(File, sep=";", head=FALSE, colClasses="character"),silent=TRUE)
    if(inherits(d1, "try-error")) return(NULL)
    names(d1) <- c("Mode","crc_ok","ok","timestamp","pck_rssi","current_rssi", "ll_id","data")
    d1 <- transform(d1, lenB = substr(data, 3,4), modeB = substr(data,5,6), vendorB = substr(data, 7,10), adressB = substr(data, 11,22), current_rssi=toNum(current_rssi), pck_rssi=toNum(pck_rssi))
    d1$data_end <- nchar(d1$data)
    d1 <- transform(d1, payload = substr(data,23,data_end))
    transform(d1, Length=base::strtoi(sprintf("0x%s",lenB)), Adress=base::strtoi(sprintf("0x%s",as.character(adressB))), datetime =lubridate::ymd_hms(timestamp), row = 1:nrow(d1))
}

filter_wmbus <- function(Df, Top=5) {
    top_ll_id <- names(head(sort(table(Df$ll_id), decreasing=TRUE),Top))
    subset(Df, ll_id %in% top_ll_id)
}

plot_wmbus <- function(Df) {
    ggplot(Df, aes(x = row, y = current_rssi, color = ll_id)) + geom_point() + geom_smooth() + ggtitle("Current RSSI") + theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))
}

main <- function(Logfile=logfile, Top=5, Refresh=1) {
    flog.info("Here is main")
    while(TRUE) {
        res1 <- parse_wmbus(Logfile)
        if(is.null(res1)) next()
        flog.info("Logfile has %s rows", nrow(res1))
        res2 <- filter_wmbus(res1, Top)
        flog.info("Rows to plot: %s", nrow(res2))
        if(nrow(res2) ==0) next()
        print(plot_wmbus(res2))
        Sys.sleep(Refresh)
    }
}

main(logfile,3,5)

## 209 rows: moved close to water 23133646 grows (23225367 still top)
## 287 rows: move to power
## no new rows added?
## EL: 23225373
## Vand: 23133646
