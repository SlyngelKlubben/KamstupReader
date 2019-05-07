SD="/media/tp"
ROOTFS="${SD}/rootfs"
BOOT="$SD/boot"
SSID="TelenorC04AFB"
PSK="CEA530B3C2"
IP="10.0.0.235"
ROUTER="10.0.0.1"

## run: sudo bash setup_rpi.sh

## Check SD card
test ! -d $SD && echo "$SD does not exist" && exit

## check rootfs
test ! -d $ROOTFS && echo "$ROOTFS does not exist" && exit

## Check we run as root
test $EUID != 0 && echo "Needs to run as root" && exit

## update /etc/wpa_supplicant/wpa_supplicant.conf
WPASUP="$ROOTFS/etc/wpa_supplicant/wpa_supplicant.conf"
if grep -Fq $SSID $WPASUP
then
    echo "SSID $SSID is already known in $WPASUP"
else
    echo "Updating $WPASUP with $SSID"
    cat <<EOF >> $WPASUP
network={
  ssid="$SSID"
  psk="$PSK"
}
EOF
fi

## Configure IP
DHCP="${ROOTFS}/etc/dhcpcd.conf"
if grep -Fq wlan0 $DHCP
then
    echo "wlan0 already configured in $DHCP"
else
    echo "Updating $DHCP"
    cat <<EOF >> $DHCP
interface wlan0
static ip_address=$IP/24
static routers=$ROUTER
static domain_name_servers=$ROUTER
EOF
fi

## Enable ssh
test ! -d $BOOT && echo "$BOOT does not exist" && exit
SSH="$BOOT/ssh"
if [[ -f $SSH ]]
then
    echo "$SSH already exists"
else
    echo "Adding $SSH"   
    touch $SSH
fi

echo "Now unmount $ROOTFS and $BOOT. Move the SD card to the raspberry and log in:"
echo "sudo umount $ROOTFS"
echo "sudo umount $BOOT"
echo "ssh pi@$IP"
echo "give with pw raspberry"
