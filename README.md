# openwrt-nightmode

Nightmode script for OpenWRT devices

## Installation
Clone this repo and then:
```bash
scp nightmode.py root@<your openwrt device>:/usr/sbin/
ssh root@<your openwrt device>

chmod +x /usr/sbin/nightmode.py
opkg update
# maybe you need kmod-gpio-button-hotplug and kmod-button-hotplug
opkg install python iw kmod-gpio-button-hotplug kmod-button-hotplug

cp /etc/rc.button/wps /etc/rc.button/wps.orig

cat <<EOF >/etc/rc.button/wps
#!/bin/sh

[ "${ACTION}" = "released" ] || exit 0

uci set wireless.nightmode.interrupt=1
/usr/sbin/nightmode.py
EOF

cat <<EOF >>/etc/crontabs/root
*/5  *  *  *  *  /usr/local/sbin/nightmode.py
EOF

/etc/init.d/cron restart
```

## How it works
The script is called via cronjob every five minutes. It checks if the current time for the current weekday is in the range of your defined onTimes. If so it enables your wifi, if not it disables it. When you need wifi while you're out of your onTimes just push the WPS button the script enables wifi and you have some minutes to connect to wifi. It will stay on while at least one device is connected and will turn off after the last device disconnected and your are out of onTimes.

## How can I debug it?
Just replace debugOn=False with debugOn=True and the script will output some more or less helpful messages to dmesg.
`logread -f` is your friend :-)

## Warning
The script uses the WPS button for interrupting the nightmode. If you need the button you cannot use this feature. Everything else will work.
