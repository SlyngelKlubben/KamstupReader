# parent image
FROM balenalib/armv7hf-debian:buster-build

# enable systemd
ENV INITSYSTEM on

RUN apt update && apt upgrade

RUN apt install r-base \
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
    r-cran-lubridate

ENV LC_ALL C.UTF-8
ENV LANG en_US.UTF-8

RUN mkdir /root/Dash2
COPY Dash2/ /root/Dash2

EXPOSE 3838

# Run app

CMD ["R","-e", "shiny::runApp('/root/Dash2', host='0.0.0.0', port = 3838)"]

