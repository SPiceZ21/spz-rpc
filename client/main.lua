-- spz-rpc/client/main.lua
-- Discord Rich Presence — live racing status displayed in Discord.
--
-- Presence states and what Discord shows:
--
--   IDLE / MENU     →  "In menus"
--   FREEROAM        →  "Freeroam — Los Santos"  [class badge]
--   QUEUED          →  "Queued — Class B · 4 racers waiting"
--   POLLING         →  "Voting · Track & Class poll"
--   STAGING         →  "Staging — Maze Bank Circuit · Class B"
--   COUNTDOWN       →  "Ready · Maze Bank Circuit — 8 racers"
--   LIVE (racing)   →  "P2/8 · Lap 3/5 · Maze Bank Circuit"  elapsed timer
--   ENDED           →  "Finished P2 · Maze Bank Circuit"
--   SPECTATING      →  "Spectating"
--   DNF             →  "DNF · Maze Bank Circuit"

-- ── State Tracking ─────────────────────────────────────────────────────────

local RPC = {
    playerState = "IDLE",   -- SPZ.State value
    raceState   = "IDLE",   -- SPZ.RaceState value

    -- Race context (populated from server events)
    track       = nil,      -- string: track display name
    trackType   = nil,      -- "circuit" | "sprint"
    classId     = nil,      -- 0–3
    totalLaps   = nil,      -- number
    totalRacers = nil,      -- number
    currentLap  = 1,
    position    = nil,      -- number | "DNF"
    raceStartMs = nil,      -- GetGameTimer() at race start (for elapsed display)
    isDNF       = false,

    -- Queue context
    queueCount  = 0,

    -- Player context
    licenseClass = nil,     -- 0–3, from identity state bag
}

-- ── Helpers ─────────────────────────────────────────────────────────────────

local function ordinal(n)
    if type(n) ~= "number" then return tostring(n) end
    local suf = Config.OrdinalSuffix[n] or "th"
    return n .. suf
end

local function classLabel(id)
    return Config.ClassLabel[id] or "Class ?"
end

local function classAsset(id)
    return Config.ClassAsset[id] or Config.Assets.logo
end

local function elapsedLabel()
    if not RPC.raceStartMs then return "" end
    local ms  = GetGameTimer() - RPC.raceStartMs
    local s   = math.floor(ms / 1000)
    local m   = math.floor(s / 60)
    s = s % 60
    return string.format("%d:%02d elapsed", m, s)
end

-- ── Core Apply Function ──────────────────────────────────────────────────────
-- All presence writes go through here so there is exactly one place to change.

local function Apply(large, largeText, small, smallText, statusLine, detailLine)
    SetDiscordAppId(Config.AppId)

    SetDiscordRichPresenceAsset(large or Config.Assets.logo)
    SetDiscordRichPresenceAssetText(largeText or Config.ServerName)

    if small and small ~= "" then
        SetDiscordRichPresenceAssetSmallImage(small)
        SetDiscordRichPresenceAssetSmallText(smallText or "")
    else
        SetDiscordRichPresenceAssetSmallImage("")
        SetDiscordRichPresenceAssetSmallText("")
    end

    -- FiveM maps SetRichPresence → Discord "state" (lower line)
    -- and the second parameter of some builds → "details" (upper line).
    -- Use SetRichPresence for the most important line.
    SetRichPresence(statusLine or "")

    -- Buttons: Join button if server URL configured
    if Config.ServerUrl and Config.ServerUrl ~= "" then
        SetDiscordRichPresenceAction(0, "Join Server", Config.ServerUrl)
    end
end

-- ── Presence Builders ────────────────────────────────────────────────────────

local function ShowIdle()
    Apply(
        Config.Assets.logo,
        Config.ServerName,
        nil, nil,
        "In menus"
    )
end

local function ShowFreeroam()
    local small     = RPC.licenseClass and classAsset(RPC.licenseClass)
    local smallText = RPC.licenseClass and classLabel(RPC.licenseClass)
    Apply(
        Config.Assets.freeroam,
        "Freeroam",
        small, smallText,
        "Cruising around Los Santos"
    )
end

local function ShowQueued()
    local cls   = RPC.classId and classLabel(RPC.classId) or "Any Class"
    local count = RPC.queueCount > 0 and (RPC.queueCount .. " waiting") or "waiting"
    Apply(
        Config.Assets.queue,
        "In Queue",
        RPC.classId and classAsset(RPC.classId), cls,
        string.format("Queued · %s · %s", cls, count)
    )
end

local function ShowPolling()
    Apply(
        Config.Assets.polling,
        "Track & Class Poll",
        nil, nil,
        "Voting — choosing next track and class"
    )
end

local function ShowStaging()
    local track  = RPC.track or "Unknown Track"
    local cls    = RPC.classId and classLabel(RPC.classId) or ""
    local racers = RPC.totalRacers and (RPC.totalRacers .. " racers") or ""
    Apply(
        Config.Assets.staging,
        track,
        RPC.classId and classAsset(RPC.classId),
        cls,
        string.format("Staging · %s%s", track, cls ~= "" and (" · " .. cls) or "")
    )
end

local function ShowCountdown()
    local track  = RPC.track or "Unknown Track"
    local cls    = RPC.classId and classLabel(RPC.classId) or ""
    Apply(
        Config.Assets.staging,
        track,
        RPC.classId and classAsset(RPC.classId),
        cls,
        string.format("Ready · %s — %s racers", track, tostring(RPC.totalRacers or "?"))
    )
end

local function ShowLive()
    local track  = RPC.track or "Unknown Track"
    local pos    = RPC.position and ordinal(RPC.position) or "?"
    local total  = RPC.totalRacers and ("/" .. RPC.totalRacers) or ""
    local lap    = RPC.currentLap or 1
    local laps   = RPC.totalLaps  or "?"
    local cls    = RPC.classId and classLabel(RPC.classId) or ""

    local lapStr
    if RPC.trackType == "circuit" then
        lapStr = string.format("Lap %d/%s", lap, tostring(laps))
    else
        lapStr = "Sprint"
    end

    Apply(
        Config.Assets.racing,
        string.format("%s · %s", track, cls),
        RPC.classId and classAsset(RPC.classId),
        cls,
        string.format("P%s%s · %s · %s", pos, total, lapStr, track)
    )
end

local function ShowEnded()
    local track = RPC.track or "Unknown Track"
    local pos

    if RPC.isDNF then
        pos = "DNF"
        Apply(
            Config.Assets.results,
            track,
            Config.Assets.badge_dnf, "DNF",
            string.format("DNF · %s", track)
        )
    else
        pos = RPC.position and ordinal(RPC.position) or "?"
        Apply(
            Config.Assets.results,
            track,
            RPC.classId and classAsset(RPC.classId),
            RPC.classId and classLabel(RPC.classId),
            string.format("Finished %s · %s", pos, track)
        )
    end
end

local function ShowSpectating()
    local track = RPC.track
    Apply(
        Config.Assets.spectate,
        "Spectating",
        nil, nil,
        track and ("Spectating · " .. track) or "Spectating"
    )
end

-- ── Dispatch ─────────────────────────────────────────────────────────────────

local function Refresh()
    local ps = RPC.playerState
    local rs = RPC.raceState

    if ps == "SPECTATING" then
        ShowSpectating()
    elseif ps == "RACING" then
        if rs == "WAITING"   then ShowStaging()
        elseif rs == "COUNTDOWN" then ShowCountdown()
        elseif rs == "LIVE"  then ShowLive()
        elseif rs == "ENDED" then ShowEnded()
        else                      ShowStaging()
        end
    elseif ps == "QUEUED" then
        if rs == "POLLING" then ShowPolling()
        else               ShowQueued()
        end
    elseif ps == "FREEROAM" then
        ShowFreeroam()
    else
        ShowIdle()
    end
end

-- ── Event Listeners ──────────────────────────────────────────────────────────

-- Player state (IDLE → FREEROAM → QUEUED → RACING → SPECTATING)
RegisterNetEvent(SPZ.Events.STATE_CHANGED, function(_, newState)
    RPC.playerState = newState
    if newState ~= "RACING" then
        -- Clear race context when leaving a race
        RPC.isDNF       = false
        RPC.raceStartMs = nil
        RPC.position    = nil
    end
    Refresh()
end)

-- Race phase (IDLE → POLLING → WAITING → COUNTDOWN → LIVE → ENDED → CLEANUP)
RegisterNetEvent("spz_race:state_updated", function(state)
    RPC.raceState = state
    if state == "LIVE" and not RPC.raceStartMs then
        RPC.raceStartMs = GetGameTimer()
    end
    if state == "IDLE" or state == "CLEANUP" then
        RPC.track       = nil
        RPC.totalLaps   = nil
        RPC.totalRacers = nil
        RPC.currentLap  = 1
        RPC.position    = nil
        RPC.isDNF       = false
        RPC.raceStartMs = nil
    end
    Refresh()
end)

-- Staging / countdown data — gives us track, class, laps, total racers
local function OnRaceSetup(data)
    if not data then return end
    RPC.track       = data.track
    RPC.classId     = data.class
    RPC.totalLaps   = data.laps
    RPC.totalRacers = data.total
    Refresh()
end

RegisterNetEvent("SPZ:stagingPhase", OnRaceSetup)
RegisterNetEvent("SPZ:countdown",    OnRaceSetup)

-- GO — record start time for elapsed display
RegisterNetEvent("SPZ:go", function()
    RPC.raceStartMs = GetGameTimer()
    RPC.raceState   = "LIVE"
    Refresh()
end)

-- Live position updates — extract our own position from the leaderboard
RegisterNetEvent("SPZ:positionUpdate", function(payload)
    if not payload then return end
    local mySource = GetPlayerServerId(PlayerId())
    for _, entry in ipairs(payload) do
        if entry.source == mySource then
            RPC.position   = entry.position
            RPC.currentLap = entry.lap or RPC.currentLap
            return  -- found — no need to refresh here; periodic loop handles it
        end
    end
end)

-- Lap complete
RegisterNetEvent("SPZ:lapComplete", function(lapNum)
    RPC.currentLap = lapNum + 1
end)

-- Player finished
RegisterNetEvent("SPZ:raceFinished", function()
    RPC.isDNF = false
    Refresh()
end)

-- DNF
RegisterNetEvent("SPZ:dnf", function()
    RPC.isDNF = true
    Refresh()
end)

-- Race ended (full results)
RegisterNetEvent(SPZ.Events.RACE_END, function(results)
    RPC.raceState = "ENDED"
    -- Confirm final position from results
    if results and results.finishers then
        local mySource = GetPlayerServerId(PlayerId())
        for _, f in ipairs(results.finishers) do
            if f.source == mySource then
                RPC.position = f.position
                break
            end
        end
    end
    Refresh()
end)

-- Queue size updates from spz-races server
RegisterNetEvent("SPZ:queueUpdated", function(data)
    if data then
        RPC.queueCount = data.count  or 0
        RPC.classId    = data.class  or RPC.classId
    end
    Refresh()
end)

-- Grab license class from identity state bag (set by spz-identity on load)
CreateThread(function()
    -- Wait a couple seconds for identity to sync
    Wait(3000)
    local licClass = LocalPlayer.state["spz:licenseClass"]
    if licClass then RPC.licenseClass = licClass end
    Refresh()
end)

AddStateBagChangeHandler("spz:licenseClass", "localPlayer", function(_, _, value)
    RPC.licenseClass = value
    Refresh()
end)

-- ── Periodic Refresh ─────────────────────────────────────────────────────────
-- Discord silently drops updates faster than ~15 s, so we loop at the config
-- interval.  For LIVE races this keeps the elapsed lap/position current.

CreateThread(function()
    -- Initial presence — set immediately on resource start
    SetDiscordAppId(Config.AppId)
    Wait(2000)
    Refresh()

    while true do
        Wait(Config.UpdateIntervalMs or 15000)
        Refresh()
    end
end)
