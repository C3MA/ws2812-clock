--Function to save WiFi-parameters into file-system as wlancfg.lua
function save_wifi_param()
 ssid,password,bssid_set,bssid=wifi.sta.getconfig()
 file.remove("wlancfg.lua");
 file.open("wlancfg.lua","w+");
 w = file.writeline('-- Tell the chip to connect to thi access point');
 w = file.writeline('wifi.setmode(wifi.STATION)');
 w = file.write('wifi.sta.config("' .. ssid .. '","' .. password .. '")');
 file.close();
 ssid,password,bssid_set,bssid=nil,nil,nil,nil
end


function CurrentDate(z)
    local z = math.floor(z / 86400) + 719468
    local era = math.floor(z / 146097)
    local doe = math.floor(z - era * 146097)
    local yoe = math.floor((doe - doe / 1460 + doe / 36524 - doe / 146096) / 365)
    local y = math.floor(yoe + era * 400)
    local doy = doe - math.floor((365 * yoe + yoe / 4 - yoe / 100))
    local mp = math.floor((5 * doy + 2) / 153)
    local d = math.ceil(doy - (153 * mp + 2) / 5 + 1)
    local m = math.floor(mp + (mp < 10 and 3 or -9))
    return y + (m <= 2 and 1 or 0), m, d
end

function CurrentTime(unixTime, TIMEZONE, DST)
    local unixTime = math.floor(unixTime + (60*60*((TIMEZONE+DST) or 0)))
    local hours = math.floor(unixTime / 3600 % 24)
    local minutes = math.floor(unixTime / 60 % 60)
    local seconds = math.floor(unixTime % 60)

    local year, month, day = CurrentDate(unixTime)
    return {
        year = year,
        month = month, 
        day = day,
        hours = hours,
        minutes = minutes < 10 and "0" .. minutes or minutes,
        seconds = seconds < 10 and "0" .. seconds or seconds
    }
end

function startTelnetServer()
   -- a simple telnet server
    s=net.createServer(net.TCP, 180)
    s:listen(2323, function(c)
       function s_output(str)
          if(c~=nil)
             then c:send(str)
          end
       end
       node.output(s_output, 0)   -- re-direct output to function s_ouput.
       c:on("receive", function(c, l)
          node.input(l)           -- works like pcall(loadstring(l)) but support multiples separate lines
       end)
       c:on("disconnection", function(c)
          node.output(nil)        -- un-register the redirect output function, output goes to serial
       end)
       print("Welcome to NodeMCU world.")
    end)
end



--main routine
function logic()
--do lcd-stuff from display.lua  
  prepare()
  tmr.alarm(2, 600000, 1, function ()
  --resync time every 10 minutes (600s)
  sntp.sync('192.53.103.108',
    function(sec,usec,server)
     print('sync', sec, usec, server)
    end,
    function()
      print('failed!')
    end
 )
   
  end)

--update display and LED-strip every second  
  tmr.alarm(1, 1000, 1 ,function()
   disp:firstPage()
   unix_sec, unix_usec = rtctime.get()
   date = CurrentTime(unix_sec, TIMEZONE, DST)
--   print("Time : " , unix_sec)
--   print("Clock: ", date.hours, ":", date.minutes, ":", date.seconds, "   ", date.day, ".",date. month, ".", date.year)
   --ws2812.writergb(1,string.char(0):rep(360))
   ledstring_sec = string.char(0,0,0):rep(date.seconds) .. string.char(0,30,0) .. string.char(0,0,0):rep(60-date.seconds-1)
--on AM time (0:00-11:59) blue color, on PM time (12:00-23:59) yellow color
   if (date.hours>11) then
     hourcolor = string.char(30,30,0)
   else
     hourcolor = string.char(0,0,30)
   end
   ledcount4hours = (date.hours%12)*5+(date.minutes/12)+1
   ledstring_hour = hourcolor:rep(ledcount4hours) .. string.char(0,0,0):rep(60-ledcount4hours+1)
   ledstring_hour_min = string.sub(ledstring_hour,1,(date.minutes)*3) .. string.char(30,0,0) .. string.sub(ledstring_hour,(1+date.minutes*3)+3,180)
   
   repeat
    disp:drawStr(42, 20, date.seconds)
    disp:drawStr(0, 0, wifi.sta.getip())
    disp:drawStr(0, 20, date.hours .. ":")
    disp:drawStr(21, 20, date.minutes .. ":")
    disp:drawStr(0, 30, date.day .. ".")
    disp:drawStr(21, 30, date.month .. ".")
    disp:drawStr(42, 30, date.year)
    until disp:nextPage() == false
    ws2812.writergb(1,ledstring_hour_min)
    ws2812.writergb(2,ledstring_sec)
  end)
end





--init_logic run once after successfully established network-connection 
function init_logic()
--Sync time with ptbtime1.ptb.de
 sntp.sync('192.53.103.108',
    function(sec,usec,server)
     print('sync', sec, usec, server)
    end,
    function()
      print('failed!')
    end
 )
 startTelnetServer()
 --TIMEZONE CET (UTC+1)
 TIMEZONE=1
 --daylight savings time: +1h
 DST=1
 logic()
end





--MAIN PROGRAM ENTRY POINT, CALLED FROM init.lua

--if unable to connect for 30 seconds, start enduser_setup-routine
 --load Wifi-configuration and try to connect
dofile("wlancfg.lua")

 --load OLED Display
dofile("display.lua")
connect_counter = 0
tmr.alarm(0, 100, 1, function()
 if wifi.sta.status() ~= 5 then
    connect_counter = connect_counter + 1
    print("Connecting to AP...")
    if(connect_counter == 300) then
      tmr.stop(0)
      print("Starting WiFi setup mode")
      enduser_setup.start(
       function()
        save_wifi_param();
        print("Connected to wifi as:" .. wifi.sta.getip());
        print("Saved parameters in wlancfg.lua");
        init_logic();
       end,
       function(err, str)
        print("enduser_setup: Err #:" .. err .. ": " .. str);
       end
      )
    end
  else
   tmr.stop(0)
   print('IP: ',wifi.sta.getip())
   init_logic()
  end
 end
)
      
--at this point we should be ready to go....

