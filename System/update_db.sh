## Add new columns
DBUSER="iot"
DBPW="iot" ## password
DB="hus"

## Adding existing columns just fails
## Fields:  content software_version content power_w intensity threshold signal IP MAC senid 

PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE el ADD COLUMN software_version text;"
PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE el ADD COLUMN power_w real;"
## PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE el ADD COLUMN threshold integer;"
PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE el ADD COLUMN t_low integer;"
PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE el ADD COLUMN t_high integer;"
PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE el ADD COLUMN signal integer ;"
PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE el ADD COLUMN intensity integer ;"
PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE el ADD COLUMN \"IP\" text ;"
PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE el ADD COLUMN \"MAC\" text;"
PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE el ADD COLUMN time_ms bigint;"
PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE el ADD COLUMN delta_ms bigint;"
PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE el ADD COLUMN timer_periods int;"


## INSERT INTO "hus"."public"."el"("IP", "MAC", "time_ms", "delta_ms", "threshold", "signal", "intensity", "senid", "timer_periods", "software_version", "content", "power_w") VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12) RETURNING row_to_json("el")
## Error: pq: column "IP" of relation "el" does not exist
## [negroni] Completed 400 Bad Request in 3.659251ms

## vand
PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE vand ADD COLUMN software_version text;"
PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE vand ADD COLUMN flow_l_per_min real;"
PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE vand ADD COLUMN threshold integer;"
PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE vand ADD COLUMN t_low integer;"
PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE vand ADD COLUMN t_high integer;"
PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE vand ADD COLUMN signal integer ;"
PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE vand ADD COLUMN intensity integer ;"
PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE vand ADD COLUMN cycle_count integer ;"
PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE vand ADD COLUMN \"IP\" text ;"
PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE vand ADD COLUMN \"MAC\" text;"
PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE vand ADD COLUMN time_ms bigint;"
PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE vand ADD COLUMN delta_ms bigint;"
PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE vand ADD COLUMN timer_periods int;"

## Envi
PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE envi ADD COLUMN software_version text;"
PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE envi ADD COLUMN signal integer ;"
PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE envi ADD COLUMN \"IP\" text ;"
PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE envi ADD COLUMN \"MAC\" text;"
PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE envi ADD COLUMN time_ms bigint;"
PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE envi ADD COLUMN delta_ms bigint;"
PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE envi ADD COLUMN timer_periods int;"
PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE envi ADD COLUMN temperature double precision;"
PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE envi ADD COLUMN humidity double precision;"
PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE envi ADD COLUMN pir integer;"
PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE envi ADD COLUMN pressure double precision;"
PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "ALTER TABLE envi ADD COLUMN light double precision;"
