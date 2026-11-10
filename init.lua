local nixInfo = require('nix-info')

local lua_dir = nixInfo(nil, "lua_dir")
if lua_dir then
    package.path = package.path .. ";" .. lua_dir .. "/?.lua;" .. lua_dir .. "/?/init.lua"
end

local hilbish = require('hilbish')
local commander = require('commander')
local lunacolors = require('lunacolors')
local bait = require('bait')

require('options').apply(hilbish)
require('prompt_style').apply(hilbish, lunacolors, bait)
require('aliases').apply(hilbish)
require('highlighting').apply(hilbish, lunacolors)
require('integrations').apply(commander)
require('commands').apply(commander, lunacolors)
require('externals').apply()

-- WARN: questo modulo deve essere necessatriamente importato dopo il modulo degli alias!!
--require('autocompletions').apply()

-- Motore di Completamento Standard (Bridge Fish)
local fish_completer = function(query, ctx, fields)
    -- Escape POSIX standard per prevenire esecuzioni arbitrarie
    local safe_ctx = ctx:gsub("'", "'\\''")
    -- Invocazione sincrona e diretta del motore complete di Fish
    local cmd = string.format("fish -c 'complete -C'\\''%s'\\''' 2>/dev/null", safe_ctx)
    local res = io.popen(cmd)
    if not res then return {} end
    local raw_str = res:read('*all')
    res:close()
    local values = {}
    -- Parsing vettoriale dell'output
    for v in string.gmatch(raw_str, "[^\r\n]+") do
        -- Rimozione sequenze di escape ANSI residue
        v = v:gsub('\27%[%d+;%d*;%d*m', ''):gsub('\27%[%d+m', '')
        -- Isolamento del token di autocompletamento primario
        local comp = v:match("^([^\t]+)")
        if comp then
            table.insert(values, comp)
        end
    end
    -- Fase di intersezione per il matching della query corrente
    if query ~= "" then
        for i = #values, 1, -1 do
            if not values[i]:find(query, 1, true) then
                table.remove(values, i)
            end
        end
    end

    return {
        { items = values, type = "grid" }
    }
end

-- Injector universale (AOT Scanning)
local function inject_global_completions()
    local path_env = os.getenv("PATH")
    if not path_env then return end
    local registered = {}
    -- Iterazione sulle directory di sistema per mappare tutti i binari disponibili
    for path in string.gmatch(path_env, "[^:]+") do
        local p = io.popen('ls -1 "' .. path .. '" 2>/dev/null')
        if p then
            for bin in p:lines() do
                if not registered[bin] then
                    hilbish.complete('command.' .. bin, fish_completer)
                    registered[bin] = true
                end
            end
            p:close()
        end
    end
end

-- Esecuzione al caricamento della shell
inject_global_completions() -- Assegnazione del bridge ai comandi specifici
--hilbish.complete('command.git', fish_completer)
--hilbish.complete('command.nix', fish_completer)
--hilbish.complete('command.systemctl', fish_completer)
--
hilbish.complete('command.nix', function(query, ctx, fields)
    -- Se #fields == 2, l'utente sta digitando il primo parametro (il sottocomando)
    if #fields == 2 then
        local subcommands = { "build", "develop", "flake", "profile", "run", "search", "shell" }
        local matches = {}

        for _, sub in ipairs(subcommands) do
            -- Filtra i sottocomandi in base alla query attuale
            if string.sub(sub, 1, #query) == query then
                table.insert(matches, sub)
            end
        end

        return {
            {
                items = matches,
                type = "grid"
            }
        }
    end

    -- Gestione gerarchica ulteriore (es. #fields > 2 per i parametri di 'nix develop')
    return {}
end)
