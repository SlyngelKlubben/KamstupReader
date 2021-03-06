## Parameters
DBUSER="iot"
DBPW="iot" ## password
DB="hus"

P1=$1 ## DROP will drop existing database

PGVER="11"

## Check we are running as root
if (( $EUID != 0 )); then
    echo "Please run $0 as root"
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
if [[ -e /etc/postgresql/${PGVER}/main/pg_hba.conf ]] ; then
    echo "Postgres installed"
else 
    sudo apt update
    sudo apt install postgresql-${PGVER}
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

echo "Log in with: "
echo "psql -U $DBUSER -W $DB"
echo "And type password: $DBPW"

## DROP database if DROP given as argument
if [ "$P1" == "DROP" ] ; then
    echo "DROP given as argument. Confirm to DROP DATABASE $DB (N/Y)"
    read ANS
    if [ "$ANS" == "Y" ] ; then
	sudo -u postgres psql -tAc "DROP TABLE el CASCADE;" $DB
	sudo -u postgres psql -tAc "DROP TABLE vand CASCADE;" $DB
	sudo -u postgres psql -tAc "DROP TABLE envi CASCADE;" $DB
	sudo -u postgres psql -tAc "DROP DATABASE $DB;"
	echo "DROPED database $DB"
    else
	echo "Bailing out"
    fi
fi

## If DB does not exist, create it
if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw "$DB"; then
    echo "Database '$DB' exists in postgres"
else
    sudo -u postgres createdb "$DB" -O $DBUSER
    sudo -u postgres psql -tAc "GRANT ALL ON DATABASE $DB TO $DBUSER;"
    echo "Created database: '$DB'"
fi

## Set password login if not already done
if grep ^local /etc/postgresql/${PGVER}/main/pg_hba.conf | grep all | grep md5 > /dev/null; then
    echo "Password already enabled"
else
    if [[ ! -e /etc/postgresql/${PGVER}/main/pg_hba.conf_bu ]]; then
	sudo cp -b /etc/postgresql/${PGVER}/main/pg_hba.conf /etc/postgresql/${PGVER}/main/pg_hba.conf_bu
    fi
    sudo sed -i  '/^local\s*all\s*all\s*peer/ s/peer/md5/' /etc/postgresql/${PGVER}/main/pg_hba.conf
    if sudo grep -e "^\s*host\s*all\s*all\s*0\.0\.0\.0/0\s*md5"  /etc/postgresql/${PGVER}/main/pg_hba.conf > /dev/null ; then
	echo "Remote login rule already enabled"
    else
	echo "host    all             all             0.0.0.0/0               md5" >> /etc/postgresql/${PGVER}/main/pg_hba.conf
    fi
    echo "Local and remote login with password enabled. Reloading server"
    sudo service postgresql restart
fi

## allow connections from external hosts
PGCONF="/etc/postgresql/${PGVER}/main/postgresql.conf"
if grep -e "^listen_addresses\s*=\s*'\*'" $PGCONF > /dev/null ; then
    echo "Remote login already enabled"
else
    if [[ ! -e ${PGCONF}_bu ]]; then
	sudo cp -b ${PGCONF} ${PGCONF}_bu
    fi
    sudo sed -i  '/^#listen_addresses/ s/#listen_addresses/listen_addresses/' ${PGCONF}
    sudo sed -i  "/^listen_addresses/ s/localhost/*/" ${PGCONF}
    echo "Remote login with password enabled. Reloading server"
    sudo service postgresql restart
fi


## Create tables, if not already found
function make_simple_table {
    TBL=$1
    if sudo -u postgres psql -tAc "SELECT 1 FROM pg_tables WHERE tablename = '${TBL}';" $DB | grep 1  > /dev/null ; then
	echo "Table '${TBL}' already exists in database $DB"
    else
	sudo -u postgres psql -tA -c "\\connect $DB" -c "CREATE TABLE public.${TBL}(
id serial,
timestamp timestamp with time zone default now(), -- Andrew without time zone?
content text,
senid text, -- sonsorid
CONSTRAINT ${TBL}_pkey PRIMARY KEY (id)
);
ALTER TABLE public.${TBL} OWNER to $DBUSER;
GRANT ALL on TABLE public.${TBL} to $DBUSER;" $DB
	echo "Created table ${TBL}" 
    fi
}
## el
make_simple_table el
## vand
make_simple_table vand
## environment
TBL="envi"
if sudo -u postgres  psql -tAc "SELECT 1 FROM pg_tables WHERE tablename = '${TBL}';" $DB | grep 1  > /dev/null ; then
    echo "Table '${TBL}' already exists in database $DB"
else
    sudo -u postgres psql -tA -c "\\connect $DB" -c "CREATE TABLE public.${TBL}(
id serial,
timestamp timestamp with time zone default now(), -- Andrew without time zone?
content text,
senid text, -- sensorid
temperature double precision,
humidity double precision,
pir integer,
pressure double precision, 
light double precision, 
CONSTRAINT ${TBL}_pkey PRIMARY KEY (id)
);
ALTER TABLE public.${TBL} OWNER to $DBUSER;
GRANT ALL on TABLE public.${TBL} to $DBUSER;" $DB
    echo "Created table ${TBL}"
fi

echo "Database setup complete"
