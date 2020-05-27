## Add relay control table and function
DBUSER="iot"
DBPW="iot" ## password
DB="hus"


PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "CREATE TABLE public.relay_control ( id SERIAL,
			   relay_mac TEXT,
			   task TEXT,
			   off_time_start TIME WITH TIME ZONE,
			   off_time_end TIME WITH TIME ZONE,
			   envi_mac TEXT,
			   off_light_level DOUBLE PRECISION
			   );"

PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc "CREATE OR REPLACE FUNCTION public.relay_state (
task text , 
now_time time with time zone ,
off_start_time time with time zone ,
off_end_time time with time zone ,
current_light double precision,
off_light_level double precision
)
RETURNS text AS
$$
BEGIN
  IF task = 'light_control' THEN
    IF off_start_time <  off_end_time THEN
      IF ( now_time > off_start_time and now_time < off_end_time ) 
        OR current_light > off_light_level
      THEN
        RETURN 'off';
      ELSE
        RETURN 'on';
      END IF ;
    ELSE
      IF ( now_time > off_start_time or now_time < off_end_time ) 
          OR current_light > off_light_level
      THEN
          RETURN 'off';
      ELSE
          RETURN 'on';
      END IF;
    END IF;
  END IF;
END;
$$
LANGUAGE PLPGSQL;"

# SELECT relay_state(
#  task, now()::time with time zone, off_time_start, off_time_end, envi.light, off_light_level
# ) AS state
# FROM
# relay_control 
# JOIN envi ON relay_control.envi_mac = envi."MAC"
# where relay_mac = '84:F3:EB:3B:7C:ET'
# ORDER BY relay_control.id desc, envi.id desc
# limit 1;

sleep 3

PGPASSWORD=$DBPW psql -U $DBUSER $DB -tAc 'CREATE OR REPLACE VIEW public.relay AS
SELECT public.relay_state(
 task::text, now()::time with time zone, off_time_start::time with time zone, off_time_end::time with time zone, envi.light::double precision, off_light_level::double precision) 
AS state, relay_mac, envi.light, envi.id as envi_id, relay_control.id as relay_id
FROM
relay_control 
JOIN envi ON relay_control.envi_mac = envi."MAC"
ORDER BY envi.id desc, relay_control.id desc;
'

