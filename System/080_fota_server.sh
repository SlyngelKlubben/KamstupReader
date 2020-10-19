## Add OTA server
## Run this as root on raspberry

## Check we are running as root
if (( $EUID != 0 )); then
    echo "Please run $0 as root"
    exit
fi


## Add web-server
sudo apt update
sudo apt install micro-httpd

## Run on high port: 21451
cat > /etc/systemd/system/sockets.target.wants/micro-httpd.socket <<EOF
[Unit]
Description=micro-httpd
Documentation=man:micro-httpd(8)

[Socket]
ListenStream=0.0.0.0:21451
Accept=true

[Install]
WantedBy=sockets.target
EOF

## Add folder and set permissions
sudo mkdir  /var/www/html/fota
sudo chgrp pi /var/www/html/fota
sudo chmod g+w /var/www/html/fota

## Restart server
sudo systemctl daemon-reload
sudo systemctl restart micro-httpd.socket
