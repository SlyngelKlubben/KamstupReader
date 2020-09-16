## make sure we have nas mounted on /tmp/NAS/ and have a writeable folder Backup there

NAS="192.168.0.100"

sudo apt install nfs-common

sudo cat <<EOF >> /etc/rc.local
sudo mkdir /tmp/NAS
sudo mount  -t nfs ${NAS}:/volume1/iot /tmp/NAS
sudo chown pi /tmp/NAS
sudo chgrp -R postgres /tmp/NAS
sudo chmod -R ug+rwX /tmp/NAS
EOF

