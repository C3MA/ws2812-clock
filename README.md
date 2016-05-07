# ws2812-clock
Clock with LEDs of type WS2812, controlled by ESP8266 , for the C3MA room

two rings have to be built with WS2812-LEDs.
One ring shows the seconds, the other one shows the hours and minutes.
Also there is code to control a I2C-Display (128x64) to show the time.

the code uses the enduser-setup-module of NodeMCU: If it does not get wifi-access within 30 seconds, it opens up its own Wireless-network with a capture portal to enter ssid and password. These are stores in the wlancfg.lua. Anyway: To get everything working the wlancfg has to be present in filesystem of ESP8266. You can upload the template in the project

Telnet access to the Clock is possible via tcp port 2323 to get access to the nodemcu interpreter.

Connections to be made:

Display: SDA on GPIO14 and SCL on GPIO12

led-ring showing the seconds: GPIO4
led-ring showing the hours and minutes: GPIO5

connect CH_PD with +3.3V


