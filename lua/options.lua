local M = {}

function M.apply(hilbish)
    -- Options
    hilbish.opts.fuzzy = true -- via the menu in Ctrl-R
    --hilbish.inputMode.vimMode = "vim" -- non ho capito cosa è questa impostazione
    --hilbish.inputMode("vim")
    -- =====================================================================
    -- 2. SHELL OPTIONS E HISTORY
    -- =====================================================================
    -- Rimuove i duplicati dalla history
    hilbish.opts.history = true
    os.execute("export GPG_TTY=$(tty)")

    hilbish.multiprompt '-->'
end

return M
