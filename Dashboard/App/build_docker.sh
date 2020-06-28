#!/bin/bash

## Build
echo "To build the app do:
docker build --no-cache -t app .

If building several times the same day, leave out the --no-cache option for faster updates
"


## Test
echo "To test the app do:
docker run -p3838:3838 -t app
Make sure the database and code are in sync.
"

## Interactive
echo "To get a shell inside the container do:
docker run -it app /bin/bash
"


## Reboot
echo "To deploy the newly build app:
sudo reboot
"
