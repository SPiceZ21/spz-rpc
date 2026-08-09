# spz-rpc

> Discord rich presence · `v1.0.1`

## Overview

`spz-rpc` shows what the player is doing in Discord — idle, free roam, queued, voting, or
racing with their position, class and track. State comes from the core and race engine;
the client refreshes presence on an interval Discord will accept.

## Structure

| Side | File | Purpose |
|---|---|---|
| Shared | `config.lua` | Application ID, branding, asset keys, interval |
| Client | `client/main.lua` | Presence updates and state polling |
| Server | `server/main.lua` | Presence data provision |

## Setup

1. Create an application at <https://discord.com/developers/applications>.
2. Upload images under **Rich Presence → Art Assets**.
3. Put the application ID in `Config.AppId` and match `Config.Assets` keys to your asset
   names.

| Key | Default | Meaning |
|---|---|---|
| `Config.AppId` | — | Discord application ID |
| `Config.ServerName` | `"SPiceZ Racing"` | Text shown in presence |
| `Config.ServerUrl` | `""` | Join button URL (empty disables it) |
| `Config.UpdateIntervalMs` | `15000` | Refresh interval — Discord throttles anything faster |
| `Config.Assets` | see config | Art asset keys per state (`logo`, `freeroam`, `queue`, `polling`, …) |

## Dependencies

`ox_lib` · `spz-core`

---

Part of [SPiceZ-Core](../README.md) · GPL-3.0
