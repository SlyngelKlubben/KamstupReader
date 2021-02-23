source("ikea.R") ## sets my_hub
## Test
coap_call(endpoint="15001", hub_data=my_hub)
coap_list_devices(my_hub)
coap_device_info("65547", result="raw")
coap_device_info("65547")

coap_call(endpoint="15001", hub_data=my_hub)

plyr::llply(coap_list_devices(my_hub), function(x) coap_device_info(x))

plyr::ldply(coap_list_devices(my_hub), function(x) coap_device_info(x), .inform=TRUE)

## device list
device_table(my_hub)

## groups
coap_call(endpoint=15004, result="values")

## Details
coap_call(endpoint="15011/15012", result="values")
