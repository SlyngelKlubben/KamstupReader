## Run this on the pi

## Update packages
sudo apt update
sudo apt upgrade

## Add locales
sudo sed -i '/^# en_DK.UTF-8 UTF-8/s/^# en_DK.UTF-8 UTF-8/en_DK.UTF-8 UTF-8/' /etc/locale.gen
sudo sed -i '/^# da_DK.UTF-8 UTF-8/s/^# da_DK.UTF-8 UTF-8/da_DK.UTF-8 UTF-8/' /etc/locale.gen
sudo locale-gen

## Install packages
sudo apt install postgresql postgresql-client
sudo apt install emacs vim
sudo apt install git

## Install docker
curl -fsSL get.docker.com -o get-docker.sh 
sudo bash get-docker.sh
## add to group
sudo usermod -aG docker $USER  
sudo gpasswd -a $USER docker
sudo newgrp docker 
sudo newgrp pi
## Test:
docker run hello-world

## Install R for dashboard (Debin buster or newer)
sudo apt install r-base \
     r-cran-later \
     r-cran-shiny \
     r-cran-plyr \
     r-cran-dplyr \
     r-cran-ggplot2 \
     r-cran-plotly \
     r-cran-futile.logger \
     r-cran-dbi \
     r-cran-rpostgresql \
     r-cran-magrittr \
     r-cran-lubridate \
     r-cran-yaml \
     r-cran-shinydashboard \
     r-cran-glue \
     r-cran-openxlsx \
     r-cran-lubridate \
     r-cran-reshape2 \
     postgresql-client

# ## Disable swap. Cf http://ideaheap.com/2013/07/stopping-sd-card-corruption-on-a-raspberry-pi/
# sudo dphys-swapfile swapoff
# sudo dphys-swapfile uninstall
# sudo update-rc.d dphys-swapfile remove

## Consider setting the "commit" value on ext4 higher (default 5 sec)
## cf https://www.raspberrypi.org/forums/viewtopic.php?t=237735#p1453206
## 600 sec is 10 min
## PARTUUID=6c586e13-02  /               ext4    defaults,noatime  0       1
## PARTUUID=6c586e13-02  /               ext4    defaults,noatime,commit=600  0       1

