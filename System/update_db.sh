## Add new columns
DBUSER="iot"
DBPW="iot" ## password
DB="hus"

### El
## ref: https://stackoverflow.com/a/34518648
for Col in content software_version content power_w intensity threshold signal IP MAC senid ; do 
##    if psql -U iot -h 192.168.1.3 hus -tAc \
    if sudo -u postgres psql postgres -tAc \
       "SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='el' AND column_name='$Col');" | grep 'f'; then
	echo "No $Col in El"
    else
	echo "El has $Col"
    fi
done
