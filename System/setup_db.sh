## Parameters
DBUSER="iot"
DBPW="iot" ## password
DB="hus"

## Check we are running as root
if (( $EUID != 0 )); then
    echo "Please run as root"
    exit
fi

## If DB user does not exist in OS: create it
## ref https://superuser.com/questions/336275/find-out-if-user-name-exists
if id "$DBUSER" >/dev/null 2>&1; then
    echo "User $DBUSER exists in OS"
else
    sudo adduser "$DBUSER"
fi

## If postgres is not installed, install it
if [[ -e /etc/postgresql/9.6/main/pg_hba.conf ]] ; then
    echo "Postgres installed"
else 
    sudo apt update
    sudo apt install postgresql-9.6
fi

## If DBUSER does not exit, create it
## sudo su - postgres
if sudo -u postgres psql postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='$DBUSER'" | grep 1 ; then
    echo "User $DBUSER already exists in postgres"
else
    sudo -u postgres createuser "$DBUSER"
    sudo -u postgres psql -tAc "ALTER USER $DBUSER WITH ENCRYPTED PASSWORD '$DBPW';"
    sudo -u postgres psql -tAc "ALTER ROLE $DBUSER LOGIN PASSWORD '$DBPW';"
    echo "Created user: '$DBUSER' with password: '$DBPW'"
fi

## If DB does not exist, create it
if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw "$DB"; then
    echo "Database '$DB' exists in postgres"
else
    sudo -u postgres createdb "$DB" -o $DBUSER
    sudo -u postgres psql -tAc "GRANT ALL ON DATABASE $DB TO $DBUSER;"
    echo "Created database: '$DB'"
fi

## Set password login if not already done
if grep ^local /etc/postgresql/9.6/main/pg_hba.conf | grep all | grep md5 ; then
    echo "Login already enabled"
else
    sudo echo "local  all   all   md5" >> /etc/postgresql/9.6/main/pg_hba.conf
    echo "Local login with password enabled"
    ## TODO: Also needs to comment out line:
    #local   all             all                                     peer     
fi

## Create tables, if not already found
function make_simple_table {
    TBL=$1
    if sudo -u postgres psql -tAc "SELECT 1 FROM pg_tables WHERE tablename = '${TBL}';" | grep 1 ; then
	echo "Table '${TBL}' already exists in database $DB"
    else
	sudo -u postgres psql -tAc "CREATE TABLE ${TBL}(
id serial,
timestamp timestamp with time zone default now(), -- Andrew without time zone?
content text,
sensorid text, -- Andrew senid
CONSTRAINT ${TBL}_pkey PRIMARY KEY (id)
);
ALTER TABLE public.${TBL} OWNER to $DBUSER;
GRANT ALL on TABLE public.${TBL} to $DBUSER;"
	echo "Created table ${TBL}"
    fi
}
## el
make_simple_table el
## vand
make_simple_table vand
## environment
TBL="envi"
if sudo -u postgres  psql -tAc "SELECT 1 FROM pg_tables WHERE tablename = '${TBL}';" | grep 1 ; then
    echo "Table '${TBL}' already exists in database $DB"
else
    sudo -u postgres psql -tAc "CREATE TABLE ${TBL}(
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
ALTER TABLE public.${TBL} OWNER to $DBUSER;
GRANT ALL on TABLE public.${TBL} to $DBUSER;"
    echo "Created table ${TBL}"
fi

