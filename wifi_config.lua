-- Definition of colors
colorHourAM=string.char(0,0,5)
colorHourAMend=string.char(0,0,40)
colorHourPM=string.char(15,15,0)
colorHourPMend=string.char(20,20,0)
colorMin=string.char(40,0,0)
colorSec=string.char(0,30,0)

--Function to save WiFi-parameters into file-system as wlancfg.lua
function save_wifi_param(ssid,password,ntpserver,timezoneoffset)
 file.remove("wlancfg.lua");
 file.open("wlancfg.lua","w+");
 w = file.writeline('-- Tell the chip to connect to thi access point');
 w = file.writeline('wifi.setmode(wifi.STATION)');
 w = file.writeline('wifi.sta.config("' .. ssid .. '","' .. password .. '")');
 w = file.writeline('sntpserverhostname="' .. ntpserver ..'"');
 w = file.writeline('timezoneoffset="' .. timezoneoffset ..'"');
 file.close();
 ssid,password,bssid_set,bssid=nil,nil,nil,nil
end

--main routine
function logic()
--do lcd-stuff from display.lua  
  prepare()
  tmr.alarm(2, 600000, 1, function ()
  --resync time every 10 minutes (600s)
  net.dns.resolve(sntpserverhostname, function(sk,sntpip)
   sntp.sync(sntpip,
     function(sec,usec,sntpip)
      print('sync', sec, usec, sntpip)
     end,
     function()
       print('failed!')
     end)
   end
 )
   
  end)

--update display and LED-strip every second  
  tmr.alarm(1, 1000, 1 ,function()
   disp:firstPage()
   unix_sec, unix_usec = rtctime.get()
   date = getLocalTime(unix_sec +1,timezoneoffset)
--   print("Es ist " .. date.hours ..":" .. date.minutes ..":" .. date.seconds .. " am " ..date.day .. "." .. date.month .."." ..date.year)
   ledstring_sec = string.char(0,0,0):rep(date.seconds) .. colorSec .. string.char(0,0,0):rep(60-date.seconds-1)
--on AM time (0:00-11:59) blue color, on PM time (12:00-23:59) yellow color
   if (date.hours>11) then
     hourcolor = colorHourPM
     hourcolor_end = colorHourPMend
   else
     hourcolor = colorHourAM
     hourcolor_end = colorHourAMend
   end
   ledcount4hours = (date.hours%12)*5+(date.minutes/12)+1
   ledstring_hour = hourcolor:rep(ledcount4hours-1) .. hourcolor_end  .. string.char(0,0,0):rep(60-ledcount4hours+1)
   ledstring_hour_min = string.sub(ledstring_hour,1,(date.minutes)*3) .. colorMin .. string.sub(ledstring_hour,(1+date.minutes*3)+3,180)
   
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
  net.dns.resolve(sntpserverhostname, function(sk,sntpip)
   sntp.sync(sntpip,
     function(sec,usec,sntpip)
      print('sync', sec, usec, sntpip)
     end,
     function()
       print('failed!')
     end)
   end
 )

--load time calculation routines
 dofile("timecore.lc")
-- startServer
 dofile("webserver.lc")
 startWebServer()
 logic()
end





--MAIN PROGRAM ENTRY POINT, CALLED FROM init.lua

--if unable to connect for 30 seconds, start enduser_setup-routine
--load Wifi-configuration and try to connect
dofile("wlancfg.lua")

--load OLED Display
dofile("display.lc")


connect_counter = 0
tmr.alarm(0, 100, 1, function()
 if wifi.sta.status() ~= 5 then
    connect_counter = connect_counter + 1
    print("Connecting to AP...")
    if (connect_counter % 10 > 5) then
      ws2812.writergb(1,string.char(20,0,0):rep(60))
    else
      ws2812.writergb(1,string.char(0,0,0):rep(60))
    end
    if(connect_counter == 300) then
      tmr.stop(0)
      print("Starting WiFi setup mode")
      ws2812.write(1,string.char(0,20,20):rep(60))
      enduser_setup.start(
       function()
        ssid,password,bssid_set,bssid=wifi.sta.getconfig()
        save_wifi_param(ssid,password,"ptbtime1.ptb.de",0);
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

