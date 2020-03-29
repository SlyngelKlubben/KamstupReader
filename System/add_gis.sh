## add postgis
DBUSER="iot"
DBPW="iot" ## password
DB="hus"
TBL="sensor_location"

# ## Update packages
sudo apt update
sudo apt upgrade

# ## install postgis
sudo apt install postgis

# ## restart postgres
sudo service postgresql restart

## Enable postgis
#### sudo su - postgres
sudo -u postgres psql $DB -tAc "CREATE EXTENSION postgis_topology CASCADE ;"

## Create sensor_location table
sudo -u postgres psql $DB -tAc "CREATE TABLE public.${TBL} (
id SERIAL PRIMARY KEY,
mac TEXT NOT NULL,
name TEXT NOT NULL,
location GEOMETRY(POINTZ,25832), -- not null?
start_date TIMESTAMPTZ  DEFAULT NOW() 
) ;
ALTER TABLE public.sensor_location OWNER to $DBUSER;
GRANT ALL on TABLE public.${TBL} to $DBUSER;" 

