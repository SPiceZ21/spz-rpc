-- spz-rpc/server/main.lua
-- Broadcasts race context data to clients so they can build accurate presence.
-- Most data already flows via spz-races events; this only fills gaps.

-- Re-broadcast queue count to newly connected players so their RPC is
-- immediately populated rather than waiting for the next natural update.
RegisterNetEvent("SPZ:requestRpcSync", function()
    local src = source
    if GetResourceState("spz-races") ~= "started" then return end

    local count     = exports["spz-races"]:GetQueueCount()
    local raceState = exports["spz-races"]:GetRaceState()

    TriggerClientEvent("SPZ:queueUpdated", src, {
        count      = count,
        raceState  = raceState,
    })
end)

-- Sync RPC state for any player that joins mid-race
AddEventHandler("SPZ:playerConnected", function(source)
    -- Slight delay to let the client finish loading
    Citizen.SetTimeout(5000, function()
        TriggerClientEvent("SPZ:requestRpcSync", source)
    end)
end)
