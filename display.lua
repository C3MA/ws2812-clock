function init_i2c_display()
    -- SDA and SCL can be assigned freely to available GPIOs
    local sda = 5 -- GPIO14
    local scl = 6 -- GPIO12
    local sla = 0x3c
    i2c.setup(0, sda, scl, i2c.SLOW)
    disp = u8g.ssd1306_128x64_i2c(sla)
end

function prepare()
    disp:setFont(u8g.font_6x10)
    disp:setFontRefHeightExtendedText()
    disp:setDefaultForegroundColor()
    disp:setFontPosTop()
end


init_i2c_display()
