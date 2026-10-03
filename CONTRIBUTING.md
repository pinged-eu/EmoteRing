# Mitwirken an EmoteRing

Diese Anleitung richtet sich an Contributors, die den Code aus diesem
Repository direkt im laufenden WoW-Client testen möchten, ohne den Ordner
nach jeder Änderung manuell in `Interface\AddOns` zu kopieren.

## Repo-Ordner mit `Interface\AddOns` verlinken (Windows)

Statt den Addon-Ordner zu kopieren, legt man einen symbolischen Link (Symlink)
an, der auf den Repo-Checkout zeigt. Jede Änderung im Repo ist dann sofort im
Client sichtbar (nach `/reload` bzw. Neustart des Clients).

Beispielpfade für dieses Szenario:

- Repo-Checkout: `C:\Devels\EmoteRing`
- WoW-Installation: `C:\BNetGames\WoW\_retail_`

### Variante 1: PowerShell (empfohlen)

PowerShell als **Administrator** öffnen (oder
[Entwicklermodus](#hinweis-entwicklermodus-ohne-admin-rechte) aktivieren,
siehe unten) und folgenden Befehl ausführen, angepasst an die eigenen Pfade:

```powershell
New-Item -ItemType SymbolicLink `
  -Path "C:\BNetGames\WoW\_retail_\Interface\AddOns\EmoteRing" `
  -Target "C:\Devels\EmoteRing"
```

### Variante 2: `cmd.exe` / `mklink`

Alternativ in einer **administrativen** Eingabeaufforderung:

```cmd
mklink /D "C:\BNetGames\WoW\_retail_\Interface\AddOns\EmoteRing" "C:\Devels\EmoteRing"
```

`/D` erzeugt einen Verzeichnis-Symlink (Directory Junction wäre `/J`, falls
Repo und WoW-Installation auf unterschiedlichen Laufwerken liegen und
Symlinks dort Probleme machen — `mklink /J` benötigt keine Admin-Rechte,
funktioniert aber nicht über Netzlaufwerke hinweg).

### Prüfen, ob der Link funktioniert

```powershell
Get-Item "C:\BNetGames\WoW\_retail_\Interface\AddOns\EmoteRing" | Select-Object LinkType, Target
```

`LinkType` sollte `SymbolicLink` (bzw. `Junction`) anzeigen und `Target` auf
den Repo-Pfad verweisen.

### Link wieder entfernen

Einen Symlink-Ordner **nicht** mit `Remove-Item -Recurse` löschen (das würde
die Zieldateien im Repo mit löschen!). Stattdessen:

```powershell
Remove-Item "C:\BNetGames\WoW\_retail_\Interface\AddOns\EmoteRing"
```

bzw. in `cmd.exe`:

```cmd
rmdir "C:\BNetGames\WoW\_retail_\Interface\AddOns\EmoteRing"
```

### Hinweis: Entwicklermodus ohne Admin-Rechte

Ab Windows 10 kann man in den Einstellungen unter
„Update & Sicherheit > Für Entwickler“ den **Entwicklermodus** aktivieren.
Damit erlaubt `mklink`/`New-Item -ItemType SymbolicLink` auch ohne
administrative Eingabeaufforderung das Anlegen symbolischer Links.

## Nach dem Verlinken

1. WoW starten oder `/reload` eingeben, damit der Client den (verlinkten)
   Addon-Ordner neu einliest.
2. Änderungen im Repo-Checkout vornehmen und erneut `/reload` ausführen, um
   sie zu testen.
3. Syntax-Check vor dem Commit (optional, benötigt eine lokale Lua-Installation):

   ```powershell
   lua -p Core.lua Data.lua Ring.lua Minimap.lua Options.lua
   ```

Es gibt in diesem Repo kein Build-/Lint-/Test-Tooling (kein `package.json`,
keine Busted/Luacheck-Konfiguration) — die eigentliche Prüfung erfolgt durch
Laden des Addons im Client und Durchtesten über die `/ering`-Befehle.
