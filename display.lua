-- JARVIS DISPLAY 3x5

local modem = peripheral.find("modem", function(_, m)
    return m.isWireless()
end)

local monitor = peripheral.find("monitor")

local channel = 42

if not modem then error("Sem modem 📡") end
if not monitor then error("Sem monitor 🖥️") end

modem.open(channel)
monitor.setTextScale(0.5)

local historico = {}

local function corStatus(p)
    if p < 20 then return colors.red end
    if p < 70 then return colors.yellow end
    return colors.green
end

local function barra(p, largura)
    local fill = math.floor((p/100)*largura)

    for i=1,largura do
        if i <= fill then
            monitor.setBackgroundColor(colors.lime)
        else
            monitor.setBackgroundColor(colors.gray)
        end
        monitor.write(" ")
    end
    monitor.setBackgroundColor(colors.black)
end

local function grafico(w,h)
    for i=1,#historico do
        local v = historico[i]
        local y = h - math.floor((v/100)*(h-5))

        monitor.setCursorPos(i,y)
        monitor.setTextColor(colors.cyan)
        monitor.write("█")
    end
end

while true do
    local _,_,ch,_,data = os.pullEvent("modem_message")

    if ch == channel then
        local w,h = monitor.getSize()

        table.insert(historico, data.percent)
        if #historico > w then table.remove(historico,1) end

        monitor.clear()

        -- 🔷 TÍTULO CENTRALIZADO
        local title = "🤖 JARVIS ENERGY CORE"
        monitor.setCursorPos(math.floor((w - #title)/2),1)
        monitor.setTextColor(colors.cyan)
        monitor.write(title)

        monitor.setCursorPos(1,2)
        monitor.setTextColor(colors.gray)
        monitor.write(string.rep("=",w))

        -- ⚡ ENERGIA GRANDE
        local percent = math.floor(data.percent)
        local energyText = percent .. "%"

        monitor.setCursorPos(math.floor((w - #energyText)/2),4)
        monitor.setTextColor(colors.white)
        monitor.write(energyText)

        -- 📊 BARRA FULL WIDTH
        monitor.setCursorPos(1,6)
        barra(data.percent, w)

        -- 🔁 FLUXO
        monitor.setCursorPos(2,8)
        monitor.setTextColor(colors.green)
        monitor.write("IN : +"..data.input)

        monitor.setCursorPos(2,9)
        monitor.setTextColor(colors.red)
        monitor.write("OUT: -" ..data.output)

        -- 🤖 STATUS IA
        monitor.setCursorPos(2,11)
        monitor.setTextColor(corStatus(data.percent))
        monitor.write("IA: "..data.status)

        monitor.setCursorPos(2,12)
        monitor.setTextColor(colors.orange)
        monitor.write("Sistema: "..(data.ativo and "ON" or "OFF"))

        -- 📈 GRÁFICO (parte de baixo)
        grafico(w,h)
    end
end
