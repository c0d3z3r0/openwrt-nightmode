#!/usr/bin/env lua
-- author = Michael Niewoehner <mniewoeh@stud.hs-offenburg.de>

-- --------------------------------------------------
-- Begin of user settings
-- --------------------------------------------------

debugOn = false

onTimes = {
--  Weekday(s)  #HH:MM    #HH:MM
  { {0,1,2,3},  {07,00},  {22,00} },    -- Mo-Thu
  { {4},        {07,00},  {23,59} },    -- Fr
  { {5,6},      {10,00},  {22,00} }     -- Sa-Su
}

-- --------------------------------------------------
-- End of user settings
-- --------------------------------------------------


function debug(msg)
  if debugOn == true then
    print(msg)
    os.execute("logger \"nightmode :: " .. msg .. "\"")
  end
end


function timeInRange(fromTime, toTime)
  now = os.date('*t'); from = os.date('*t'); to = os.date('*t')
  from.hour = fromTime[1];  from.min = fromTime[2]
  to.hour   = toTime[1];    to.min   = toTime[2]

  if os.time(from) <= os.time(now) and os.time(now) <= os.time(to) then
    debug("Time is in range.")
    return true
  else
    debug("Time is not in range.")
    return false
  end
end


function weekDay()
  w = tonumber(os.date("%w"))
  if w > 0 then
    return w-1
  else
    return 6
  end
end


function onTime()
  weekday = weekDay()
  for x, o in pairs(onTimes) do
    for y, i in pairs(o[1]) do
      if i == weekday then
        fromTime = o[2]
        toTime   = o[3]
      end
    end
  end

  if timeInRange(fromTime, toTime) then
    debug("Time is in onTimes.")
    return true
  else
    debug("Time is not in onTimes.")
    return false
  end
end


function countStations()
  cmd = [[(for dev in `ifconfig | grep -o 'wlan[0-9]\(-[0-9]\)*'`;
          do iw dev $dev station dump; done) | grep -c Station]]
  f = assert(io.popen(cmd, 'r'))
  stations = tonumber(assert(f:read('*a')))
  debug("Stations: " .. stations)
  return stations
end


function getFirstArg()
  if arg[1] then
    debug("Argument: " .. arg[1])
    return arg[1]
  end
end


function resetButton()
  os.execute("uci set wireless.nightmode.interrupt=0")
  os.execute("uci commit wireless.nightmode.interrupt")
end


function getButton()
  cmd = [[uci get wireless.nightmode.interrupt]]
  f = assert(io.popen(cmd, 'r'))
  button = tonumber(assert(f:read('*a')))
  debug("Button: " .. button)
  if button == 1 then
    return true
  else
    return false
  end
end


function getWifi()
  cmd = [[iw dev | grep -c phy]]
  f = assert(io.popen(cmd, 'r'))
  phy = tonumber(assert(f:read('*a')))
  if phy > 0 then
    debug("WiFi is on")
    return true
  else
    debug("WiFi is off")
    return false
  end
end


function wifiEnabled()
  cmd = [[uci get wireless.nightmode.wifion]]
  f = assert(io.popen(cmd, 'r'))
  switch = tonumber(assert(f:read('*a')))
  debug("Switch: " .. switch)
  if switch == 1 then
    return true
  else
    return false
  end
end


function setWifi(state)
  if state == true then
    debug("WiFi should be on")
  else
    debug("WiFi should be off")
  end

  if getWifi() ~= state then
    if state == true then
      debug("Change WiFi state to: on")
      os.execute("wifi on")
    else
      debug("Change WiFi state to: down")
      os.execute("wifi down")
    end
  else
    debug("Nothing to do")
  end
end


function main()
  if onTime() and wifiEnabled() then
    debug("It's onTime!")
    resetButton()
    setWifi(true)
  else
    debug("It's offTime!")
    if countStations() == 0 then
      debug("No stations connected.")
      if getButton() then
        debug("Got button trigger. Enable WiFi!")
        resetButton()
        setWifi(true)
      else
        debug("Disable WiFi!")
        resetButton()
        setWifi(false)
      end
    else
      resetButton()
      debug("There are stations connected. Keep WiFi on!")
    end
  end
end


main()