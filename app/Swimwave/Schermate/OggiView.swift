import SwiftUI
import SwimwaveCore

struct OggiView: View {
    @Environment(StatoApp.self) private var stato
    @State private var popup: PopupCoach?
    @State private var esitoInvio: EsitoInvioWatch?

    var body: some View {
        let profilo = stato.profilo
        let fascia = FasciaOraria(data: Date(), calendar: .italiano)
        ScrollView {
            VStack(spacing: 0) {
                IntestazioneOnda {
                    HStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(verbatim: fascia.saluto(nome: profilo.nomePulito))
                                .font(Tema.titolo2)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("oggi.sottotitolo")
                                .font(Tema.corpo)
                                .opacity(0.9)
                        }
                        Spacer(minLength: 0)
                        if let coach = profilo.coach {
                            AvatarCoach(coach: coach, espressione: .benvenuto, dimensione: 52)
                        }
                    }
                }
                VStack(spacing: 16) {
                    obiettivoSettimana
                    allenamento
                    #if DEBUG
                    Button {
                        let adesso = Date()
                        stato.registra(NuotataCompletata(data: adesso, metri: 500, durataSecondi: 1500, titolo: "Debug"))
                        mostraPopupSeServe()
                    } label: {
                        Text(verbatim: "Segna una nuotata (solo debug)")
                    }
                    .buttonStyle(.secondario)
                    #endif
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .sfondoApp()
        .coachPopup($popup, coach: profilo.coach) { p in
            pulsanti(per: p)
        }
        .onChange(of: stato.nuotate.count) { _, _ in
            mostraPopupSeServe()
        }
        .onAppear {
            mostraPopupSeServe()
            // Tiene aggiornato il Watch con l'allenamento di oggi, senza mostrare nulla.
            _ = stato.inviaAlWatch()
        }
    }

    // MARK: Obiettivo della settimana

    @ViewBuilder
    private var obiettivoSettimana: some View {
        if let p = stato.progressoSettimana {
            VStack(alignment: .leading, spacing: 10) {
                Text("oggi.obiettivo.titolo")
                    .font(Tema.sottotitolo)
                    .foregroundStyle(Tema.testo)
                Text(verbatim: testo("oggi.obiettivo.conteggio", p.nuotate, p.obiettivo))
                    .font(Tema.numeroGrande)
                    .foregroundStyle(Tema.testo)
                BarraAvanzamento(frazione: p.frazione, colore: p.raggiunto ? Tema.corallo : Tema.turchese)
                Text(verbatim: frase(per: p.mancanti))
                    .font(Tema.corpo)
                    .foregroundStyle(Tema.testoSecondario)
            }
            .carta()
            .accessibilityElement(children: .combine)
        } else {
            // Ritmo Libero: nessun obiettivo, solo un conteggio discreto.
            VStack(alignment: .leading, spacing: 6) {
                Text("oggi.libero.titolo")
                    .font(Tema.sottotitolo)
                    .foregroundStyle(Tema.testo)
                Text(verbatim: testo("oggi.libero.conteggio", stato.nuotateQuestaSettimana))
                    .font(Tema.corpo)
                    .foregroundStyle(Tema.testoSecondario)
            }
            .carta()
        }
    }

    private func frase(per mancanti: Mancanti) -> String {
        switch mancanti {
        case .raggiunto: return testo("oggi.obiettivo.raggiunto")
        case .uno: return testo("oggi.obiettivo.mancaUno")
        case .piu(let n): return testo("oggi.obiettivo.mancanoN", n)
        }
    }

    // MARK: Allenamento del giorno

    @ViewBuilder
    private var allenamento: some View {
        if let w = stato.allenamentoDiOggi() {
            VStack(alignment: .leading, spacing: 14) {
                Text("oggi.allenamento.titolo")
                    .font(Tema.piccolo)
                    .foregroundStyle(Tema.testoSecondario)
                // Titolo e righe vengono da content/ (testo in italiano, non ancora localizzato).
                Text(verbatim: w.titolo)
                    .font(Tema.titolo2)
                    .foregroundStyle(Tema.testo)
                HStack(spacing: 8) {
                    Etichetta(contenuto: testo("oggi.minuti", w.durataStimataMin))
                    Etichetta(contenuto: testo("oggi.metri", w.metriTotali))
                    Etichetta(contenuto: testo("oggi.vasca", w.vascaMetri))
                }
                ForEach(Array(w.blocchi.enumerated()), id: \.offset) { _, blocco in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(verbatim: blocco.tipo.etichetta)
                            .font(Tema.sottotitolo)
                            .foregroundStyle(Tema.testo)
                        ForEach(Array(blocco.serie.enumerated()), id: \.offset) { _, serie in
                            Text(verbatim: w.descrizione(di: serie) { stato.contenuti.drill(id: $0)?.nome })
                                .font(Tema.corpo)
                                .foregroundStyle(Tema.testoSecondario)
                        }
                    }
                }
                Button {
                    esitoInvio = stato.inviaAlWatch()
                } label: {
                    Text("oggi.invia")
                }
                .buttonStyle(.primario)
                .padding(.top, 4)
                if let esito = esitoInvio {
                    Text(verbatim: messaggio(per: esito))
                        .font(Tema.piccolo)
                        .foregroundStyle(Tema.testoSecondario)
                }
            }
            .carta()
        } else {
            // Nessun allenamento approvato (o contenuti non leggibili).
            VStack(alignment: .leading, spacing: 8) {
                Text("oggi.vuoto.titolo")
                    .font(Tema.sottotitolo)
                    .foregroundStyle(Tema.testo)
                Text("oggi.vuoto.testo")
                    .font(Tema.corpo)
                    .foregroundStyle(Tema.testoSecondario)
            }
            .carta()
        }
    }

    private func messaggio(per esito: EsitoInvioWatch) -> String {
        switch esito {
        case .inviato: return testo("oggi.invia.ok")
        case .watchNonDisponibile: return testo("oggi.invia.noWatch")
        case .errore: return testo("oggi.invia.errore")
        }
    }

    // MARK: Popup

    private func mostraPopupSeServe() {
        guard popup == nil, let p = stato.popupDaMostrare() else { return }
        stato.segnaMostrato(p)
        popup = p
    }

    private func pulsanti(per p: PopupCoach) -> [PulsantePopup] {
        switch p.momento {
        case .obiettivoRaggiunto:
            return [PulsantePopup(titolo: testo("popup.bottone.grazie"), principale: true) { popup = nil }]
        case .benvenutoGiornata, .ripartenza:
            return [
                PulsantePopup(titolo: testo("popup.bottone.ciSono"), principale: true) { popup = nil },
                PulsantePopup(titolo: testo("popup.bottone.piuTardi")) { popup = nil },
            ]
        }
    }
}

struct Etichetta: View {
    let contenuto: String

    var body: some View {
        Text(verbatim: contenuto)
            .font(Tema.piccolo.weight(.bold))
            .foregroundStyle(Tema.testo)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(Tema.turchese.opacity(0.18)))
    }
}
