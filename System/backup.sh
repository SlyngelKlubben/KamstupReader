DB="hus"
ROOT="NAS/Backup"

## pg_dump -d hus  -Fc | ssh tp@192.168.1.62 'cat > andrew_2020-08-17.pgdump'
## echo $(( `date +%s`/86400 % 7))
## date +%u ## day of week

# sudo su postgres
# pg_dump -d $DB  -Fc > "${ROOT}/daily.pgdump"

WEEK=$(( `date +%V` % 5 ))
MONTH=`date +%m`
YEAR=`date +%Y`

[ `date +%u` = "1" ] && echo "${ROOT}/daily.pgdump" "${ROOT}/weekly_${WEEK}.pgdump"
[ `date +%d` = "01" ] && [ `date +%u` = "1" ] && echo "${ROOT}/daily.pgdump" "${ROOT}/monthly_${MONTH}.pgdump"
[ `date +%m` = "01" ] && [ `date +%u` = "1" ] && [ `date +%d` = "01" ] && echo "${ROOT}/daily.pgdump" "${ROOT}/yearly_${YEAR}.pgdump"
