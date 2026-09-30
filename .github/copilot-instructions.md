# EmoteRing

EmoteRing is a World of Warcraft Retail addon (pure Lua + WoW XML) that shows a
radial "ping"-style ring for selecting an emote (optionally targeted at
mouseover/target) by holding a key, moving the mouse, and releasing.

## No build/test/lint tooling

There is no compiler, bundler, package manager, linter, or automated test
suite in this repo (no `package.json`, no busted/luacheck config). The addon
is loaded directly by the WoW client per `EmoteRing.toc`. Validation is
manual: load the addon in-game (or a client-less syntax check with `lua -p`
per file) and exercise it via the `/ering` slash commands. The GitLab CI
(`.gitlab-ci.yml`) only runs a REUSE license-compliance check via shared
`ds_2/ci-templates`; there is nothing to run locally for it.

When changing Lua files, at minimum sanity-check syntax, e.g.:
```powershell
lua -p Core.lua Data.lua Ring.lua Minimap.lua Options.lua
```

## File load order & module structure

`EmoteRing.toc` loads files in this fixed order — respect it when adding
globals/functions that another file depends on:
1. `Data.lua` – locale tables (`Addon.L`), the emote `catalog`/`catalogByID`,
   and `Addon.defaults` (default layouts/settings).
2. `Core.lua` – SavedVariables DB init/migration, the secure binding button,
   subject (mouseover/target) capture and emote execution, slash commands,
   and the `ADDON_LOADED`/`PLAYER_LOGIN`/`PLAYER_LOGOUT` event frame.
3. `Ring.lua` – the radial ring UI (icon/label frames, angle math, layout
   dwell-switch zones).
4. `Minimap.lua` – the draggable minimap button.
5. `Options.lua` – the in-game options panel (keybind UI, slot/layout
   editors, emote picker).

All files share one `Addon` table via `local addonName, Addon = ...` (the
addon-private table WoW passes to every file of the same addon) — there are
no `require`/`import` statements; cross-file calls just assume the other
file's functions already exist on `Addon` because of the load order above.

## Key conventions

- **SavedVariables schema**: `EmoteRingDB` holds `schemaVersion`, `layouts`
  (4 layouts × 8 slots referencing catalog IDs), `defaultLayout`, and
  behavior flags. Bump `schemaVersion` and add a migration branch in
  `Addon:InitializeDatabase` (see the `previousSchema < 2` legacy-slot
  migration) instead of silently reinterpreting old saved data.
- **Emote catalog**: curated entries in `Addon.catalog`/`Addon.catalogByID`
  (`Data.lua`) carry `id`, `token` (or `action` for non-emote entries like
  AFK/DND), `label`, `category`, `icon`. Any `EMOTE<n>_TOKEN` global from the
  client not already curated is auto-appended under `CATEGORY_OTHER` — don't
  hardcode the full client emote list.
- **Secure/protected code**: targeting logic that touches combat-protected
  state (changing `target`) is restricted to the `SecureActionButtonTemplate`
  button's `PreClick`/`PostClick` handlers in `Addon:CreateSecureBindingButton`
  (`Core.lua`). Ordinary addon Lua must never call protected target-changing
  API directly — see the comment in `Addon:LockMouseoverSubject`. Follow this
  split when touching targeting/binding code.
- **Secret values**: use the local `IsSecret`/`IsSecret`-style helper
  (`issecretvalue`) before comparing or storing GUID/name values obtained in
  combat, per Blizzard's secret-value API; never assume a value is safe to
  read/store without this check in combat code paths.
- **Localization**: every user-facing string goes through `Addon.L` (`deDE`/
  `enUS` tables in `Data.lua`, selected via `GetLocale()`); add new strings to
  both tables together.
- **Two-space indentation**, LF line endings, UTF-8 (see `.editorconfig`).

## Versioning

Addon version lives in two places that must stay in sync when bumping:
`EmoteRing.toc` (`## Version:`) and `Addon.version` in `Data.lua`. `README.txt`
(German) documents user-facing behavior/commands and should be updated for
behavior changes.
