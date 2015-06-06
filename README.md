# openwrt-nightmode

Nightmode script for OpenWRT devices

## Installation
On your OpenWRT router:

~~~bash
wget -O /usr/sbin/nightmode https://raw.githubusercontent.com/c0d3z3r0/openwrt-nightmode/master/nightmode.lua
chmod +x /usr/sbin/nightmode
opkg update
# you need iw, kmod-gpio-button-hotplug and kmod-button-hotplug
opkg install iw kmod-gpio-button-hotplug kmod-button-hotplug libuci-lua

mv /etc/rc.button/wps /etc/rc.button/wps.orig
mv /etc/rc.button/rfkill /etc/rc.button/rfkill.orig

# THIS IS MAYBE HARDWARE DEPENDENT! Tested with TP-Link TPL-WDR4300
cat <<'EOF' >/etc/rc.button/wps
#!/bin/sh

[ "${ACTION}" = "released" ] || exit 0

uci set wireless.nightmode.interrupt=1
/usr/sbin/nightmode
EOF

cat <<'EOF' >/etc/rc.button/rfkill
#!/bin/sh

# Wifi on
[ "${ACTION}" = "released" ] && uci set wireless.nightmode.wifion=1

# Wifi off
[ "${ACTION}" = "pressed" ] && uci set wireless.nightmode.wifion=0

/usr/sbin/nightmode
EOF

chmod +x /etc/rc.button/wps /etc/rc.button/rfkill

(crontab -l; echo; echo '*/5  *  *  *  *  /usr/sbin/nig
htmode') | crontab -

# initialize vars
uci set wireless.nightmode.interrupt=0
uci set wireless.nightmode.wifion=1
~~~

## How it works
The script is called via cronjob every five minutes. It checks if the current time for the current weekday is in the range of your defined onTimes. If so it enables your wifi, if not it disables it. When you need wifi while you're out of your onTimes just push the WPS button the script enables wifi and you have some minutes to connect to wifi. It will stay on while at least one device is connected and will turn off after the last device disconnected and your are out of onTimes. You can use your RFkill switch to completely disable wifi. When there are connected stations it will turn off when they disconnect. In disabled state you can use the WPS button to enable wifi like in offTimes.

## How can I debug it?
Just set debugOn to true and the script will output some more or less helpful messages to dmesg.
`logread -f` is your friend :-)

## Warning
The script uses the WPS button for interrupting the nightmode. If you need the button you cannot use this feature. Everything else will work.
