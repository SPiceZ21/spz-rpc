-- spz-rpc/client/main.lua
-- Revamped Discord Rich Presence for live race status, position, class, queue, and freeroam.

local Config = _G.Config or {}
local queueJoinTime = nil
local lastInQueue = false

Citizen.CreateThread(function()
    print("^3[spz-rpc] Starting Dynamic Discord Rich Presence...^7")

    -- Initial application registration
    SetDiscordAppId(Config.AppId or "YOUR_DISCORD_APP_ID")

    -- Setup static join action button if url is provided
    if Config.ServerUrl and Config.ServerUrl ~= "" then
        SetDiscordRichPresenceAction(0, "Join Server", Config.ServerUrl)
    end

    local function UpdatePresence()
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        local inRace = LocalPlayer.state.inRace
        local inQueue = LocalPlayer.state.inQueue
        local raceState = GlobalState.raceState or "IDLE"

        -- Track queue join time to show elapsed time waiting
        if inQueue and not lastInQueue then
            queueJoinTime = os.time()
        elseif not inQueue then
            queueJoinTime = nil
        end
        lastInQueue = inQueue

        local largeAsset = Config.Assets.logo or "spz_logo"
        local largeText = Config.ServerName or "SPiceZ Racing"
        local smallAsset = nil
        local smallText = nil
        local details = "Cruising"
        local state = "In Los Santos"
        local hasTimer = false
        local customStartTime = 0

        if inRace and raceState == "LIVE" then
            largeAsset = Config.Assets.racing or "spz_racing"
            largeText = "Living on the limit"

            local raceClass = LocalPlayer.state.raceClass
            smallAsset = Config.ClassAsset[raceClass] or Config.Assets.class_c
            smallText = Config.ClassLabel[raceClass] or "Active Racer"

            local trackName = LocalPlayer.state.raceTrack or "Unknown Track"
            details = "Racing on " .. trackName

            local isDnf = LocalPlayer.state.dnf
            if isDnf then
                state = "Did Not Finish (DNF)"
                smallAsset = Config.Assets.badge_dnf or "spz_dnf"
                smallText = "DNF"
            else
                local pos = LocalPlayer.state.racePosition or 0
                local ordinal = "1st"
                if pos > 0 then
                    local suffix = "th"
                    if pos >= 1 and pos <= 3 then
                        suffix = Config.OrdinalSuffix[pos] or "th"
                    end
                    ordinal = tostring(pos) .. suffix
                else
                    ordinal = "Loading..."
                end

                local currentLap = LocalPlayer.state.raceLap or 1
                local totalLaps = LocalPlayer.state.raceLaps or 1
                state = string.format("Pos: %s | Lap: %d/%d", ordinal, currentLap, totalLaps)

                local raceTime = LocalPlayer.state.raceTime
                if raceTime and raceTime > 0 then
                    hasTimer = true
                    customStartTime = os.time() - math.floor((GetGameTimer() - raceTime) / 1000)
                end
            end

        elseif inRace and (raceState == "WAITING" or raceState == "COUNTDOWN") then
            largeAsset = Config.Assets.staging or "spz_staging"
            largeText = "Lined up on grid"

            local raceClass = LocalPlayer.state.raceClass
            smallAsset = Config.ClassAsset[raceClass] or Config.Assets.class_c
            smallText = Config.ClassLabel[raceClass] or "Active Racer"

            local trackName = LocalPlayer.state.raceTrack or "Unknown Track"
            details = "Grid Setup | " .. trackName

            local pos = LocalPlayer.state.racePosition or 0
            state = string.format("Class: %s | Grid #%d", smallText, pos)

        elseif raceState == "POLLING" then
            largeAsset = Config.Assets.polling or "spz_polling"
            largeText = "Casting votes"
            smallAsset = Config.Assets.logo or "spz_logo"
            smallText = Config.ServerName or "SPiceZ Racing"

            details = "Voting for Next Race"
            state = "Deciding track & class..."

        elseif inQueue then
            largeAsset = Config.Assets.queue or "spz_queue"
            largeText = "Ready to race"
            smallAsset = Config.Assets.logo or "spz_logo"
            smallText = Config.ServerName or "SPiceZ Racing"

            details = "Waiting in Queue"
            local queuePos = LocalPlayer.state.queuePosition or 1
            local queueTotal = GlobalState.queueCount or 1
            state = string.format("Queue Position: #%d/%d", queuePos, queueTotal)

            if queueJoinTime and queueJoinTime > 0 then
                hasTimer = true
                customStartTime = queueJoinTime
            end

        else
            -- Freeroam / cruising
            largeAsset = Config.Assets.freeroam or "spz_freeroam"
            largeText = "Free Roam"
            smallAsset = Config.Assets.logo or "spz_logo"
            smallText = Config.ServerName or "SPiceZ Racing"

            if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
                local hash = GetEntityModel(veh)
                local modelName = GetDisplayNameFromVehicleModel(hash)
                local vehicleLabel = GetLabelText(modelName)
                if vehicleLabel == "CARNOTFOUND" then vehicleLabel = modelName end
                details = "Cruising in " .. vehicleLabel
            else
                details = "On Foot in Los Santos"
            end

            local profile = nil
            pcall(function()
                profile = exports["spz-identity"]:GetClientProfile()
            end)

            if profile then
                largeText = "SR: " .. tostring(profile.sr or 0.0) .. " | Level " .. tostring(profile.level or 1)
                state = "Rank: " .. tostring(profile.rank or "C-1") .. " (iR: " .. tostring(profile.iRating or 1000) .. ")"
            else
                state = "Cruising the streets"
            end
        end

        SetDiscordRichPresenceAsset(largeAsset)
        SetDiscordRichPresenceAssetText(largeText)

        if smallAsset then
            SetDiscordRichPresenceAssetSmall(smallAsset)
            SetDiscordRichPresenceAssetSmallText(smallText or "")
        else
            SetDiscordRichPresenceAssetSmall("")
            SetDiscordRichPresenceAssetSmallText("")
        end

        SetRichPresence(details .. " - " .. state)

        if hasTimer and customStartTime > 0 then
            SetDiscordRichPresenceStartTime(customStartTime)
        else
            SetDiscordRichPresenceStartTime(0)
        end
    end

    -- Server sync event handler
    RegisterNetEvent("SPZ:rpcSync", function()
        UpdatePresence()
    end)

    -- Real-time state bag triggers for responsive status transitions
    AddStateBagChangeHandler("raceState", "global", function()
        UpdatePresence()
    end)

    AddStateBagChangeHandler("inRace", nil, function(bagName)
        local id = tonumber(bagName:match("player:(%d+)"))
        if id == GetPlayerServerId(PlayerId()) then
            UpdatePresence()
        end
    end)

    AddStateBagChangeHandler("inQueue", nil, function(bagName)
        local id = tonumber(bagName:match("player:(%d+)"))
        if id == GetPlayerServerId(PlayerId()) then
            UpdatePresence()
        end
    end)

    -- Periodic refresh loop matching standard Discord update throttling
    while true do
        UpdatePresence()
        Citizen.Wait(Config.UpdateIntervalMs or 15000)
    end
end)
