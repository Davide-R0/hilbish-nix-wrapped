local M = {}

function M.apply(commander)
    -- ---------------------------------
    -- Autocompletamento con carpace
    -- ---------------------------------
    -- Inizializzazione del bridge dinamico per Carapace
    -- Il comando '_carapace hilbish' istruisce il binario a stampare l'interprete di completamento in sintassi Lua
    --local carapace_process = io.popen("carapace _carapace hilbish")

    --if carapace_process then
    --    -- Estrazione del buffer di output (codice sorgente) nel thread principale
    --    local carapace_source = carapace_process:read("*a")
    --    carapace_process:close()

    --    -- Valutazione e compilazione a runtime (JIT) del codice generato, se presente
    --    if carapace_source and carapace_source ~= "" then
    --        local success, err = pcall(load(carapace_source))
    --        if not success then
    --            print("Errore critico durante la compilazione del modulo Carapace: " .. tostring(err))
    --        end
    --    end
    --end
    -- =====================================================================
    -- ZOXIDE INTEGRATION
    -- =====================================================================
    -- Zoxide genera codice Lua nativo per Hilbish. Lo leggiamo e lo eseguiamo.
    local f_zox = io.popen("zoxide init hilbish --cmd cd 2>/dev/null") -- in automatico crea l'alias per cd e cdi
    if f_zox then
        local zoxide_code = f_zox:read("*a")
        f_zox:close()
        if zoxide_code and zoxide_code ~= "" then
            local chunk, err = load(zoxide_code)
            if chunk then
                chunk()
            else
                print("Errore nel caricamento di zoxide: " .. tostring(err))
            end
        end
    end


    -- =====================================================================
    -- 6. YAZI E ZOXIDE WRAPPERS
    -- =====================================================================
    commander.register('y', function(args)
        local tmp = os.tmpname()
        local cmd = "yazi"
        if #args > 0 then
            cmd = cmd .. " " .. table.concat(args, " ")
        end
        cmd = cmd .. " --cwd-file=" .. tmp
        os.execute(cmd)

        local f = io.open(tmp, "r")
        if f then
            local cwd = f:read("*a")
            f:close()
            os.remove(tmp)
            if cwd and cwd ~= "" then
                cwd = cwd:gsub("%s+$", "")
                hilbish.run("cd " .. cwd)
            end
        end
    end)
end

return M
