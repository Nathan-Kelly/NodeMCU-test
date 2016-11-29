--[[Runs when UART receives data.  Checks packet type and attempts to send data packets via wifi and
    run commands.]]
function uart_ondata(data)

       print("Received via UART: "..data)

       --check packet type
       if data:sub(1, 3) == "lux" then

           --packet is from light sensor
           set_packet_lux(data)
           if wifi.sta.status() == 5 and wifi.sta.getrssi() > -75 then

               if not synced then
                   print("WARNING: Time not synced.")
               end

               sendpacket()
               print("+") --notify Arduino that packet was sent
           else
               print("-") --packet could not be sent
           end
       else
           --packet is command (required to debug interactively)
           cmd = loadstring(data)
           if cmd then
               cmd()
           end
       end
       
       collectgarbage()
end


function inituart() 
   --uncomment to use altarnate UART pins (gpio13/15)
   --uart.alt(1)

   --see if manually configuring uart params helps at all
    print("Initializing UART...")

    --The default baud rate for ESP boards is 115200
    uart.setup(0, 115200, 8, uart.PARITY_NONE, uart.STOPBITS_1, 0)

    --set callback function when data is received
    uart.on("data", "\n", uart_ondata, 0)
end

function set_packet(_str) packet = _str:sub(1, -2).."\n" end
function set_packet_lux(_str) 
  sec, usec = rtctime.get()
  packet = _str:sub(1, -2).."1"..sec.."\n" --packet structure for lux: 
end


inituart()
