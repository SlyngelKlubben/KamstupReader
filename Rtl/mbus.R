## Functions for working with w-mbus data
## based on sniffer etc
## needs rtl_wmbus from https://github.com/xaelsouth/rtl-wmbus
## needs sudo apt install rtl-sdr
## AES in R: https://www.rdocumentation.org/packages/digest/versions/0.6.27/topics/AES
## decoding hex: as.numeric(as.hexmode("23")) ## 35
library(lubridate)
library(ggplot2)
library(futile.logger)
library(stringr) # str_sub()
library(digest)
options(stringsAsFactors = FALSE)

mbus_aquire <- function(logfile=sprintf("/tmp/mbus_%s.out", Sys.Date()), demon=TRUE) {
    ## Start logging data to logfile.
    ## non blocking if demon is TRUE
    flog.info("Logging mbus data to %s", logfile)
    if(demon) flog.info("Nonblocking")
    ambs <- ifelse(demon,"&","")
    cmd <- sprintf("rtl_sdr -f 868.95M -s 1600000 - 2>/dev/null | rtl_wmbus >> %s %", logfile, abms)
    system(cmd, intern=FALSE) 
    cmd
}

toNum <- function(x) as.numeric(as.character(x))

mbus_parse <- function(logfile){
    d1 <- try(read.delim(logfile, sep=";", head=FALSE, colClasses="character"),silent=TRUE)
    if(inherits(d1, "try-error")) return(NULL)
    names(d1) <- c("Mode","crc_ok","ok","timestamp","pck_rssi","current_rssi", "ll_id","data")
    d1 <- transform(d1, lenB = substr(data, 3,4), modeB = substr(data,5,6), vendorB = substr(data, 7,10), addressB = substr(data, 11,22), current_rssi=toNum(current_rssi), pck_rssi=toNum(pck_rssi))
    d1$data_end <- nchar(d1$data)
    d1 <- transform(d1, payload = substr(data,23,data_end))
    transform(d1, Length=base::strtoi(sprintf("0x%s",lenB)),  row = 1:nrow(d1), datetime =lubridate::ymd_hms(timestamp), vendor = mbus_vendor_decode(vendorB), serial_number= hexstr_reverse(addressB))
}

mbus_data_parse <- function(Dat) {
    d1 <- data.frame(lenB = substr(Dat, 3,4), modeB = substr(Dat,5,6), vendorB = substr(Dat, 7,10), addressB = substr(Dat, 11,22))
    d1$data_end <- nchar(Dat)
    d1 <- transform(d1, payload = substr(Dat,23,data_end))
    transform(d1, Length=base::strtoi(sprintf("0x%s",lenB)), vendor = mbus_vendor_decode(vendorB), serial_number= hexstr_reverse(addressB))
}

mbus_filter_count <- function(Df, min_count=5) {
    ## Filer away ids seen less than min_count times
    keep_df <- subset(data.frame(table(Df$ll_id)), Freq >= min_count)
    keep_set <- as.character(keep_df$Var1)
    subset(Df, ll_id %in% keep_set, drop=TRUE)
}

mbus_plot_signal <- function(Df) {
    ggplot(Df, aes(x = row, y = current_rssi, color = ll_id)) + geom_point() + geom_smooth() + ggtitle("Current RSSI") + theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))
}

mbus_vendor_decode <- function(Hex,inverted=TRUE) {
    ## See Annex D of prEN 13757-4. Mode T1 example
    if(length(Hex) > 1)
        return(as.vector(sapply(Hex, mbus_vendor_decode, inverted)))
    if(inverted)
        Hex <- sprintf("%s%s", substr(Hex,3,4), substr(Hex,1,2))
    flog.trace("Hex: %s", Hex)
    Dec <- as.numeric(as.hexmode(Hex))
    pL1 <- floor(Dec/32^2)
    pL2 <- floor((Dec - 32^2*pL1)/32)
    pL3 <- Dec - 32^2*pL1 - 32*pL2
    flog.trace("%s %s %s", pL1, pL2, pL3)
    paste(LETTERS[c(pL1,pL2,pL3)],collapse="")
}

hexstr_reverse <- function(x) {
    ## reverse byte-order, as mbus are send LSB first
    if(length(x) > 1)
        return(sapply(x, hexstr_reverse))
    L <- nchar(x)
    stopifnot(L %% 2 == 0) ## assert even length
    Bytes <- stringr::str_sub(x,seq(1,L,2), seq(2,L,2))
    paste(rev(Bytes), collapse="") ## return reversed
}

hexstr_to_raw <- function(x) {
    ## convert a string of hex to raw bytes
    stopifnot(length(x)==1)
    ## split in bytes
    L <- nchar(x)
    stopifnot(L %% 2 == 0) ## assert even length
    Bytes <- stringr::str_sub(x,seq(1,L,2), seq(2,L,2))
    ## convert to numbers
    Dec <- as.numeric(as.hexmode(Bytes))
    ## covert to raw
    as.raw(Dec)
}
