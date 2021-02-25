## R-3.6.3
source("my_hub.R")

library(futile.logger)
library(jsonlite)
library(tidyr)
library(plyr)
library(dplyr)
library(purrr)


coap_call <- function(endpoint, hub_data = my_hub, port = 5684, method = "get", result = "values") {
    ## get/post
    CMD <- sprintf('coap-client -m %s -u "%s" -k "%s" "coaps://%s:%s/%s"', method, hub_data$user_name, hub_data$preshared_key, hub_data$gateway_host, port, endpoint)
    flog.debug("coap_call. CMD = '%s'", CMD)
    res <- system(CMD, intern=TRUE)
    if(result == "raw")
        return(res)
    if(result == "values" && length(res) == 4)
        return(fromJSON(res[4]))
    print(res)
    stop("failed")    
}

coap_list_devices <- function(hub_data = my_hub, port = 5684, result = "values") {
    # coap-client -m get -u "$TF_USERNAME" -k "$TF_PRESHARED_KEY" "coaps://$TF_GATEWAYIP:5684/15001"
    coap_call(endpoint= "15001", hub_data = hub_data, port = port, method = "get", result = result)    
}

coap_device_info <- function(dev_id, hub_data = my_hub, port = 5684, result = "values") {
    # coap-client -m get -u "$TF_USERNAME" -k "$TF_PRESHARED_KEY" "coaps://$TF_GATEWAYIP:5684/15001/$TF_DEVICEID"
    endp <- sprintf("15001/%s", dev_id)
    res <- coap_call(endpoint= endp, hub_data = hub_data, port = port, method = "get", result = result)
    if(result == "raw")
        return(res)
    r1 <- data.frame(id = res[["9003"]], Name = res[["9001"]], Creation = as.Date(res[["9002"]]/100000, origin='1970-01-01'))
    if("3" %in% names(res)) {
        r1 <- cbind(r1, data.frame(Vendor= res$`3`$`0`, Type = res$`3`$`1`))
    }
    if("3311" %in% names(res)) ## Light/bulp
        r1 <- cbind(r1, .parse_bulp(res$`3311`))
    r1
}

.parse_bulp <- function(l1){
    r2 <- data.frame(State=as.character(NA), Brightness = as.numeric(NA), Hue = as.numeric(NA), ColorTemp = as.numeric(NA), ColorHex = as.character(NA), Saturation = as.numeric(NA), colorX = as.numeric(NA), colorY=as.numeric(NA), TransitionTime = as.numeric(NA))
    if("5850" %in% names(l1))
        r2$State = l1$`5850` ## ifelse(l1$`5850`== 1, "Off", "On")
    if("5851" %in% names(l1))
        r2$Brightness = l1$`5851`
    if( "5706" %in% names(l1))
        r2$Hue = l1$`5706`
    if( "5711" %in% names(l1))
        r2$ColorTemp = l1$`5711`
    r2
}

device_table <- function(hub_data=my_hub) {
    plyr::ldply(coap_list_devices(my_hub), function(x) coap_device_info(x))
}
