-- ============================================
--   Mekanism Induction Matrix Monitor
--   Conecte o computador ao Induction Port
--   via modem ou adjacente.
--   Requer monitor (opcional, usa terminal
--   como fallback).
-- ============================================

local REFRESH_RATE = 1 -- segundos entre atualizações

-- ---- Formatação de energia ----
local function formatEnergy(joules)
    if joules >= 1e18 then
        return string.format("%.2f EJ", joules / 1e18)
    elseif joules >= 1e15 then
        return string.format("%.2f PJ", joules / 1e15)
    elseif joules >= 1e12 then
        return string.format("%.2f TJ", joules / 1e12)
    elseif joules >= 1e9 then
        return string.format("%.2f GJ", joules / 1e9)
    elseif joules >= 1e6 then
        return string.format("%.2f MJ", joules / 1e6)
    elseif joules >= 1e3 then
        return string.format("%.2f kJ", joules / 1e3)
    else
        return string.format("%.2f J", joules)
    end
end

local function formatRate(joules)
    return formatEnergy(joules) .. "/t"
end

-- ---- Barra de progresso ----
local function drawBar(display, x, y, width, percent, fillColor, bgColor)
    local filled = math.floor(percent * width)
    for i = 0, width - 1 do
        display.setCursorPos(x + i, y)
        if i < filled then
            display.setBackgroundColor(fillColor)
            display.write(" ")
        else
            display.setBackgroundColor(bgColor)
            display.write(" ")
        end
    end
    display.setBackgroundColor(colors.black)
end

-- ---- Cor da barra baseada no percentual ----
local function barColor(pct)
    if pct > 0.6 then return colors.green
    elseif pct > 0.3 then return colors.yellow
    else return colors.red end
end

-- ---- Escreve texto centralizado ----
local function writeCentered(display, y, text, fg, bg)
    local w, _ = display.getSize()
    local x = math.floor((w - #text) / 2) + 1
    display.setCursorPos(x, y)
    if fg then display.setTextColor(fg) end
    if bg then display.setBackgroundColor(bg) end
    display.write(text)
    display.setTextColor(colors.white)
    display.setBackgroundColor(colors.black)
end

-- ---- Linha com label e valor ----
local function writeLine(display, y, label, value, labelColor, valueColor)
    local w, _ = display.getSize()
    display.setCursorPos(2, y)
    display.setTextColor(labelColor or colors.lightGray)
    display.write(label)
    local valStr = tostring(value)
    display.setCursorPos(w - #valStr, y)
    display.setTextColor(valueColor or colors.white)
    display.write(valStr)
    display.setTextColor(colors.white)
end

-- ---- Linha divisória ----
local function drawDivider(display, y)
    local w, _ = display.getSize()
    display.setCursorPos(1, y)
    display.setTextColor(colors.gray)
    display.write(string.rep("-", w))
    display.setTextColor(colors.white)
end

-- ---- Renderiza a tela inteira ----
local function render(display, matrix, prevEnergy)
    local w, h = display.getSize()

    local energy     = matrix.getEnergy()
    local maxEnergy  = matrix.getMaxEnergy()
    local pct        = matrix.getEnergyFilledPercentage() -- 0.0 a 1.0
    local input      = matrix.getLastInput()
    local output     = matrix.getLastOutput()
    local transferCap = matrix.getTransferCap()

    -- Calcular fluxo líquido
    local net = input - output
    local netStr
    if net > 0 then
        netStr = "+" .. formatRate(net)
    elseif net < 0 then
        netStr = "-" .. formatRate(math.abs(net))
    else
        netStr = "0 J/t"
    end

    -- Estimar tempo para encher/esvaziar
    local timeStr = "---"
    if net > 0 and pct < 1 then
        local remaining = maxEnergy - energy
        local ticks = remaining / net
        local seconds = math.floor(ticks / 20)
        if seconds > 3600 then
            timeStr = string.format(">%dh cheio", math.floor(seconds/3600))
        elseif seconds > 60 then
            timeStr = string.format("%dm cheio", math.floor(seconds/60))
        else
            timeStr = string.format("%ds cheio", seconds)
        end
    elseif net < 0 and pct > 0 then
        local ticks = energy / math.abs(net)
        local seconds = math.floor(ticks / 20)
        if seconds > 3600 then
            timeStr = string.format(">%dh vazio", math.floor(seconds/3600))
        elseif seconds > 60 then
            timeStr = string.format("%dm vazio", math.floor(seconds/60))
        else
            timeStr = string.format("%ds vazio", seconds)
        end
    end

    -- Limpar tela
    display.setBackgroundColor(colors.black)
    display.clear()

    -- Título
    display.setCursorPos(1, 1)
    display.setBackgroundColor(colors.blue)
    display.setTextColor(colors.white)
    display.write(string.rep(" ", w))
    writeCentered(display, 1, "[ INDUCTION MATRIX ]", colors.white, colors.blue)
    display.setBackgroundColor(colors.black)

    -- Percentual grande
    local pctStr = string.format("%.1f%%", pct * 100)
    writeCentered(display, 3, pctStr, barColor(pct))

    -- Barra de energia
    local barW = w - 4
    drawBar(display, 3, 4, barW, pct, barColor(pct), colors.gray)

    -- Energia armazenada
    writeCentered(display, 5,
        formatEnergy(energy) .. " / " .. formatEnergy(maxEnergy),
        colors.lightBlue)

    drawDivider(display, 6)

    -- Stats de I/O
    writeLine(display, 7,  " Entrada:", formatRate(input),  colors.lightGray, colors.lime)
    writeLine(display, 8,  " Saida:  ", formatRate(output), colors.lightGray, colors.red)
    writeLine(display, 9,  " Fluxo:  ", netStr,             colors.lightGray,
        net >= 0 and colors.lime or colors.orange)
    writeLine(display, 10, " Cap.Max:", formatRate(transferCap), colors.lightGray, colors.cyan)

    drawDivider(display, 11)

    -- Estimativa de tempo
    writeLine(display, 12, " Estimativa:", timeStr, colors.lightGray, colors.yellow)

    -- Rodapé
    display.setCursorPos(1, h)
    display.setTextColor(colors.gray)
    display.write(string.rep(" ", w))
    writeCentered(display, h, "Atualiza a cada " .. REFRESH_RATE .. "s  |  q = sair", colors.gray)

    return energy
end

-- ============================================
--   MAIN
-- ============================================

-- Encontrar Induction Port
local matrix = peripheral.find("inductionPort")
if not matrix then
    error("Nenhum Induction Port encontrado! Conecte o computador ao Induction Port.", 0)
end

-- Encontrar monitor (ou usar terminal)
local display = peripheral.find("monitor") or term
if display ~= term then
    display.setTextScale(0.5)
end

print("Induction Matrix encontrada! Iniciando display...")
os.sleep(0.5)

-- Loop principal
local prevEnergy = nil
local running = true

parallel.waitForAny(
    -- Thread de render
    function()
        while running do
            local ok, err = pcall(function()
                prevEnergy = render(display, matrix, prevEnergy)
            end)
            if not ok then
                display.clear()
                display.setCursorPos(1, 1)
                display.setTextColor(colors.red)
                display.write("Erro: " .. tostring(err))
            end
            os.sleep(REFRESH_RATE)
        end
    end,
    -- Thread de input (sair com Q)
    function()
        while true do
            local _, key = os.pullEvent("key")
            if key == keys.q then
                running = false
                break
            end
        end
    end
)

-- Limpar ao sair
if display ~= term then
    display.clear()
    display.setCursorPos(1,1)
else
    term.clear()
    term.setCursorPos(1,1)
    print("Monitor encerrado.")
end
