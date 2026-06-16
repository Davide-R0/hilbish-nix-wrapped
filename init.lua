-- Hilbish init.lua

local nixInfo = require('nix-info')

-- Aggiungiamo la nostra directory ./lua al package.path in modo da poter usare require
local lua_dir = nixInfo(nil, "lua_dir")
if lua_dir then
    package.path = package.path .. ";" .. lua_dir .. "/?.lua;" .. lua_dir .. "/?/init.lua"
end

local hilbish = require 'hilbish'
local commander = require 'commander'
local lunacolors = require 'lunacolors'

-- =====================================================================
-- 1. PROMPT E TEMA (STARSHIP)
-- =====================================================================
-- Dal momento che hai una configurazione di Starship estremamente
-- personalizzata, il modo migliore per averla su Hilbish è usare il
-- comando universale di starship. Hilbish adatterà nativamente
-- i colori del tuo terminale!
-- In Hilbish 2.x il prompt prende una stringa formattata.
-- Creiamo una funzione che calcola dinamicamente il branch Git o Fossil
-- e aggiorna la stringa del prompt, in modo da avere le stesse info di Starship!
-- Usiamo il modulo bait per intercettare gli eventi della shell!
local bait = require 'bait'

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
-- 2. SHELL OPTIONS E HISTORY
-- =====================================================================
-- Rimuove i duplicati dalla history
hilbish.opts.history = true
os.execute("export GPG_TTY=$(tty)")

-- =====================================================================
-- 3. ALIASES
-- =====================================================================
local aliases = {
    [".."] = "cd ..",
    ["..."] = "cd ../..",
    ["...."] = "cd ../../..",
    cat = "bat",
    df = "df -h",
    diff = "diff --color=auto",
    du = "du -h",
    eza = "eza --icons auto --git --group-directories-first --header",
    f = "fossil",
    fci = "fossil commit -m",
    fdiff = "fossil diff --command 'nvim -d'",
    fe = "fossil extra",
    fl = "fossil timeline",
    fman = "compgen -c | fzf | xargs man",
    fs = "fossil status",
    ga = "git add",
    gc = "git commit -m",
    gl =
    "git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %s %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)' --all",
    gp = "git push",
    grep = "grep --color=auto",
    gs = "git status -s",
    ip = "ip --color=auto",
    la = "eza -a",
    ll = "eza -al --icons",
    lla = "eza -la",
    ls = "eza -a --icons",
    lt = "eza -a --tree --level=2 --icons",
    mocp = 'mocp -M "' .. os.getenv("HOME") .. '/.system/config/moc"',
    ["n-clean"] = "nix-collect-garbage -d && sudo nix-collect-garbage -d && nix-store --optimize",
    ["n-flake-update"] = "sudo nix flake update",
    ["n-full-update"] =
    "sudo systemctl stop opensnitchd.service && sleep 2 && sudo nix flake update && sleep 2 && sudo nixos-rebuild switch && sleep 2 && sudo systemctl start opensnitchd.service",
    ["n-rebuild"] = "sudo nixos-rebuild switch",
    ["nix-clean"] = "nix-collect-garbage -d && sudo nix-collect-garbage -d && nix-store --optimize",
    nv = "nvim",
    ["nvidia-settings"] = 'nvidia-settings --config="' .. os.getenv("HOME") .. '/.system/config/nvidia/settings"',
    ["onlykeycli-tmp-shell"] = "NIXPKGS_ALLOW_INSECURE=1 nix shell --impure nixpkgs#onlykey-cli --command onlykey-cli",
    ["opensnitch-start"] = "sudo systemctl start opensnitchd.service",
    ["opensnitch-status"] = "systemctl status opensnitchd.service",
    ["opensnitch-stop"] = "sudo systemctl stop opensnitchd.service",
    snv = "sudoedit",
    snvim = "sudoedit",
    vdiff = "nvim -d",
    vi = "nvim",
    vim = "nvim",
    wget = 'wget --hsts-file="' .. os.getenv("HOME") .. '/.system/data/wget-hsts"',
    ["~"] = "cd ~"
}

for k, v in pairs(aliases) do
    hilbish.alias(k, v)
end

-- =====================================================================
-- 4. HYPRLAND HDMI MANAGER (Trasposto in puro LUA!)
-- =====================================================================
local function hdmi_action(action)
    if os.execute("command -v jq >/dev/null 2>&1") ~= 0 then
        print("\27[1;31m[ERROR] 'jq' is not installed.\27[0m")
        return
    end

    local f = io.popen("hyprctl monitors all -j")
    local all_monitors = f:read("*a")
    f:close()

    local f_int = io.popen("echo '" ..
        all_monitors .. "' | jq -r '.[] | select(.name | test(\"^(eDP|LVDS|mipi)\")) | .name' | head -n 1")
    local internal = f_int:read("*l") or ""
    f_int:close()

    local f_ext = io.popen("echo '" ..
        all_monitors .. "' | jq -r '.[] | select(.name | test(\"^(eDP|LVDS|mipi)\") | not) | .name' | head -n 1")
    local external = f_ext:read("*l") or ""
    f_ext:close()

    if internal == "" then
        print("\27[1;31m[ERROR] No internal monitor detected.\27[0m")
        return
    end

    if action == "reset" then
        print("\27[1;34m[INFO] Resetting Hyprland configurations to default...\27[0m")
        os.execute("hyprctl reload >/dev/null")
        print("\27[1;32m[SUCCESS] Done.\27[0m")
        return
    end

    print("\27[1;34m[INFO] Detected Monitors:\27[0m")
    print("  Internal: " .. internal)
    if external ~= "" then
        print("  External: " .. external)
    else
        print("  External: \27[1;33mNONE DETECTED\27[0m")
        print("\27[1;31m[ERROR] Please connect an external monitor.\27[0m")
        return
    end

    local scale = "1"
    if action == "mirror" or action == "only" or action == "extended" or action == "on" then
        io.write("Enter scale value for " .. external .. " [Press Enter for default: 1]: ")
        local user_scale = io.read("*l")
        if user_scale and user_scale ~= "" then scale = user_scale end
    end

    os.execute("hyprctl reload >/dev/null")
    os.execute("sleep 0.5")

    if action == "mirror" then
        os.execute("hyprctl keyword monitor '" ..
            external .. ",preferred,auto," .. scale .. ",mirror," .. internal .. "' >/dev/null")
    elseif action == "only" then
        os.execute("hyprctl keyword monitor '" .. internal .. ",disable' >/dev/null")
        os.execute("sleep 0.5")
        os.execute("hyprctl keyword monitor '" .. external .. ",preferred,auto," .. scale .. "' >/dev/null")
    elseif action == "extended" or action == "on" then
        os.execute("hyprctl keyword monitor '" .. external .. ",preferred,auto," .. scale .. "' >/dev/null")
    elseif action == "off" then
        os.execute("hyprctl keyword monitor '" .. external .. ",disable' >/dev/null")
    end

    print("\27[1;32m[SUCCESS] Configuration applied successfully.\27[0m")
end

commander.register('hdmi-mirror', function() hdmi_action('mirror') end)
commander.register('hdmi-only', function() hdmi_action('only') end)
commander.register('hdmi-extended', function() hdmi_action('extended') end)
commander.register('hdmi-off', function() hdmi_action('off') end)
commander.register('hdmi-on', function() hdmi_action('on') end)
commander.register('hdmi-reset', function() hdmi_action('reset') end)


-- =====================================================================
-- 5. BTRFS SNAPSHOT MANAGER
-- =====================================================================
commander.register('snapshot-show-del', function()
    print("\n\27[1;34m=== Interactive Snapshot Manager ===\27[0m")
    io.write("Which list do you want to view? Type 'h' (Home), 'r' (Root), or any other key to exit: ")
    local target = io.read("*l")
    if target ~= "h" and target ~= "H" and target ~= "r" and target ~= "R" then
        print("\27[0;33mOperation cancelled. Exiting...\27[0m")
        return
    end

    io.write("\nDo you want to calculate Disk Usage? It may take a while. Type 'y' (Yes) or 'n' (No): ")
    local calc_du = io.read("*l")

    print("\n\27[1;34m:: Retrieving information...\27[0m\n")

    local target_name = ""
    if target == "h" or target == "H" then
        target_name = "HOME"
        print("\27[1;36m--- Snapper List (HOME) ---\27[0m")
        os.execute("sudo snapper -c home list")
        print("\n\27[1;36m--- Btrfs Subvolume List (HOME) ---\27[0m")
        os.execute("sudo btrfs subvolume list /home | grep 'path .snapshots'")
        if calc_du == "y" or calc_du == "Y" then
            print("\n\27[1;36m--- Disk Usage (HOME) ---\27[0m")
            os.execute("sudo btrfs filesystem du -s --human-readable /home/.snapshots/* 2>/dev/null")
        else
            print("\n\27[0;33m--- Disk Usage (HOME) Skipped ---\27[0m")
        end
    else
        target_name = "ROOT"
        print("\27[1;36m--- Snapper List (ROOT) ---\27[0m")
        os.execute("sudo snapper -c root list")
        print("\n\27[1;36m--- Btrfs Subvolume List (ROOT) ---\27[0m")
        os.execute("sudo btrfs subvolume list / | grep 'path .snapshots' | grep -v 'home'")
        if calc_du == "y" or calc_du == "Y" then
            print("\n\27[1;36m--- Disk Usage (ROOT) ---\27[0m")
            os.execute("sudo btrfs filesystem du -s --human-readable /.snapshots/* 2>/dev/null")
        else
            print("\n\27[0;33m--- Disk Usage (ROOT) Skipped ---\27[0m")
        end
    end

    io.write("\nDo you want to proceed with deleting snapshots? Type 'yes' to continue (or Enter to exit): ")
    local proceed = io.read("*l")
    if proceed ~= "yes" then
        print("\n\27[0;33mOperation cancelled. Exiting...\27[0m")
        return
    end

    print("\n\27[1;34m:: Snapshot Selection\27[0m")
    print("Enter the numbers to delete. You can enter a single value (e.g., \27[1;33m1\27[0m)")
    print("a space-separated list (e.g., \27[1;33m1 5 23\27[0m), or type '\27[1;31mall\27[0m' for everything.")
    io.write("Numbers to delete: ")
    local snap_list = io.read("*l")

    if not snap_list or snap_list == "" then
        print("\n\27[0;33mNo numbers entered. Operation cancelled.\27[0m")
        return
    end

    if string.lower(snap_list) == "all" then
        local path = (target == "h" or target == "H") and "/home/.snapshots" or "/.snapshots"
        local f = io.popen("sudo ls -1 " .. path .. " 2>/dev/null | grep -E '^[0-9]+$' | tr '\\n' ' '")
        snap_list = f:read("*a")
        f:close()
        if not snap_list or snap_list:match("^%s*$") then
            print("\n\27[0;33mNo snapshots found to delete. Exiting...\27[0m")
            return
        end
    end

    print("\n\27[1;31mWARNING: You are about to permanently delete snapshots [" ..
        snap_list .. "] from the " .. target_name .. " group.\27[0m")
    io.write("Are you sure you want to proceed? Type 'yes' to confirm: ")
    local confirm = io.read("*l")

    if confirm ~= "yes" then
        print("\n\27[0;33mDeletion cancelled by user. Exiting...\27[0m")
        return
    end

    print("\n\27[1;34m:: Starting deletion process...\27[0m")
    local errors = 0
    for num in string.gmatch(snap_list, "%S+") do
        if string.match(num, "^[0-9]+$") then
            local sub_del, rm_del
            if target == "h" or target == "H" then
                sub_del = os.execute("sudo btrfs subvolume delete '/home/.snapshots/" .. num .. "/snapshot' 2>/dev/null")
                rm_del = os.execute("sudo rm -rf '/home/.snapshots/" .. num .. "'")
            else
                sub_del = os.execute("sudo btrfs subvolume delete '/.snapshots/" .. num .. "/snapshot' 2>/dev/null")
                rm_del = os.execute("sudo rm -rf '/.snapshots/" .. num .. "'")
            end
            if sub_del == true or sub_del == 0 then
                print("[\27[1;32mOK\27[0m] Snapshot " .. num .. " successfully deleted.")
            else
                print("[\27[1;31mERROR\27[0m] Failed to delete snapshot " .. num)
                errors = errors + 1
            end
        else
            print("[\27[1;31mERROR\27[0m] Input ignored: '" .. num .. "' is not a valid number.")
            errors = errors + 1
        end
    end

    if errors == 0 then
        print("\n\27[1;32m=== SUCCESS: All selected snapshots were deleted successfully. ===\27[0m")
    else
        print("\n\27[1;31m=== WARNING: The operation completed with some errors. ===\27[0m")
    end
end)

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

-- Options
hilbish.opts.fuzzy = true -- via the menu in Ctrl-R
--hilbish.inputMode.vimMode = "vim" -- non ho capito cosa è questa impostazione
--hilbish.inputMode("vim")

-- Nelle nuove versioni di Hilbish, highlighter prende una stringa col nome del linguaggio
-- (es: "sh") invece di una funzione.
--pcall(function()
--    hilbish.highlighter("sh")
--end)


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

-- this will display "hi" after the cursor in a dimmed color.
--function hilbish.hinter(line, pos)
--    return 'hi'
--end

-- Nota: zoxide per hilbish può essere inizializzato nativamente
-- chiamando: eval "$(zoxide init hilbish)"
-- Hilbish supporta questo tramite hilbish.run se zoxide supporta hilbish,
-- o scrivendo una funzione hook dedicata.
-- Ma per ora, zoxide e fzf vengono integrati tramite plugin Hilbish.

--[[
imagine this is your text input:
user ~ ∆ echo "hey
but there's a missing quote! hilbish will now prompt you so the terminal
will look like:
user ~ ∆ echo "hey
--> ...!"
so then you get
user ~ ∆ echo "hey
--> ...!"
hey ...!
]] --
hilbish.multiprompt '-->'
