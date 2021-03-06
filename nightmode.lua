#!/usr/bin/env lua
-- author = Michael Niewoehner <mniewoeh@stud.hs-offenburg.de>

-- --------------------------------------------------
-- Begin of user settings
-- --------------------------------------------------

debugOn = true

onTimes = {
--  Weekday(s)  #HH:MM    #HH:MM
  { {0,1,2,3},  {07,00},  {22,00} },    -- Mo-Thu
  { {4},        {07,00},  {23,59} },    -- Fr
  { {5,6},      {10,00},  {22,00} }     -- Sa-Su
}

-- --------------------------------------------------
-- End of user settings
-- --------------------------------------------------


require("uci")
conf = uci.cursor()


function debug(msg)
  if debugOn == true then
    print(msg)
    os.execute("logger \"nightmode :: " .. msg .. "\"")
  end
end


function timeInRange(fromTime, toTime)
  local now = os.date('*t')
  local from = os.date('*t')
  local to = os.date('*t')
  from.hour = fromTime[1]
  from.min = fromTime[2]
  to.hour   = toTime[1]
  to.min   = toTime[2]

  if os.time(from) <= os.time(now) and os.time(now) <= os.time(to) then
    debug("Time is in range.")
    return true
  else
    debug("Time is not in range.")
    return false
  end
end


function weekDay()
  local w = tonumber(os.date("%w"))
  if w > 0 then
    return w-1
  else
    return 6
  end
end


function onTime()
  local weekday = weekDay()
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
  local cmd = [[(for dev in `ifconfig | grep -o 'wlan[0-9]\(-[0-9]\)*'`;
                do iw dev $dev station dump; done) | grep -c Station]]
  local f = assert(io.popen(cmd, 'r'))
  local stations = tonumber(assert(f:read('*a')))
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
  conf:set("wireless", "nightmode", "interrupt", 0)
  conf:commit("wireless")
end


function getButton()
  local button = tonumber(conf:get("wireless", "nightmode", "interrupt"))
  debug("Button: " .. button)
  if button == 1 then
    return true
  else
    return false
  end
end


function getWifi()
  local count = 0
  conf:foreach("wireless", "wifi-iface", function(s) count=count+1 end)
  local cmd = [[iw dev | grep -c wlan]]
  local f = assert(io.popen(cmd, 'r'))
  local phy = tonumber(assert(f:read('*a')))
  if phy == count then
    debug("WiFi is on")
    return true
  else
    debug("WiFi is off")
    return false
  end
end


function wifiEnabled()
  local switch = tonumber(conf:get("wireless", "nightmode", "wifion"))
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


function init()
  if not conf:get("wireless", "nightmode", "wifion") or
     not conf:get("wireless", "nightmode", "interrupt") then
       conf:set("wireless", "nightmode", 0)
       conf:set("wireless", "nightmode", "wifion", 1)
       conf:set("wireless", "nightmode", "interrupt", 0)
       conf:commit("wireless")
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


init()
main()
