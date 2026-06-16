local M = {}

function M.apply(commander)
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
                    sub_del = os.execute("sudo btrfs subvolume delete '/home/.snapshots/" ..
                    num .. "/snapshot' 2>/dev/null")
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
end

return M
