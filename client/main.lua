-- spz-rpc/client/main.lua
-- Simplified Discord Rich Presence.

local SPZ = nil
local Config = _G.Config or {}

Citizen.CreateThread(function()
    print("^3[spz-rpc] Starting Simplified Discord Rich Presence...^7")
    while not SPZ do
        pcall(function()
            SPZ = exports["spz-lib"]:GetCoreObject()
        end)
        if not SPZ then Citizen.Wait(1000) end
    end

    local function ApplySimple(status)
        SetDiscordAppId(Config.AppId or "YOUR_DISCORD_APP_ID")
        SetDiscordRichPresenceAsset(Config.Assets and Config.Assets.logo or "spz_logo")
        SetDiscordRichPresenceAssetText(Config.ServerName or "SPiceZ Racing")
        SetRichPresence(status or "In Los Santos")
        
        if Config.ServerUrl and Config.ServerUrl ~= "" then
            SetDiscordRichPresenceAction(0, "Join Server", Config.ServerUrl)
        end
    end

    -- Event listener for state changes
    RegisterNetEvent("SPZ:stateChanged", function(_, newState)
        local status = "Cruising"
        if newState == "RACING" then status = "Racing"
        elseif newState == "QUEUED" then status = "In Queue"
        elseif newState == "SPECTATING" then status = "Spectating"
        end
        ApplySimple(status)
    end)

    -- Initial presence
    ApplySimple("In Los Santos")

    -- Periodic refresh
    while true do
        Wait(30000)
        ApplySimple()
    end
end)
