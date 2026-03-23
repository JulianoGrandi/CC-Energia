-- DISPLAY CLIENT

local modem = peripheral.find("modem", function(_, m)
    return m.isWireless()
end)

-- 🔍 detectar monitor automaticamente
local monitor = nil

for _, name in ipairs(peripheral.getNames()) do
    local t = peripheral.getType(name)
    if string.find(t, "monitor") then
        monitor = peripheral.wrap(name)
        break
    end
end

local channel = 42

if not modem then error("Sem modem wireless 📡") end
if not monitor then error("Monitor não encontrado 🖥️") end

modem.open(channel)
monitor.setTextScale(0.5)

local screen = 1
local history = {}

local function status(percent, input, output)
    if percent < 20 then return colors.red, "CRITICAL" end
    if input > output then return colors.blue, "CHARGING" end
    if output > input then return colors.orange, "DRAINING" end
    return colors.green, "STABLE"
end

local function drawBar(x,y,p)
    local w = 24
    local fill = math.floor((p/100)*w)

    monitor.setCursorPos(x,y)

    for i=1,w do
        if i <= fill then
            monitor.setBackgroundColor(colors.lime)
        else
            monitor.setBackgroundColor(colors.gray)
        end
        monitor.write(" ")
    end

    monitor.setBackgroundColor(colors.black)
end

local function drawMain(data)
    local percent = math.floor(data.percent*100)
    local color, txt = status(percent, data.input, data.output)

    monitor.clear()

    monitor.setCursorPos(1,1)
    monitor.setTextColor(colors.cyan)
    monitor.write("⚡ INDUCTION MATRIX")

    monitor.setCursorPos(1,2)
    monitor.setTextColor(colors.gray)
    monitor.write(string.rep("=",30))

    monitor.setCursorPos(1,4)
    monitor.setTextColor(colors.white)
    monitor.write("Charge: "..percent.."%")

    drawBar(1,6,percent)

    monitor.setCursorPos(1,8)
    monitor.setTextColor(colors.green)
    monitor.write("IN : +"..data.input)

    monitor.setCursorPos(1,9)
    monitor.setTextColor(colors.red)
    monitor.write("OUT: -" ..data.output)

    monitor.setCursorPos(1,11)
    monitor.setTextColor(color)
    monitor.write("STATUS: "..txt)
end

local function drawGraph()
    monitor.clear()

    monitor.setCursorPos(1,1)
    monitor.setTextColor(colors.cyan)
    monitor.write("⚡ ENERGY GRAPH")

    local w,h = monitor.getSize()

    for i = 1, #history do
        local value = history[i]
        local y = h - math.floor((value/100)*h)

        monitor.setCursorPos(i, y)
        monitor.setTextColor(colors.lime)
        monitor.write("█")
    end
end

while true do
    local event = {os.pullEvent()}

    if event[1] == "modem_message" then
        local _,_,ch,_,data = table.unpack(event)

        if ch == channel then
            local percent = math.floor(data.percent*100)

            table.insert(history, percent)
            if #history > 50 then table.remove(history,1) end

            if screen == 1 then
                drawMain(data)
            else
                drawGraph()
            end
        end
    end

    if event[1] == "monitor_touch" then
        screen = screen + 1
        if screen > 2 then screen = 1 end
    end
end
