# Mitwirken an EmoteRing

Diese Anleitung richtet sich an Contributors, die den Code aus diesem
Repository direkt im laufenden WoW-Client testen möchten, ohne den Ordner
nach jeder Änderung manuell in `Interface\AddOns` zu kopieren.

## Einrichten von GitFlow

Wir nutzen GitFlow, um parallele Änderungen am Code zu machen. Primär das Tool `Git Flow Next`.

Die Einrichtung nach dem Checkout sollte so aussehen:

```powershell
git-flow init --develop=develop --feature=feat/ --bugfix=fix/ --release=release/ --tag="v" --main=midnight
```

Wir nutzen als Hauptentwicklungsbranch _develop_. Hier kommen alle aktiven Änderungen rauf.
Für Releases nutzen wir den _releases_ Zweig.
Finale Releases landen letztlich dadurch auf dem _main_ Zweig.

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

## Multi-TOC: Client-Varianten & WoW Forever (experimentell)

Statt einer einzigen TOC-Datei nutzt EmoteRing Blizzards Multi-TOC-Konvention
(`AddonName_Flavor.toc`), damit ein Client automatisch die zu ihm passende
Datei lädt:

- `EmoteRing.toc` — Fallback, u. a. für Classic Era, da dieser Client keinen
  von Blizzard definierten Flavor-Suffix besitzt bzw. der Suffix nicht
  erkannt wird.
- `EmoteRing_Mainline.toc` — Retail. Der WoW-Forever-Client (1.60.1) meldet
  sich clientseitig ebenfalls als "Mainline" und lädt daher diese Datei
  (durch einen Test mit unterschiedlichen `## Title`-Werten je TOC-Datei
  verifiziert).
- `EmoteRing_TBC.toc` — Burning Crusade Classic
- `EmoteRing_Wrath.toc` — Wrath of the Lich King Classic
- `EmoteRing_Mists.toc` — Mists of Pandaria Classic

Findet der Client keine zu seinem Flavor passende Datei, lädt er stattdessen
`EmoteRing.toc`. Da WoW Forever als "Mainline" erkannt wird, enthält die
`## Interface`-Zeile von `EmoteRing_Mainline.toc` zusätzlich die nicht
offiziell von Blizzard unterstützte Interface-Nummer 16001, damit das Addon
dort nicht als "inkompatibel" markiert wird. Mit
`/run print(select(4, GetBuildInfo()))` lässt sich im jeweiligen Client die
tatsächlich erwartete Interface-Nummer ermitteln.

Da die API von WoW Forever nicht vollständig dokumentiert ist, enthält der
Code an mehreren Stellen defensive Kompatibilitäts-Hilfsfunktionen statt
harter Annahmen über moderne Retail-APIs:

- `Addon:CreateBackdropFrame(...)` statt direktem
  `CreateFrame(..., "BackdropTemplate")` — fällt über `pcall` auf ein
  einfaches `Frame` zurück, falls `BackdropTemplate` auf dem Client nicht
  existiert.
- `Addon:After(delay, callback)` statt `C_Timer.After(...)` — nutzt, falls
  vorhanden, `C_Timer`, sonst einen eigenen `OnUpdate`-Ticker.
- Fallback auf `InterfaceOptions_AddCategory`/`InterfaceOptionsFrame_OpenToCategory`,
  falls die moderne `Settings`-API nicht vorhanden ist.

Diese Kompatibilitäts-Hilfsfunktionen sind bislang nicht am echten
Forever-Client verifiziert, auch wenn die TOC-Zuordnung (Mainline) jetzt
bestätigt ist. Rückmeldungen (inkl. Lua-Fehlern über BugSack/BugGrabber bzw.
`/console scriptErrors 1`) zu diesem Client sind daher weiterhin willkommen.
