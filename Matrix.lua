-- JARVIS SERVER

local modem = peripheral.find("modem", function(_, m)
    return m.isWireless()
end)

local matrix = peripheral.wrap("back")

-- opcional (controle)
local rs = peripheral.find("redstoneIntegrator")

local channel = 42

if not modem then error("Sem modem 📡") end
if not matrix then error("Matrix não encontrada ⚡") end

modem.open(channel)

local ligado = false

while true do
    local percent = matrix.getEnergyFilledPercentage() * 100
    local input = matrix.getLastInput()
    local output = matrix.getLastOutput()

    -- 🧠 IA SIMPLES
    local acao = "IDLE"

    if percent < 20 then
        acao = "LIGAR"
        if rs then rs.setOutput("front", true) end
        ligado = true

    elseif percent > 90 then
        acao = "DESLIGAR"
        if rs then rs.setOutput("front", false) end
        ligado = false
    end

    local data = {
        percent = percent,
        input = input,
        output = output,
        status = acao,
        ativo = ligado
    }

    modem.transmit(channel, channel, data)

    sleep(1)
end
