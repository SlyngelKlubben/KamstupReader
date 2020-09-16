## make sure we have nas mounted on /tmp/NAS/ and have a writeable folder Backup there

## crontab
# m h  dom mon dow   command
# 0 0 * * * /usr/bin/pg_dump -d hus  -Fc > "/tmp/NAS/daily.pgdump"
# 1 1 * * * /bin/bash /home/pi/KamstupReader/System/backup.sh


NAS="192.168.0.100"

sudo apt install nfs-common

sudo cat <<EOF >> /etc/rc.local
mkdir /tmp/NAS
mount  -t nfs ${NAS}:/volume1/iot /tmp/NAS
chown pi /tmp/NAS
chgrp -R postgres /tmp/NAS
chmod -R ug+rwX /tmp/NAS
EOF

