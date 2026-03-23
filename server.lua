local matrix = peripheral.find("inductionPort")
if not matrix then error("Induction Port não encontrado!", 0) end

local modem = peripheral.find("modem", function(_, m) return m.isWireless() end)
if not modem then error("Modem wireless não encontrado!", 0) end

rednet.open(peripheral.getName(modem))
print("Transmitindo dados da matrix...")

while true do
    local data = {
        energy       = matrix.getEnergy(),
        maxEnergy    = matrix.getMaxEnergy(),
        pct          = matrix.getEnergyFilledPercentage(),
        input        = matrix.getLastInput(),
        output       = matrix.getLastOutput(),
        transferCap  = matrix.getTransferCap(),
    }
    rednet.broadcast(data, "matrix_data")
    os.sleep(1)
end
