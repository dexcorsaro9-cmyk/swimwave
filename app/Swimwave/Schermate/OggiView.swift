import SwiftUI
import SwimwaveCore

struct OggiView: View {
    @Environment(StatoApp.self) private var stato
    @State private var popup: PopupCoach?
    @State private var esitoInvio: EsitoInvioWatch?
    @State private var daSeguire: AllenamentoDaSeguire?
    @State private var mostraPermessoSalute = false
    @State private var permessoSaluteProposto = false
    @State private var cambiaAperto = false

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
                    domandaUltimaNuotata
                    obiettivoSettimana
                    rigaSerie
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
        .fullScreenCover(item: $daSeguire) { da in
            AllenamentoGuidatoView(workout: da.workout)
                .environment(stato)
        }
        .sheet(isPresented: $cambiaAperto) {
            CambiaAllenamentoView(
                chiudi: { cambiaAperto = false },
                inizia: { w in
                    // Prima si chiude il foglio, poi si apre la schermata guidata (non si presentano insieme).
                    cambiaAperto = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        daSeguire = AllenamentoDaSeguire(workout: w)
                    }
                }
            )
            .environment(stato)
        }
        .sheet(isPresented: $mostraPermessoSalute) {
            PermessoSaluteView(onFine: { mostraPermessoSalute = false })
                .environment(stato)
        }
        .onChange(of: stato.nuotate.count) { _, _ in
            // Mai popup durante l'allenamento guidato: se ne parla alla chiusura.
            if daSeguire == nil { mostraPopupSeServe() }
        }
        .onChange(of: daSeguire?.id) { _, nuovo in
            if nuovo == nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { mostraPopupSeServe() }
            }
        }
        .onChange(of: popup?.id) { _, nuovo in
            if nuovo == nil { programmaPermessoSalute(dopo: 1.0) }
        }
        .onChange(of: stato.allenamentoGenerato) { _, _ in
            // Arrivato l'allenamento del coach: il Watch riceve quello aggiornato.
            _ = stato.inviaAlWatch()
        }
        .onAppear {
            mostraPopupSeServe()
            // Tiene aggiornato il Watch con l'allenamento di oggi, senza mostrare nulla.
            _ = stato.inviaAlWatch()
            programmaPermessoSalute(dopo: 2.5)
        }
        .task {
            // Senza bloccare la vista: l'allenamento mostrato cambia quando arriva quello generato.
            await stato.aggiornaAllenamentoIA()
            await stato.importaDaSalute()
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

    // MARK: Serie di settimane

    /// Riga discreta: solo da 2 settimane in su. Quando la serie si ferma non compare nulla.
    @ViewBuilder
    private var rigaSerie: some View {
        let n = stato.serieSettimane
        if n >= 2 {
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(Tema.corallo)
                    .accessibilityHidden(true)
                Text(verbatim: testo("oggi.serie", n))
                    .font(Tema.sottotitolo)
                    .foregroundStyle(Tema.testo)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 4)
            .accessibilityElement(children: .combine)
        }
    }

    // MARK: Com'è andata l'ultima nuotata

    /// Per le nuotate arrivate dal Watch (o da Salute) senza risposta, nelle ultime 24 ore.
    @ViewBuilder
    private var domandaUltimaNuotata: some View {
        if let ultima = stato.nuotate.first,
           ultima.sensazione == nil,
           Date().timeIntervalSince(ultima.data) < 24 * 3600 {
            VStack(alignment: .leading, spacing: 12) {
                Text("oggi.sensazione.titolo")
                    .font(Tema.sottotitolo)
                    .foregroundStyle(Tema.testo)
                SceltaSensazione(selezionata: nil, compatta: true) { s in
                    rispondi(s, perNuotata: ultima.id)
                }
            }
            .carta()
        }
    }

    private func rispondi(_ s: Sensazione, perNuotata id: UUID) {
        stato.imposta(sensazione: s, perNuotata: id)
        if s == .dura, popup == nil {
            popup = PopupCoach(
                momento: .dopoAllenamentoDuro,
                espressione: .dopoAllenamentoDuro,
                messaggio: testo("popup.dopoAllenamentoDuro.messaggio", stato.profilo.nomePulito)
            )
        }
    }

    // MARK: Allenamento del giorno

    @ViewBuilder
    private var allenamento: some View {
        if let w = stato.allenamentoDiOggi() {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 8) {
                    Text("oggi.allenamento.titolo")
                        .font(Tema.piccolo)
                        .foregroundStyle(Tema.testoSecondario)
                    Spacer(minLength: 8)
                    Button {
                        cambiaAperto = true
                    } label: {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(.body, design: .rounded).weight(.bold))
                            .foregroundStyle(Tema.testo)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Tema.turchese.opacity(0.18)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("libreria.cambia"))
                }
                if sceltoPerOggi {
                    HStack(spacing: 8) {
                        Text("libreria.scelto")
                            .font(Tema.piccolo.weight(.bold))
                            .foregroundStyle(Tema.testoSecondario)
                        Spacer(minLength: 8)
                        Button {
                            stato.annullaSceltaAllenamento()
                            esitoInvio = nil
                            // Il Watch torna all'allenamento proposto.
                            _ = stato.inviaAlWatch()
                        } label: {
                            Text("libreria.tornaProposto")
                                .font(Tema.piccolo.weight(.bold))
                                .foregroundStyle(Tema.coralloOmbra)
                        }
                        .buttonStyle(.plain)
                    }
                }
                // Titolo e righe vengono da content/ (testo in italiano, non ancora localizzato).
                Text(verbatim: w.titolo)
                    .font(Tema.titolo2)
                    .foregroundStyle(Tema.testo)
                HStack(spacing: 8) {
                    Etichetta(contenuto: testo("oggi.minuti", w.durataStimataMin))
                    Etichetta(contenuto: testo("oggi.metri", w.metriTotali))
                    Etichetta(contenuto: testo("oggi.vasca", w.vascaMetri))
                }
                // Righe delle serie, con il tempo obiettivo se l'utente ha fatto il test del ritmo.
                AnteprimaAllenamento(workout: w)
                Button {
                    daSeguire = AllenamentoDaSeguire(workout: w)
                } label: {
                    Text("oggi.inizia")
                }
                .buttonStyle(.primario)
                .padding(.top, 4)
                Button {
                    esitoInvio = stato.inviaAlWatch()
                } label: {
                    Text("oggi.invia")
                }
                .buttonStyle(.secondario)
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
                Button {
                    cambiaAperto = true
                } label: {
                    Text("libreria.cambia")
                }
                .buttonStyle(.secondario)
                .padding(.top, 4)
            }
            .carta()
        }
    }

    /// Vero se l'utente ha scelto lui l'allenamento di oggi (dalla libreria o chiedendolo al coach).
    private var sceltoPerOggi: Bool {
        guard stato.allenamentoScelto != nil, let giorno = stato.giornoAllenamentoScelto else { return false }
        return giorno == (Calendar.italiano.ordinality(of: .day, in: .year, for: Date()) ?? 0)
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

    /// La prima volta propone di leggere le nuotate da Salute, con un ritardo per non sovrapporsi ai popup del coach.
    /// Si propone al massimo una volta per apertura dell'app; "Più tardi" lascia la strada aperta dallo Storico e dal Profilo.
    private func programmaPermessoSalute(dopo secondi: Double) {
        guard !stato.permessoSaluteChiesto, !permessoSaluteProposto else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + secondi) {
            guard !stato.permessoSaluteChiesto, !permessoSaluteProposto,
                  popup == nil, daSeguire == nil, !mostraPermessoSalute, !cambiaAperto else { return }
            permessoSaluteProposto = true
            mostraPermessoSalute = true
        }
    }

    private func pulsanti(per p: PopupCoach) -> [PulsantePopup] {
        switch p.momento {
        case .obiettivoRaggiunto, .serieSettimane, .tappaSuperata:
            return [PulsantePopup(titolo: testo("popup.bottone.grazie"), principale: true) { popup = nil }]
        case .dopoAllenamentoDuro:
            return [PulsantePopup(titolo: testo("popup.bottone.ok"), principale: true) { popup = nil }]
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
