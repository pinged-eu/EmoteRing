EmoteRing 0.2.2 – Retail-Testversion
====================================

Installation
------------
1. Den Ordner "EmoteRing" nach
   World of Warcraft\_retail_\Interface\AddOns\
   kopieren.
2. World of Warcraft starten oder /reload eingeben.
3. Escape > Optionen > Addons > EmoteRing öffnen.
4. Eine Taste festlegen.
   Hinweis: Umlaut-/Sondertasten (ü, ö, ä, ß) funktionieren clientbedingt
   nicht zuverlässig als Tastenbelegung. Bitte einen Buchstaben, eine Zahl,
   eine F-Taste oder eine Modifikator-Kombination (z. B. ALT-K) verwenden.

Beim Update von einer älteren Testversion wird die alte Taste beim Login auf
das sichere Mouseover-Binding umgestellt. Falls im Chat eine entsprechende
Meldung erscheint, die Taste danach einfach noch einmal drücken.

Bedienung
---------
- Taste gedrückt halten.
- Maus in Richtung eines Emotes bewegen.
- Taste loslassen, um das hervorgehobene Emote auszuführen.
- In der Ringmitte loslassen, um abzubrechen.
- In einem der vier kleinen Innenkreise kurz verweilen, um für diesen
  geöffneten Ring auf das entsprechende Layout zu wechseln.

Layouts
-------
Vier Layouts mit jeweils acht frei belegbaren Plätzen stehen zur Verfügung.
Das Layout, das beim Öffnen vorne liegt, wird in den Optionen festgelegt.
Die Layout-Namen können geändert und die Plätze mit den Pfeiltasten neu
geordnet werden. Vorhandene Plätze aus Version 0.1.0 werden in Layout 1
übernommen.

Zielauswahl
-----------
Beim Öffnen merkt sich EmoteRing zuerst die Einheit unter der Maus und danach
das aktuelle Ziel. Außerhalb des Kampfes wird ein Mouseover-Ziel vorübergehend
als Ziel gesichert und direkt nach dem Emote auf das vorherige Ziel
zurückgestellt. Im Kampf wird ausschließlich nach einem noch gültigen
Unit-Token für die gespeicherte GUID gesucht.

Emote-Katalog
-------------
Die wichtigsten Emotes besitzen eigene Kategorien, deutsche/englische Namen
und passende Symbole. Zusätzlich liest EmoteRing alle EMOTE<n>_TOKEN-Einträge
des installierten Retail-Clients ein. Dadurch erscheinen auch weitere
Standard-Emotes automatisch in der Kategorie "Weitere". Diese Einträge nutzen
ein neutrales Symbol, da WoW nicht jedem Text-Emote ein eigenes Icon zuordnet.
AFK und "Nicht stören" sind als separate Statusaktionen vorhanden.

Minimap
-------
- Linksklick: Optionen öffnen
- Rechtsklick: Ring-Vorschau
- Ziehen: Position am Rand der Minimap ändern

Die Vorschau wird durch einen zweiten Rechtsklick, einen zweiten Klick auf
"Ring-Vorschau", Escape oder automatisch nach fünf Sekunden geschlossen.

Befehle
-------
/ering          Optionen öffnen
/ering test     Ring fünf Sekunden als Vorschau anzeigen
/ering reset    Einstellungen zurücksetzen

Umfang dieser Version
---------------------
- World of Warcraft Retail, Interface 120100/120105
- Vier Layouts mit jeweils acht frei belegbaren Ringplätzen
- Kategorie-Filter, Suche und Sortierung der Emote-Auswahl
- Deutsches und englisches Interface
- Mouseover-/Target-Erfassung
- Minimap-Button
- AFK und "Nicht stören" als auswählbare Statusaktionen
- Responsiver Optionsinhalt mit einem immer vollständig sichtbaren Außenrahmen

Testhinweis
-----------
Diese Version wurde außerhalb des laufenden WoW-Clients syntaktisch und als
AddOn-Paket geprüft. Bitte nach dem Update einmal /reload verwenden und vor
allem Mouseover, Layoutwechsel und die gewünschte UI-Skalierung im
Retail-Client testen.
