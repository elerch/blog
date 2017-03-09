+++
date = "2017-03-09T14:16:06-08:00"
title = "Rasperry Pi Headless Bootstrap"
draft = false

+++

Recently I picked up a new [Rasberry Pi Zero W](https://www.raspberrypi.org/magpi/pi-zero-w/)
and was excited but also lamenting the fact that I'd have to dig out a keyboard
and mouse. Being lazy, and being willing to work **really hard** to remain
lazy, I was determined to find a way around this.

I grabbed a MicroSD card and put [Raspian Jessie Lite](https://www.raspberrypi.org/downloads/raspbian/)
on it. I then [extended the root partition](http://raspberrypi.stackexchange.com/questions/499/how-can-i-resize-my-root-partition)
which I found easier to do before first boot since a) it was a virgin distro
install and b) since I wasn't doing it from the running system there were no
reboots involved - I could simply eject the card and plug it back in to
refresh the block device listing.

From there, I found a pretty good run-through of adding the ability to
connect via bluetooth here: https://hacks.mozilla.org/2017/02/headless-raspberry-pi-configuration-over-bluetooth/
The article is pretty good and though the script details are a little odd
I went with most of it. One big difference is that I did not allow automatic
login as I want to allow bluetooth serial connections permanently (so I can
add public hotspot networks later if I'm travelling). That was an easy change -
just remove the "-a pi" off the end of the ExecStart=/usr/bin/rfcomm line,
and it removes the need for the "Security" section near the bottom, since,
sure, you can find/pair/connect, but all you'll get is a login prompt.
I followed the instructions in the article, so I won't repeat them here,
but this is the script I used (with a generic device name) without the
"-a pi" on the getty line.

```
#!/bin/bash -e

# Display name in BT discovery list
echo PRETTY_HOSTNAME=MY-DEVICE-NAME

# Edit /lib/systemd/system/bluetooth.service to enable BT services
sudo sed -i: 's|^Exec.*toothd$| \
ExecStart=/usr/lib/bluetooth/bluetoothd -C \
ExecStartPost=/usr/bin/sdptool add SP \
ExecStartPost=/bin/hciconfig hci0 piscan \
|g' /lib/systemd/system/bluetooth.service

# create /etc/systemd/system/rfcomm.serfvice to enable BT serial from systemctl
sudo cat <<EOF | sudo tee /etc/systemd/system/rfcomm.service > /dev/null
[Unit]
Description=RFCOMM service
After=bluetooth.service
Requires=bluetooth.service

[Service]
ExecStart=/usr/bin/rfcomm watch hci0 1 getty rfcomm0 115200 vt100

[Install]
WantedBy=multi-user.target
EOF

#enable the new rfcomm service
sudo systemctl enable rfcomm

#start the rfcomm service
sudo systemctl restart rfcomm
```

With the script in place to allow bluetooth I needed one more thing. The
terminal emulators for Android over bluetooth serial connections kind of suck,
so for that reason I wanted to be able to get in and get out of the bluetooth
side of things as quickly as I could, basically bootstrapping to wifi.

I therefore created an additional script ```new-wifi``` that looked like this:

```bash
#!/bin/bash
sudo iwlist wlan0 scan |grep -F SSID
read -p 'SSID:' ssid
read -s -p 'Password:' password
sudo sh -c "wpa_passphrase $ssid $password | sed '/#psk/d' \
  >> /etc/wpa_supplicant/wpa_supplicant.conf"
sudo wpa_cli reconfigure
```

This handles networks that are broadcasting SSIDs just fine and doesn't
expose passwords in ```wpa_supplicant.conf```. Make sure to chmod 700
on the script. For non-broadcast SSID networks, I'll likely need to
modify the script to add the SSID as documented here:
https://www.raspberrypi.org/documentation/configuration/wireless/wireless-cli.md

General Connection overview and Mac specifics
---------------------------------------------

Next up, we want to connect to this thing. On Linux and Mac I found the
easiest way was to use screen. I didn't try without specifying the baud rate
so I don't know if that will work, but the general steps are:

* Pair with the Pi
* Find the device
* (sometimes) rfcomm bind to the device
* screen <dev> 115200

The baud rate should match the script above, so if you change it, just make
sure it matches. On mac, the device just "shows up" after pairing, so you'll
look for it in /dev/cu.*MY-DEVICE-NAME*-SerialPort. You'll also see a
/dev/tty.*MY-DEVICE-NAME*-SerialPort, but you'll want to use the cu version.
There's a great description of the differences here:
http://stackoverflow.com/questions/8632586/macos-whats-the-difference-between-dev-tty-and-dev-cu

Linux
-----

On Linux, something like this might also show up automagically. I like
to use arch linux when I can since nothing is automatic and therefore I
learn much more about the internals, so after pairing and making sure
my [system could work with bluetooth](https://wiki.archlinux.org/index.php/bluetooth),
I was able to create a serial device using rfcomm. A great overview of this
process is in this gist: https://gist.github.com/0/c73e2557d875446b9603
Note that the device becomes /dev/rfcomm0, but a simple ```screen /dev/rfcomm0 115200```
is all you need to connect. For me, I got 'screen is terminating' when I tried
this. I then realized my user didn't have permissions to read/write to /dev/rfcomm0.
So, I used 'sudo screen...' until I added myself to the uucp group. The uucp
group has rw permissions on the file, and you can add yourself with:
usermod -a -G uucp *myusername*

Android
-------

On Android I needed an appy-app to connect to Bluetooth. As I mentioned earlier
they mostly suck as they're usually optimized for non-terminal super-raw
usage. The two that I found the best was BlueTerm2 (a fork of BlueTerm that
uses volume buttons to send control characters instead of the jog wheel that
hasn't existed in forever), and [SENA BTerm Bluetooth Terminal](https://play.google.com/store/apps/details?id=com.sena.bterm&hl=en).
I'm not linking to BlueTerm2 here because I don't want to send folks over there.
It's mostly superior to SENA with one glaring issue - it doesn't seem to be
able to send upper case characters. The source code is available so if someone
fixes it I'll use BlueTerm2 in a heartbeat, but for now I'll stick with SENA.

Windows
-------

For Windows, putty should be your friend as shown here:
http://www.hobbyist.co.nz/?q=bluetooth-module-device
I haven't tried this though as I don't have a use case for it and my Windows
machine doesn't have a bluetooth adapter.
