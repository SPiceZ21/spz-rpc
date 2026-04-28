# spz-rpc
> Discord Rich Presence — live race status · `v1.0.1`

## Scripts

| Side   | File              | Purpose                                               |
| ------ | ----------------- | ----------------------------------------------------- |
| Shared | `config.lua`      | Discord application ID and presence configuration     |
| Client | `client/main.lua` | Rich presence updates, race status polling            |
| Server | `server/main.lua` | Presence data provision, player state queries         |

## Dependencies
- spz-lib
- spz-core

## CI
Built and released via `.github/workflows/release.yml` on push to `main`.
