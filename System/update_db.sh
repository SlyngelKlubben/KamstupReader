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

PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE el ADD COLUMN \"IP\" text ;"

PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE el ADD COLUMN \"MAC\" text;"

PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE el ADD COLUMN time_ms bigint;"

PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE el ADD COLUMN delta_ms bigint;"

PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE el ADD COLUMN timer_periods int;"


## INSERT INTO "hus"."public"."el"("IP", "MAC", "time_ms", "delta_ms", "threshold", "signal", "intensity", "senid", "timer_periods", "software_version", "content", "power_w") VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12) RETURNING row_to_json("el")
## Error: pq: column "IP" of relation "el" does not exist
## [negroni] Completed 400 Bad Request in 3.659251ms


