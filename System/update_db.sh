## Add new columns
DBUSER="iot"
DBPW="iot" ## password
DB="hus"

## Adding existing columns just fails
## Fields:  content software_version content power_w intensity threshold signal IP MAC senid 

PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE el ADD COLUMN software_version text;"

PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE el ADD COLUMN power_w text;"

PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE el ADD COLUMN threshold integer;"

PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE el ADD COLUMN signal integer ;"

PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE el ADD COLUMN IP text ;"

PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE el ADD COLUMN MAC text;"

PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE el ADD COLUMN time_ms bigint;"

PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE el ADD COLUMN delta_ms bigint;"

PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE el ADD COLUMN timer_periods int;"




