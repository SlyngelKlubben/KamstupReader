## add postgis
DB="hus"



## Update packages
sudo apt update
sudo apt upgrade

## install postgis
sudo apt install postgis

## restart postgres
sudo service postgresql restart

## Enable postgis
sudo su - postgres
psql $DB -tAc "CREATE EXTENSION postgis_topology CASCADE ;"

## Create sensor_location table
psql $DB -tAc "CREATE TABLE sensor_location (
id SERIAL PRIMARY KEY,
mac TEXT NOT NULL,
name TEXT NOT NULL,
location GEOMETRY(POINTZ,25832),
start_date TIMESTAMPTZ  DEFAULT NOW() 
) ;"

