local M = {}

function M.apply(hilbish)
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
        ["onlykeycli-tmp-shell"] =
        "NIXPKGS_ALLOW_INSECURE=1 nix shell --impure nixpkgs#onlykey-cli --command onlykey-cli",
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
end

return M
