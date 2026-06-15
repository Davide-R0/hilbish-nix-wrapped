-- Esempio di un modulo Lua situato in una cartella esterna
-- Se questo file viene require-ato, restituirà una funzione utile.

local M = {}

function M.say_hello()
    return "Hello from external lua module!"
end

return M