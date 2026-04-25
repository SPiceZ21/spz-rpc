Config = {}

-- ── Discord Application ──────────────────────────────────────────────────────
-- Create your app at https://discord.com/developers/applications
-- Upload art assets to the "Rich Presence > Art Assets" tab there.
-- Paste your Application ID below.
Config.AppId = "YOUR_DISCORD_APP_ID"

-- ── Server Branding ──────────────────────────────────────────────────────────
Config.ServerName = "SPiceZ Racing"
Config.ServerUrl  = ""   -- optional: shown in the Join button (leave "" to disable)

-- ── Update Interval ─────────────────────────────────────────────────────────
-- Discord silently throttles updates faster than ~15 seconds.
-- During an active race the RPC refreshes at this interval.
Config.UpdateIntervalMs = 15000

-- ── Discord Art Asset Keys ────────────────────────────────────────────────────
-- These must match the asset name you uploaded in your Discord app's Art Assets panel.
Config.Assets = {
    -- Large images (main visual)
    logo       = "spz_logo",       -- default / idle / menu
    freeroam   = "spz_freeroam",   -- cruising in freeroam
    queue      = "spz_queue",      -- waiting in queue
    polling    = "spz_polling",    -- voting on track / class
    staging    = "spz_staging",    -- on the grid before lights
    racing     = "spz_racing",     -- live race
    results    = "spz_results",    -- post-race results screen
    spectate   = "spz_spectate",   -- spectating

    -- Small images (overlay badge — shown bottom-right of large image)
    class_c    = "spz_class_c",    -- Class C — Street
    class_b    = "spz_class_b",    -- Class B — Sport
    class_a    = "spz_class_a",    -- Class A — Pro
    class_s    = "spz_class_s",    -- Class S — Elite
    badge_dnf  = "spz_dnf",        -- shown when player DNF'd
}

-- ── Class Display Names ───────────────────────────────────────────────────────
Config.ClassLabel = {
    [0] = "Class C",
    [1] = "Class B",
    [2] = "Class A",
    [3] = "Class S",
}

Config.ClassAsset = {
    [0] = "spz_class_c",
    [1] = "spz_class_b",
    [2] = "spz_class_a",
    [3] = "spz_class_s",
}

-- ── Ordinal Suffixes ─────────────────────────────────────────────────────────
Config.OrdinalSuffix = { "st", "nd", "rd" }
