# Audit di SplitArc 0.2.1

9 novembre 2026 · Apple silicon · Xcode 27.2 · macOS 27.2

La revisione ha coperto la build e la distribuzione, i punti d'ingresso DriverKit, il ciclo di vita dell'agente, i canali fra app e agente, il decoder, gli stati dell'interfaccia e la compatibilità dichiarata. La base analizzata è il commit upstream `f5947df`.

## Firma e distribuzione

| Priorità | Riscontro | Stato |
| --- | --- | --- |
| Bloccante | Apple ha accettato il primo archivio con tutti gli entitlement. Gatekeeper lo ha riconosciuto come notarizzato, ma AMFI ha rifiutato l'avvio con «No matching profile found» per host e agente. | La versione con input virtuale richiede i profili Developer ID per host, agente e driver. Lo script di distribuzione li richiede. |
| Alta | Il driver originale accettava connessioni da qualsiasi app locale. Le API del driver accettano report per gamepad, mouse e tastiera. | Rimosso l'accesso universale. Solo l'agente designato richiede accesso allo specifico driver; serve il profilo Apple corrispondente. |
| Alta | Gli script originali potevano dichiarare successo dopo un errore del driver o incorporarne una copia precedente. Il problema si è riprodotto su questo Mac. | Xcode compila e incorpora tutti i target nello stesso grafo di build. Per l'archivio firmato vengono verificati anche presenza, architettura e firma dei componenti. |
| Alta | La firma ricorsiva e la firma ad hoc negli script precedenti non rappresentavano un percorso di distribuzione. | Firma esplicita dall'interno verso l'esterno, Hardened Runtime, timestamp, notarizzazione, ticket incorporato e verifica Gatekeeper. |

### Anteprima firmata

Il pacchetto di anteprima usa Developer ID Application di Alessio Cosi. L'app e l'agente sono firmati senza gli entitlement che richiedono i profili ancora mancanti. L'estensione è inclusa e firmata, mentre l'app rende indisponibile il comando di attivazione. L'anteprima serve per avviare l'interfaccia e il servizio di diagnostica Bluetooth.

## Backend e DriverKit

- **Avvio dell'agente.** Eliminata la ricerca di eseguibili accanto all'app o nella cartella corrente. L'app avvia esclusivamente l'agente incorporato e tiene separati gli stati di avvio, funzionamento e arresto. Il watcher del processo chiude l'agente se l'app termina.
- **Canali locali.** Ogni avvio crea una cartella privata, con permessi 0700, e una FIFO 0600. L'agente scrive senza bloccare il ciclo BLE quando il lettore rallenta. La versione 0.2.1 corregge lo scarto degli aggiornamenti del controller più lunghi di 512 byte, con recupero al successivo delimitatore dopo una scrittura parziale. L'app ricompone le righe prima della decodifica UTF-8. Il lettore dei comandi aspetta la fine della riga e limita i byte letti a ogni passaggio.
- **Riconnessione e input.** La disconnessione azzera pulsanti, stick e grilletto del lato perso e rilascia i pulsanti del puntatore quando quel lato lo controllava. L'agente aggiorna la cache dei report solo dopo una consegna riuscita. L'interfaccia scarta campioni pendenti del lato disconnesso e consente allo stato di progredire alla riconnessione.
- **Superficie del driver.** Rivisti il controllo dei selettori, le dimensioni delle strutture e i limiti delle copie nei descrittori di memoria. Conservati gli identificatori del profilo compatibile con DualSense per evitare regressioni nei client che lo riconoscono per VID/PID.
- **Limiti residui.** In caso di saturazione della FIFO i campioni dell'interfaccia possono essere scartati. Un arresto anomalo può lasciare una piccola cartella di sessione temporanea. La suite di test non sostituisce il collaudo dei report HID e dei gesti con giochi e controller reali.

## Interfaccia e manutenzione

- Navigazione SwiftUI nativa, barra strumenti, menu di stato, finestra diagnostica e nuova icona. L'indicatore distingue la scansione dal numero di controller connessi.
- L'opzione di apertura al login usa il servizio di sistema. Le impostazioni mostrano lo stato del driver e il numero di versione del pacchetto. Sono stati rimossi comandi senza implementazione e l'importazione/esportazione che per lo più li riguardava.
- I tre binari sono solo arm64. App e agente dichiarano macOS 26.0 come minimo. Il driver dichiara DriverKit 25.0. La verifica su questa macchina ha usato macOS 27.2.
- Marchio e identificatori sono di SplitArc. La licenza MIT, i crediti e la cronologia upstream restano disponibili.

## Verifiche e rilascio completo

- Archivio Xcode, Clang Static Analyzer, test C++ del decoder con AddressSanitizer e UndefinedBehaviorSanitizer e 48 test Python sul movimento.
- Controllo della firma dei componenti, verifica del ticket e valutazione Gatekeeper del pacchetto di anteprima.
- Ripetuto il test di avvio e arresto forzato dell’app. Il test controlla che l’agente termini anche quando l’app viene interrotta senza passare dal menu.
- Per il rilascio con input virtuale, richiedere l'autorizzazione Apple, configurare i profili per `dev.icosisenpai.splitarc`, `dev.icosisenpai.splitarc.agent` e `dev.icosisenpai.splitarc.driver`, poi rieseguire lo script di distribuzione. Dopo l'abilitazione del driver, provare su Tahoe con due Joy-Con fisici, riconnessione, vibrazione, mouse, tastiera gestuale e almeno un client SDL. NFC resta sperimentale. [Modulo Apple per gli entitlement](https://developer.apple.com/contact/request/system-extension/)
