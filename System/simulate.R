suppressPackageStartupMessages({
    library("optparse")
    library("futile.logger")
    ## library("glue")
})
option_list <- list( 
    make_option(c("-i", "--ip"), action="store", default="192.168.0.47", help="IP adress of server")
    , make_option(c("-s", "--sleep"), action="store", default="1", help="seconds between calls")
    , make_option(c("-d", "--device"), action="store", default="Kamstrup", help="Device to simultate [default: Kampstrup]")
    , make_option(c("-c", "--count"), action="store", default="10", help="Number of cycles (-1 for infinite)")
)
opt <- parse_args(OptionParser(option_list=option_list))

IP <- opt$ip
Sleep <- opt$sleep
Device <- opt$device
Count <- opt$count

if(Count == -1)
    Count <- Inf

stopifnot(Device %in% c("Kamstrup", "Sensus620"))
## stopifnot(grepl("\\d+\\.\\d+\\.\\d+\\.\\d+",IP))

          
flog.info("IP: %s, Device: %s, Sleep: %s, Count: %s", IP, Device, Sleep, Count)

Iter <- 1

while(Iter < Count) {
    Cmd <- sprintf('curl -d \'{"content":"%s: %s"}\' -H "Content-Type: application/json" -X POST http://%s:3000/hus/public/tyv', Device, Iter, IP)
    flog.info(Cmd)
    system(Cmd, intern=TRUE)
    Sys.sleep(Sleep)
    Iter <- Iter +1 
}
