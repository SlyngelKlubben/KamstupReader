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
RUN apt-get update && apt-get install -y \ 
  r-cran-shiny \
  r-cran-shinybs \
  r-cran-shinydashboard \
  r-cran-ggplot2 \
  r-cran-cairo \
  r-cran-futile.logger \
  r-cran-lubridate \
  r-cran-yaml \
  r-cran-rpostgresql \
  r-cran-dbi

# Run R
CMD ["R"]
