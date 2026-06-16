local M = {}

function M.apply(hilbish, lunacolors, bait)
    -- Creiamo una funzione LUA PURA che emula la tua configurazione di Starship!
    -- Niente più binari esterni, tutto eseguito a velocità nativa.
    local function update_prompt()
        local p = {} -- Conterrà i vari pezzi del prompt

        -- 1. Base (NixOS, Utente, Host)
        -- Usiamo %u per l'utente e %h per l'host per lasciare che Hilbish li risolva perfettamente!
        table.insert(p, lunacolors.cyan("  NixOS") .. lunacolors.blue("%u"))
        table.insert(p, lunacolors.magenta(" : ") .. lunacolors.blue("%h"))

        -- 2. Modulo Git (Branch + Repo)
        local f_git = io.popen("git branch --show-current 2>/dev/null")
        if f_git then
            local b = f_git:read("*l")
            f_git:close()
            if b and b ~= "" then
                local repo_name = ""
                local f_repo = io.popen("basename $(git rev-parse --show-toplevel 2>/dev/null)")
                if f_repo then
                    repo_name = f_repo:read("*l") or ""
                    f_repo:close()
                end
                table.insert(p, lunacolors.yellow(" (  " .. b .. " : " .. repo_name .. ")"))
            end
        end

        -- 3. Modulo Fossil (Branch + Repo)
        local cmd_fsl_branch =
        "fossil info 2>/dev/null | awk '/^tags:/ {branch=$2} /^project-name:/ {project=$2} END {if (branch != \"\") {split(branch, a, \",\"); printf \"%s :   %s\", a[1], project}}'"
        local f_fsl = io.popen(cmd_fsl_branch)
        if f_fsl then
            local b = f_fsl:read("*l")
            f_fsl:close()
            if b and b ~= "" then table.insert(p, lunacolors.rgb(255, 135, 0)(" ( " .. b .. ")")) end
        end

        -- 4. Modulo Fossil (Metrics)
        local cmd_fsl_met =
        "fossil changes 2>/dev/null | awk '/^EDITED/ {mod++} /^ADDED/ {add++} /^DELETED|MISSING/ {del++} END {out=\"\"; if(add>0) out=out\" \"add\" \"; if(del>0) out=out\" \"del\" \"; if(mod>0) out=out\" \"mod\" \"; sub(/ $/, \"\", out); if(out!=\"\") print out}'"
        local f_fsl_met = io.popen(cmd_fsl_met)
        if f_fsl_met then
            local met = f_fsl_met:read("*l")
            f_fsl_met:close()
            if met and met ~= "" then table.insert(p, lunacolors.red(" {" .. met .. "}")) end
        end

        -- 5. Nix Shell
        if os.getenv("IN_NIX_SHELL") then
            table.insert(p, lunacolors.cyan(" [ Nix Pure ]"))
        end

        -- 6. Rilevamento Linguaggi (Versione ottimizzata: leggiamo la cartella corrente una sola volta)
        local f_ls = io.popen("ls -1a 2>/dev/null")
        local files = ""
        if f_ls then
            files = f_ls:read("*a")
            f_ls:close()

            if files:match("%.lua\n") or files:match("init%.lua\n") then
                table.insert(p, lunacolors.blue(" [ Lua ]"))
            end
            if files:match("Cargo%.toml\n") or files:match("%.rs\n") then
                table.insert(p, lunacolors.rgb(255, 135, 0)(" [ Rust ]"))
            end
            if files:match("package%.json\n") or files:match("%.js\n") then
                table.insert(p, lunacolors.green(" [ Nodejs ]"))
            end
            if files:match("%.py\n") then
                table.insert(p, lunacolors.magenta(" [ Python ]"))
            end
            if files:match("CMakeLists%.txt\n") or files:match("%.c\n") or files:match("%.cpp\n") then
                table.insert(p, lunacolors.blue(" [ c/cpp ]"))
            end
        end

        -- 7. Directory e Carattere finale
        table.insert(p, lunacolors.magenta(" : "))
        table.insert(p, lunacolors.cyan("%D"))

        -- Seleziona il simbolo corretto in base all'esito del comando precedente
        local char = lunacolors.green("⊢ ")
        if (hilbish.exitCode or 0) ~= 0 then
            char = lunacolors.red("⊬ ")
        end

        -- Uniamo tutto e mandiamo ad Hilbish
        local final_prompt = table.concat(p, "") .. "\n" .. char
        hilbish.prompt(final_prompt)
    end

    -- Genera il primo prompt all'avvio
    update_prompt()

    -- Aggiorna dinamicamente il prompt ad ogni cambio cartella o comando eseguito
    bait.catch('cd', update_prompt)

    bait.catch('command.exit', update_prompt)
end

return M
