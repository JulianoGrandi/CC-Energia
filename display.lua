local modem = peripheral.find("modem", function(_, m) return m.isWireless() end)
if not modem then error("Modem wireless não encontrado!", 0) end

rednet.open(peripheral.getName(modem))

local display = peripheral.find("monitor") or term
if display ~= term then display.setTextScale(0.5) end

-- ---- Helpers (mesmos do programa original) ----
local J_TO_RF = 2.5

local function formatEnergy(j)
    local rf = j * J_TO_RF
    if rf >= 1e18 then return string.format("%.2f ERF", rf/1e18)
    elseif rf >= 1e15 then return string.format("%.2f PRF", rf/1e15)
    elseif rf >= 1e12 then return string.format("%.2f TRF", rf/1e12)
    elseif rf >= 1e9  then return string.format("%.2f GRF", rf/1e9)
    elseif rf >= 1e6  then return string.format("%.2f MRF", rf/1e6)
    elseif rf >= 1e3  then return string.format("%.2f kRF", rf/1e3)
    else return string.format("%.2f RF", rf) end
end

local function formatRate(j) return formatEnergy(j) .. "/t" end

local function barColor(p)
    if p > 0.6 then return colors.green
    elseif p > 0.3 then return colors.yellow
    else return colors.red end
end

local function drawBar(d, x, y, width, pct, fill, bg)
    local filled = math.floor(pct * width)
    for i = 0, width-1 do
        d.setCursorPos(x+i, y)
        d.setBackgroundColor(i < filled and fill or bg)
        d.write(" ")
    end
    d.setBackgroundColor(colors.black)
end

local function writeCentered(d, y, text, fg, bg)
    local w = d.getSize()
    d.setCursorPos(math.floor((w - #text)/2)+1, y)
    if fg then d.setTextColor(fg) end
    if bg then d.setBackgroundColor(bg) end
    d.write(text)
    d.setTextColor(colors.white)
    d.setBackgroundColor(colors.black)
end

local function writeLine(d, y, label, value, lc, vc)
    local w = d.getSize()
    d.setCursorPos(2, y)
    d.setTextColor(lc or colors.lightGray)
    d.write(label)
    local v = tostring(value)
    d.setCursorPos(w - #v, y)
    d.setTextColor(vc or colors.white)
    d.write(v)
    d.setTextColor(colors.white)
end

local function drawDivider(d, y)
    local w = d.getSize()
    d.setCursorPos(1, y)
    d.setTextColor(colors.gray)
    d.write(string.rep("-", w))
    d.setTextColor(colors.white)
end

local function render(d, data)
    local w, h = d.getSize()
    local net = data.input - data.output
    local netStr = (net > 0 and "+" or "") .. formatRate(net)

    local timeStr = "---"
    if net > 0 and data.pct < 1 then
        local s = math.floor((data.maxEnergy - data.energy) / net / 20)
        timeStr = s > 3600 and string.format(">%dh cheio", s/3600)
                or s > 60  and string.format("%dm cheio",  math.floor(s/60))
                or string.format("%ds cheio", s)
    elseif net < 0 and data.pct > 0 then
        local s = math.floor(data.energy / math.abs(net) / 20)
        timeStr = s > 3600 and string.format(">%dh vazio", s/3600)
                or s > 60  and string.format("%dm vazio",  math.floor(s/60))
                or string.format("%ds vazio", s)
    end

    d.setBackgroundColor(colors.black)
    d.clear()

    -- Título
    d.setCursorPos(1,1)
    d.setBackgroundColor(colors.blue)
    d.write(string.rep(" ", w))
    writeCentered(d, 1, "[ INDUCTION MATRIX ]", colors.white, colors.blue)
    d.setBackgroundColor(colors.black)

    writeCentered(d, 3, string.format("%.1f%%", data.pct * 100), barColor(data.pct))
    drawBar(d, 3, 4, w-4, data.pct, barColor(data.pct), colors.gray)
    writeCentered(d, 5, formatEnergy(data.energy) .. " / " .. formatEnergy(data.maxEnergy), colors.lightBlue)

    drawDivider(d, 6)
    writeLine(d, 7,  " Entrada:", formatRate(data.input),       colors.lightGray, colors.lime)
    writeLine(d, 8,  " Saida:  ", formatRate(data.output),      colors.lightGray, colors.red)
    writeLine(d, 9,  " Fluxo:  ", netStr,                       colors.lightGray, net >= 0 and colors.lime or colors.orange)
    writeLine(d, 10, " Cap.Max:", formatRate(data.transferCap), colors.lightGray, colors.cyan)
    drawDivider(d, 11)
    writeLine(d, 12, " Estimativa:", timeStr, colors.lightGray, colors.yellow)

    d.setCursorPos(1, h)
    writeCentered(d, h, "wireless | q = sair", colors.gray)
end

-- ---- Loop principal ----
print("Aguardando dados...")

parallel.waitForAny(
    function()
        while true do
            local _, _, msg, protocol = rednet.receive("matrix_data", 5)
            if msg then
                pcall(render, display, msg)
            else
                -- Timeout: avisa que perdeu conexão
                display.clear()
                display.setCursorPos(1,1)
                display.setTextColor(colors.red)
                writeCentered(display, 3, "SEM SINAL...", colors.red)
            end
        end
    end,
    function()
        while true do
            local _, key = os.pullEvent("key")
            if key == keys.q then break end
        end
    end
)

term.clear()
term.setCursorPos(1,1)
print("Encerrado.")


---

## Setup físico
```
[Induction Port] ←→ [Computador 1] [Wireless Modem]
                                          ↕ (ar)
                     [Wireless Modem] [Computador 2] ←→ [Monitor]
