local modem = peripheral.find("modem", function(_, m) return m.isWireless() end)
local monitor = peripheral.find("monitor")

local channel = 42

if not modem then error("Sem modem wireless 📡") end

modem.open(channel)

if monitor then monitor.setTextScale(0.5) end

while true do
    local event, side, ch, reply, data = os.pullEvent("modem_message")

    if ch == channel then
        local percent = math.floor(data.percent * 100)

        if monitor then
            monitor.clear()
            monitor.setCursorPos(1,1)

            monitor.write("Energia: "..percent.."%")
            monitor.setCursorPos(1,3)
            monitor.write("In: "..data.input.." FE/t")
            monitor.setCursorPos(1,4)
            monitor.write("Out: "..data.output.." FE/t")

            -- barra
            local bar = math.floor(percent / 5)

            monitor.setCursorPos(1,6)
            monitor.write("[")
            monitor.write(string.rep("#", bar))
            monitor.write(string.rep(" ", 20 - bar))
            monitor.write("]")
        else
            print("Energia:", percent.."%")
        end
    end
end
