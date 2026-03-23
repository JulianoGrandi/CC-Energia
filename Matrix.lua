local modem = peripheral.find("modem", function(_, m) return m.isWireless() end)
local matrix = peripheral.find("inductionMatrix") or peripheral.find("mekanism_induction_port")

local channel = 42

if not modem then error("Sem modem wireless 📡") end
if not matrix then error("Matrix não encontrada ⚡") end

modem.open(channel)

while true do
    local data = {
        energy = matrix.getEnergy(),
        max = matrix.getMaxEnergy(),
        percent = matrix.getEnergyFilledPercentage(),
        input = matrix.getLastInput(),
        output = matrix.getLastOutput()
    }

    modem.transmit(channel, channel, data)

    sleep(1)
end
