# SplitArc · Autorizzazione e collaudo DriverKit

## Richiesta da parte dell’Account Holder

Accedi al team **6KV8L8WQ9D** e apri il modulo Apple. Il progetto usa un driver in spazio utente basato su `IOUserHIDDevice` e sulla classe di supporto `AppleUserHIDDevice`. Il driver non comunica direttamente con hardware USB. La connessione fisica passa dall’agente CoreBluetooth. [Modulo Apple](https://developer.apple.com/contact/request/system-extension/) · [Riferimento IOUserHIDDevice](https://developer.apple.com/documentation/hiddriverkit/iouserhiddevice)

| Identificatore esplicito | Autorizzazione da configurare |
| --- | --- |
| `dev.icosisenpai.splitarc` | System Extension |
| `dev.icosisenpai.splitarc.agent` | DriverKit UserClient Access per `dev.icosisenpai.splitarc.driver` |
| `dev.icosisenpai.splitarc.driver` | DriverKit e DriverKit Family HID Device |

Chiedi la distribuzione macOS esterna al Mac App Store con **Developer ID**. Una volta approvate le autorizzazioni, genera un profilo **Developer ID** per ciascuno dei tre identificatori, selezionando il certificato Developer ID Application del team. Scarica i tre file `.provisionprofile` nella stessa cartella, oppure importali in Xcode. [Apple · Capability Requests](https://developer.apple.com/help/account/capabilities/capability-requests)

### Descrizione da incollare nel modulo

> SplitArc is an open-source macOS app for Apple silicon Macs running macOS Tahoe or later. Its bundled CoreBluetooth agent connects to left and right Nintendo Switch 2 Joy-Con controllers and combines their input. A user-space DriverKit extension using IOUserHIDDevice and AppleUserHIDDevice exposes a virtual gamepad for games and optional controller-driven pointer and keyboard gestures. Only the bundled agent opens the extension through a scoped DriverKit user client. The user initiates activation from Settings. We request Developer ID distribution for team 6KV8L8WQ9D. Source code is available at https://github.com/iCosiSenpai/SplitArc.

## Firma e verifica sul Mac

Lo script di rilascio cerca i profili nelle cartelle di Xcode. Per usare una cartella diversa, impostare `SPLITARC_PROFILE_DIR`. È possibile anche passare percorsi espliciti in `APP_PROVISIONING_PROFILE`, `AGENT_PROVISIONING_PROFILE` e `DEXT_PROVISIONING_PROFILE`. Il controllo verifica identificatore, team, scadenza, certificato ed entitlement prima di archiviare o inviare file al servizio di notarizzazione.

Dopo firma e notarizzazione, aprire la build di distribuzione da **Applicazioni**. In SplitArc aprire **Settings → Enable Driver** e approvare l’estensione nelle Impostazioni di Sistema quando richiesto. La schermata principale distingue la connessione Bluetooth dalla disponibilità del gamepad virtuale.

Per il collaudo del gioco:

1. Collegare i due Joy-Con e verificare che SplitArc riporti **Virtual gamepad online**.
2. Verificare che `systemextensionsctl list` riporti `dev.icosisenpai.splitarc.driver` attiva e che `hidutil list` mostri il gamepad virtuale.
3. Abilitare SDL compatibility mode per pubblicare un solo gamepad e scollegare altri controller durante il test. Da Terminale, eseguire `xcrun swift scripts/check-gamepad.swift`. Premere un pulsante e muovere lo stick sinistro.
4. Aprire il gioco e verificare pulsanti e stick. Ripetere dopo aver scollegato e ricollegato un Joy-Con.

L’approvazione dell’estensione, la visibilità in macOS e la ricezione dell’input sono tre verifiche distinte.
