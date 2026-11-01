import Foundation
import SwimwaveCore

/// Modalità demo: l'app parte con un profilo e uno storico inventati, senza domande iniziali, popup o richieste di permesso.
/// Serve ai test dell'interfaccia (SwimwaveUITests), che scattano gli screenshot di tutte le schermate nelle tre lingue e con
/// il testo grande. Si attiva solo con l'argomento di avvio `-SwimwaveDemo` e solo nelle build di sviluppo (DEBUG).
/// I dati stanno in un archivio a parte che si azzera a ogni avvio, quindi non toccano quelli veri.
enum ModalitaDemo {
    static let argomento = "-SwimwaveDemo"
    /// Con questo argomento in più resta la schermata di apertura (per scattarne la foto).
    static let argomentoSplash = "-SwimwaveSplash"
    /// Parte da zero, come alla prima apertura dell'app (18 anni, coach, domande).
    static let argomentoPrimoAvvio = "-SwimwavePrimoAvvio"
    /// Parte con tutto pronto ma senza il consenso all'IA: si vede la schermata del consenso.
    static let argomentoConsenso = "-SwimwaveConsenso"
    /// Parte con il recap del coach per l'ultima nuotata (come dopo una nuotata fatta con il Watch).
    static let argomentoRecap = "-SwimwaveRecap"

    /// Solo nelle build di sviluppo (quelle dei test): nell'app che arriva agli utenti la modalità demo non esiste.
    static var attiva: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.arguments.contains(argomento)
        #else
        return false
        #endif
    }
    static var mostraSplash: Bool { attiva && ProcessInfo.processInfo.arguments.contains(argomentoSplash) }

    /// Lo stato dell'app: quello vero, o quello demo.
    static func creaStato() -> StatoApp {
        guard attiva else { return StatoApp() }
        let nome = "swimwave.demo"
        let archivio = UserDefaults(suiteName: nome) ?? .standard
        archivio.removePersistentDomain(forName: nome)
        let stato = StatoApp(defaults: archivio)
        let argomenti = ProcessInfo.processInfo.arguments
        if !argomenti.contains(argomentoPrimoAvvio) {
            stato.riempiConDatiDemo()
            if argomenti.contains(argomentoConsenso) { stato.consensoIA = nil }
            if argomenti.contains(argomentoRecap), !stato.nuotate.isEmpty {
                stato.nuotate[0].sensazione = nil          // il recap chiede com'è andata
                stato.recapInAttesa = stato.nuotate[0].id
            }
        }
        return stato
    }
}

extension StatoApp {
    /// Un'utente che nuota da qualche mese: profilo completo, 26 nuotate, cinque tappe superate e il test del ritmo fatto.
    func riempiConDatiDemo(adesso: Date = Date()) {
        profilo = Profilo(coach: .donna, nome: "Giulia", livello: .piuDiCento, obiettivo: .resistenza,
                          vasca: .metri25, ritmo: .regolare, frequenzaSettimanale: 3, personaggio: "delfino")
        maggiorenneConfermato = true
        onboardingCompletato = true
        consensoIA = false
        permessoSaluteChiesto = true
        tappaAttuale = 6
        tappeSuperate = [1, 2, 3, 4, 5]
        testRitmo = TestRitmo(data: adesso.addingTimeInterval(-20 * 86_400), tempo200Secondi: 235)
        giornoUltimoPopup = adesso

        let calendario = Calendar.current
        let titoli = ["Resistenza intermedia", "Tecnica: catch-up", "Ritmo alto: 10 × 50 m",
                      "Fondo facile: 8 × 25 m", "Soglia: 6 × 100 m"]
        let sensazioni: [Sensazione] = [.giusta, .facile, .giusta, .dura]
        var lista: [NuotataCompletata] = []
        for i in 0..<26 {
            let giorniFa = 2 + i * 4 + (i % 3)
            let data = calendario.date(byAdding: .day, value: -giorniFa, to: adesso) ?? adesso
            let metri = 800 + (i * 150) % 1400
            let secondiPer100 = 105 + (i * 7) % 25
            let vasche: [SplitVasca]? = i < 8 ? (0..<(metri / 25)).map {
                SplitVasca(metri: 25, durataSecondi: Double(secondiPer100) / 4 + Double($0 % 3),
                           stile: .libero, inizioSecondi: Double($0) * Double(secondiPer100) / 4)
            } : nil
            lista.append(NuotataCompletata(
                data: data, metri: metri, durataSecondi: metri / 100 * secondiPer100 + 120,
                titolo: titoli[i % titoli.count], sensazione: sensazioni[i % sensazioni.count],
                origine: i % 5 == 0 ? .salute : (i % 2 == 0 ? .watch : .iphone),
                calorie: metri / 4, frequenzaCardiacaMedia: 128 + i % 20,
                bracciate: metri / 25 * (18 + i % 4), vascaMetri: 25, ambiente: .vasca, vasche: vasche))
        }
        nuotate = lista.sorted { $0.data > $1.data }
        // Nessuna festa a schermo intero all'apertura.
        medaglieViste = Set(medaglie.map(\.id))
    }
}
