-- MATRIX SERVER

local modem = peripheral.find("modem", function(_, m)
    return m.isWireless()
end)

local matrix = peripheral.wrap("back") -- seu caso: back InductionPort

local channel = 42

if not modem then error("Sem modem wireless 📡") end
if not matrix then error("Matrix não encontrada ⚡") end

modem.open(channel)

while true do
    local data = {
        percent = matrix.getEnergyFilledPercentage(),
        input = matrix.getLastInput(),
        output = matrix.getLastOutput()
    }

    modem.transmit(channel, channel, data)

    sleep(1)
end
