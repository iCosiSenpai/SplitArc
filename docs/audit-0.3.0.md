# SplitArc 0.3.0 · Audit del backend

Revisione del 9 novembre 2026, a partire da `ebd1c48` (SplitArc 0.2.1). Il perimetro include acquisizione CoreBluetooth, smistamento destra/sinistra, comunicazione tra app e agente, NFC, arresto e interfaccia DriverKit. Per le verifiche precedenti e la procedura di distribuzione rimane disponibile [l’audit iniziale](audit.md).

## Interventi in questa versione

| Riscontro | Intervento e riscontro nel codice |
| --- | --- |
| Il contatore della schermata derivava dal totale di entrambi i Joy-Con. | L’agente invia un contatore indipendente per lato e lo azzera quando quel lato si disconnette. La diagnostica interna conserva il contatore complessivo. [Agente](../SplitArcAgent/main.mm#L906) |
| Una variazione dell’orologio di sistema poteva far scartare aggiornamenti validi. Un carattere di controllo nella descrizione BLE poteva invalidare l’intera riga JSON. | Il limite di frequenza dell’agente e quello dell’app usano il tempo di attività del sistema. L’encoder protegge tutti i caratteri ASCII di controllo. [Agente](../SplitArcAgent/main.mm#L216) · [Ricezione Swift](../SplitArcApp/DaemonBridge.swift#L677) |
| Il nome generico memorizzato da CoreBluetooth poteva nascondere il lato dichiarato nell’annuncio più recente. | L’agente preferisce il lato dichiarato nell’annuncio corrente e ricade sul nome memorizzato. Il fallback per periferiche prive di un lato esplicito rimane da verificare con i controller reali. [Discovery BLE](../SplitArcAgent/BLEManager.mm#L1870) |
| La schermata NFC annunciava una scansione anche dopo un rifiuto locale. L’elenco dei tag non aveva un limite. Il pulsante Apri poteva passare schemi arbitrari al sistema. | Stato in attesa, esito dell’agente, timeout e gestione della disconnessione del destro. Lo storico conserva fino a 128 tag. Solo URL HTTP e HTTPS con un host possono aprirsi dal lettore. Gli altri valori restano copiabili. L’esito positivo dell’agente indica l’avvio della sequenza, mentre la lettura del tag richiede i successivi report fisici. [Agente](../SplitArcAgent/main.mm#L679) · [Stato NFC](../SplitArcApp/DaemonBridge.swift#L1393) · [Apertura URL](../SplitArcApp/NFCView.swift#L300) |
| Ogni messaggio dalla coda di ricezione accodava lavoro sul thread principale, e la console ridisegnava un unico grande testo. | Accumulo sincronizzato e pubblicazione a gruppi, con limiti per record, coda e storico. Event Console usa righe con identità stabile e filtraggio testuale. [Buffer](../SplitArcApp/TelemetryStore.swift) · [Console](../SplitArcApp/SettingsView.swift) |

## Rischi aperti

| Priorità | Riscontro | Verifica o intervento da fare |
| --- | --- | --- |
| Alta | Se la scoperta dei servizi fallisce, l’agente registra l’errore e lascia in vita il contesto BLE. Anche una scoperta incompleta delle caratteristiche può lasciare un lato collegato senza input. Due contesti presenti possono fermare la scansione prima che il flusso sia pronto. [Scoperta BLE](../SplitArcAgent/BLEManager.mm#L2037) | Aggiungere un limite alla fase di inizializzazione. Provare servizio mancante, permesso negato, disconnessione e riconnessione durante il setup. |
| Alta | Il cambio SDL scrive il nuovo stato prima di aver creato tutti i dispositivi virtuali e può rilasciare il gamepad generico prima di un errore successivo. Il percorso non offre rollback. [Cambio modalità](../VirtualJoyConDriver/VirtualJoyConDriver.cpp#L1517) | Rendere atomico il passaggio e collaudare il rollback con un driver provisionato. |
| Media | Telemetria e notifiche di stato condividono una FIFO non bloccante. Con il buffer pieno l’agente può scartare sia un campione sia un evento di controllo. Le scritture parziali recuperano al delimitatore successivo. I comandi, invece, si accumulano su un file per tutta la sessione. [Scrittura eventi](../SplitArcAgent/main.mm#L194) · [Lettura comandi](../SplitArcAgent/main.mm#L713) | Separare i campioni sacrificabili dagli eventi con conferma di consegna e rendere limitato anche il canale dei comandi. |
| Media | La vibrazione usa un report globale letto e scritto in più punti del driver. Il sorgente non rende esplicita la serializzazione tra callback HID e chiamate del client. [Pubblicazione](../VirtualJoyConDriver/VirtualJoyConDriver.cpp#L125) · [Lettura](../VirtualJoyConDriver/VirtualJoyConDriver.cpp#L1495) | Verificare le code reali di DriverKit con vibrazione e più connessioni. Se i callback possono sovrapporsi, isolare lo stato per client e sincronizzare lettura e scrittura. |

## Verifiche

- Xcode su Apple silicon per build e analisi statica. ASan e UBSan sul decoder C++ e 48 test Python sulla matematica dell’input.
- Controllo avvio e arresto della nuova app e del suo agente, firma, ticket e Gatekeeper sull’anteprima.
- Nessuna prova HID su driver provisionato. La notarizzazione dell’anteprima e la telemetria interna non verificano l’output verso un gioco. Restano da verificare riconnessione, vibrazione, avvio della tastiera virtuale e NFC con l’hardware su Tahoe.
- Nella nuova app sono stati verificati Pairing Deck, le scorciatoie da ⌘2 a ⌘6 e il filtro della Event Console. La prova visiva è stata svolta in modalità scura con i controller scollegati.

## Riferimenti di progetto

La nuova interfaccia usa navigazione, scorciatoie e finestre SwiftUI native. Il colore e le illustrazioni sono riservati alle superfici che rappresentano i due controller. [Linee guida Apple per SwiftUI su macOS](https://developer.apple.com/videos/play/wwdc2025/323/) · [View Refactor](https://www.skills.sh/openai/plugins/view-refactor) · [Liquid Glass](https://www.skills.sh/openai/plugins/liquid-glass) · [Frontend Design](https://github.com/anthropics/skills/blob/main/skills/frontend-design/SKILL.md)
