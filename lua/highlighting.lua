local M = {}

function M.apply(hilbish, lunacolors)
    -- =====================================================================
    -- CUSTOM SYNTAX HIGHLIGHTING
    -- =====================================================================
    function hilbish.highlighter(line)
        local highlighted = line

        -- 1. Evidenzia le stringhe ("..." e '...') in Verde
        highlighted = highlighted:gsub('"[^"]*"', function(match)
            return lunacolors.green(match)
        end)
        highlighted = highlighted:gsub("'[^']*'", function(match)
            return lunacolors.green(match)
        end)

        -- 2. Evidenzia i numeri in Giallo
        highlighted = highlighted:gsub("%f[%w]%d+%f[%W]", function(match)
            return lunacolors.yellow(match)
        end)

        -- 3. Evidenzia i flag (es. --help, -v) in Magenta
        highlighted = highlighted:gsub("%s%-%a+", function(match)
            return lunacolors.magenta(match)
        end)
        highlighted = highlighted:gsub("%s%-%-%a+", function(match)
            return lunacolors.magenta(match)
        end)

        -- 4. Ricerca dinamica del comando (la prima parola della riga)
        -- Catturiamo la prima parola della riga digitata
        local first_word = line:match("^%s*(%S+)")

        if first_word then
            local is_valid = false

            -- Controlla se è un Alias
            if hilbish.aliases and hilbish.aliases[first_word] then
                is_valid = true
                -- Controlla se è un comando built-in o un eseguibile nel $PATH
            elseif hilbish.which(first_word) ~= nil then
                is_valid = true
                -- (Opzionale) Aggiungi qui comandi built-in fissi se hilbish.which non li rileva
            elseif first_word == "cd" or first_word == "exit" then
                is_valid = true
            end

            -- Se il comando è valido, colora la prima parola di Ciano
            -- Se NON è valido (comando inesistente), colorala di Rosso
            local color_func = is_valid and lunacolors.cyan or lunacolors.red

            -- Sostituiamo SOLO la prima occorrenza (il comando) nella stringa finale
            -- Usiamo una regex che matcha l'inizio della riga seguito dalla parola
            highlighted = highlighted:gsub("^(%s*)" .. first_word:gsub("%p", "%%%0"), "%1" .. color_func(first_word), 1)
        end

        -- FIXME: non sembra funzionare bene...
        -- 5. Evidenzia i percorsi (paths) sottolineandoli
        -- Cerca parole che iniziano con /, ./, ../ o ~/ o contengono un / a metà parola
        highlighted = highlighted:gsub("%f[%S]([~%.%/][%w%-_%.%/]+)%f[%s]", function(match)
            return lunacolors.underline(match)
        end)
        highlighted = highlighted:gsub("%f[%S]([%w%-_%.]+/[%w%-_%.%/]*)%f[%s]", function(match)
            return lunacolors.underline(match)
        end)

        return highlighted
    end
end

return M
