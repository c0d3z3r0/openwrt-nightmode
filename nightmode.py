#!/usr/bin/env python2.7
# -*- coding: utf-8 -*-
__author__ = 'c0d3z3r0'

import sys
import datetime
import subprocess
import re

debugOn = False
onTimes = \
    [    # weekday      #HH:MM   #HH:MM
        (range(0,3 +1), ( 7,00), (22,00)),   # Mo - Do
        (range(4,4 +1), ( 7,00), (23,59)),   # Fr
        (range(5,6 +1), (10,00), (22,00))    # Sa - So
    ]


def debug(msg):
    if debugOn:
        print(msg)
        subprocess.check_output('logger "nightmode :: %s"' % msg, shell=True)


def timeInRange(timerange):
    if datetime.time(timerange[0][0], timerange[0][1])\
            <= datetime.datetime.now().time()\
            <= datetime.time(timerange[1][0], timerange[1][1]):
        debug("Time is in range.")
        return True
    else:
        debug("Time is not in range.")
        return False


def onTime():
    weekday = datetime.datetime.now().weekday()
    matchTime = [item for item in onTimes if weekday in item[0]][0]
    if timeInRange(matchTime[1:]):
        debug("Time is in onTimes.")
        return True
    else:
        debug("Time is not in onTimes.")
        return False


def shell(command):
    #return subprocess.getoutput(command)
    try:
        output = subprocess.check_output(command, shell=True)
    except Exception, e:
        output = str(e.output)

    debug("Shell: " + command)
    debug("Output: " + str(output))
    return output


def countStations():
    stations = int(shell("(for dev in `ifconfig | "
                         "grep -o 'wlan[0-9]\(-[0-9]\)*'`; "
                         "do iw dev $dev station dump; done) | "
                         "grep -c Station"))
    debug("Stations: " + str(stations))
    return stations


def getFirstArg():
    if len(sys.argv)>1:
        debug("Argument: " + sys.argv[1])
        return sys.argv[1]


def resetButton():
    shell('uci set wireless.nightmode.interrupt=0')
    shell('uci commit wireless.nightmode.interrupt')


def getButton():
    try:
        button = bool(int(shell('uci get wireless.nightmode.interrupt')))
    except ValueError:
        button = False
    debug("Button: " + str(button))
    return button


def getWifi():
    if re.findall('phy', shell('iw dev')):
        debug("WiFi is on")
        return True
    debug("WiFi is off")
    return False


def setWifi(state):
    debug("WiFi should be %s" % ("down", "on")[state])
    if getWifi() != bool(state):
        debug("Change WiFi state:")
        shell('wifi %s' % ("down", "on")[state])


if __name__ == '__main__':
    if onTime():
        debug("It's onTime!")
        resetButton()
        setWifi(1)
    else:
        debug("It's offTime!")
        if countStations() == 0:
            debug("No stations connected.")
            if getButton():
                debug("Got button trigger. Enable WiFi!")
                resetButton()
                setWifi(1)
            else:
                debug("Disable WiFi!")
                resetButton()
                setWifi(0)
        else:
            debug("There are stations connected. Keep WiFi on!")
