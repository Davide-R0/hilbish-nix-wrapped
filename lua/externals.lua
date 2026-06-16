local M = {}

function M.apply()
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
end

return M
