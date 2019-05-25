## Parameters
DBUSER="iot"
DBPW="iot" ## password
DB="hus"

## If DB user does not exist in OS: create it
## ref https://superuser.com/questions/336275/find-out-if-user-name-exists
if id "$DBUSER" >/dev/null 2>&1; then
    echo "User $DBUSER exists in OS"
else
    sudo adduser "$DBUSER"
fi

## If postgres is not installed, install it
sudo apt install postgresql-9.6

## If DBUSER does not exit, create it
sudo su - postgres
if psql postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='$DBUSER'" | grep 1 ; then
    echo "User $DBUSER already exists in postgres"
else
    createuser "$DBUSER"
    psql -tAc "ALTER USER $DBUSER WITH ENCRYPTED PASSWORD '$DBPW';"
    psql -tAc "ALTER ROLE $DBUSER LOGIN PASSWORD '$DBPW';"
    echo "Created user: '$DBUSER' with password: '$DBPW'"
fi

## If DB does not exist, create it
if psql -lqt | cut -d \| -f 1 | grep -qw "$DB"; then
    echo "Database '$DB' exists in postgres"
else
    createdb "$DB" -o $DBUSER
    psql -tAc "GRANT ALL ON DATABASE $DB TO $DBUSER;"
    echo "Created database: '$DB'"
fi

## Set password login if not already done
if grep ^local /etc/postgresql/9.6/main/pg_hba.conf | grep all | grep md5 ; then
    echo "Login already enabled"
else
    echo "local  all   all   md5" >> /etc/postgresql/9.6/main/pg_hba.conf
    echo "Local login with password enabled"
fi

## Create tables, if not already found
function make_simple_table {
    TBL=$1
    if psql -tAc "SELECT 1 FROM pg_tables WHERE tablename = '${TBL}';" | grep 1 ; then
	echo "Table '${TBL}' already exists in database $DB"
    else
	psql -tAc "CREATE TABLE ${TBL}(
id serial,
timestamp timestamp with time zone default now(), -- Andrew without time zone?
content text,
sensorid text, -- Andrew senid
CONSTRAINT ${TBL}_pkey PRIMARY KEY (id)
);
ALTER TALBE ${TBL} OWNER to $DBUSER;
GRANT ALL on TABLE ${TBL} to $DBUSER;"
	echo "Created table ${TBL}"
    fi
}
## el
make_simple_table el
## vand
make_simple_table vand
## environment
TBL="envi"
if psql -tAc "SELECT 1 FROM pg_tables WHERE tablename = '${TBL}';" | grep 1 ; then
    echo "Table '${TBL}' already exists in database $DB"
else
    psql -tAc "CREATE TABLE ${TBL}(
id serial,
timestamp timestamp with time zone default now(), -- Andrew without time zone?
content text,
sensorid text, -- Andrew senid
temp double precision,
humi double precision,
pir boolean,
pressure double precision, -- Not in Andrew
CONSTRAINT ${TBL}_pkey PRIMARY KEY (id)
);
ALTER TALBE ${TBL} OWNER to $DBUSER;
GRANT ALL on TABLE ${TBL} to $DBUSER;"
    echo "Created table ${TBL}"
fi

