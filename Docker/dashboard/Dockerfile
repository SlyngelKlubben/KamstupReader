# parent image
FROM resin/raspberrypi3-debian:latest

ENTRYPOINT []

# enable systemd
ENV INITSYSTEM on

# update sources
RUN echo "deb http://mirrordirector.raspbian.org/raspbian/ buster main" > /etc/apt/sources.list


# install R
RUN apt-get update && apt-get install -y \ 
  r-base \ 
  r-base-core \
  r-base-dev

# install dachboard deps
RUN apt-get install -y \ 
  r-cran-shiny \
  r-cran-shinybs \
  r-cran-shinydashboard \
  r-cran-ggplot2 \
  r-cran-cairo \
  r-cran-futile.logger \
  r-cran-lubridate \
  r-cran-yaml \
  r-cran-rpostgresql \
  r-cran-dbi \
  r-cran-bh

RUN apt-get install -y \ 
  libboost-atomic-dev



## Patch later
RUN mkdir /root/Later ; \
  curl -L https://github.com/r-lib/later/archive/master.zip --output /root/Later/master.zip ; \
  sed /root/Later/later-master/src/Makevars -e 's/PKG_LIBS = -pthread/PKG_LIBS = -pthread -lboost_atomic/' -i ; \
  cd /root/Later ; \
  ln -s later-master later

RUN R CMD INSTALL later

## Add the app
RUN mkdir /root/Dash2
COPY ../../Dashboard/Dash2 /root/Dash2

EXPOSE 3838

# Run app

CMD ["R","-e", "shiny::runApp('/root/Dash2', host='0.0.0.0', port = 3838)"]
