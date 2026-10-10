import SwiftUI
import UIKit
import SwimwaveCore

/// Allenamento seguito sul telefono, a tutto schermo (per chi nuota senza Watch o vuole la scheda sotto gli occhi).
/// Prima la schermata guidata, poi quella di fine allenamento con la domanda "facile, giusta o dura?".
/// Durante l'allenamento non compaiono popup del coach, solo una frase breve in basso.
struct AllenamentoGuidatoView: View {
    let workout: Workout

    @Environment(StatoApp.self) private var stato
    @Environment(\.dismiss) private var dismiss
    @State private var esito: Esito?

    struct Esito: Equatable {
        let nuotataId: UUID
        let metri: Int
        let durataSecondi: Int
    }

    var body: some View {
        Group {
            if let esito {
                FineAllenamentoView(
                    nuotataId: esito.nuotataId,
                    metri: esito.metri,
                    durataSecondi: esito.durataSecondi,
                    onChiudi: { dismiss() }
                )
            } else {
                SchermataGuidata(workout: workout) { metri, durata in
                    concludi(metri: metri, durataSecondi: durata)
                }
            }
        }
        .environment(stato)
    }

    private func concludi(metri: Int, durataSecondi: Int) {
        // Se non si è nuotato nulla non si registra niente.
        guard metri > 0 else {
            dismiss()
            return
        }
        let nuotata = NuotataCompletata(
            data: Date(),
            metri: metri,
            durataSecondi: max(1, durataSecondi),
            titolo: workout.titolo,
            origine: .iphone
        )
        stato.registra(nuotata)
        esito = Esito(nuotataId: nuotata.id, metri: metri, durataSecondi: max(1, durataSecondi))
    }
}

// MARK: - Schermata guidata

private struct SchermataGuidata: View {
    let workout: Workout
    /// Chiamata una sola volta, a fine allenamento o quando si termina: metri fatti e secondi trascorsi.
    let alTermine: (_ metri: Int, _ durataSecondi: Int) -> Void

    @Environment(StatoApp.self) private var stato
    @State private var sessione: SessioneGuidata
    @State private var adesso = Date()
    /// Vero dopo l'avviso dei 5 secondi, così vibra una sola volta per recupero.
    @State private var avvisoRecuperoDato = false
    @State private var confermaTermina = false
    @State private var concluso = false
    /// Tempo obiettivo per ogni ripetizione del piano (nil dove non c'è: niente test, altro stile, nessuna intensità).
    @State private var tempiObiettivo: [Int?] = []
    /// "Bordo vasca": numeri enormi, contrasto massimo e un tocco ovunque sul centro per andare avanti.
    /// Si ricorda tra un allenamento e l'altro.
    @AppStorage("swimwave.bordoVasca") private var bordoVasca = false

    private let orologio = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    /// Quante frasi del coach ruotano (guidato.frase.1 ... guidato.frase.N).
    private static let numeroFrasi = 8

    init(workout: Workout, alTermine: @escaping (_ metri: Int, _ durataSecondi: Int) -> Void) {
        self.workout = workout
        self.alTermine = alTermine
        _sessione = State(initialValue: SessioneGuidata(workout: workout))
    }

    var body: some View {
        let passo = sessione.avanzamento.passoCorrente
        Group {
            if bordoVasca {
                vistaBordoVasca(passo)
            } else {
                vistaNormale(passo)
            }
        }
        .onAppear {
            // Lo schermo resta acceso finché la schermata è aperta.
            UIApplication.shared.isIdleTimerDisabled = true
            // Stesso piano e stesso ordine della sessione: l'indice del passo corrente è l'indice del tempo obiettivo.
            tempiObiettivo = stato.targetRitmo(per: workout)
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onReceive(orologio) { istante in
            adesso = istante
            if sessione.aggiorna(adesso: istante) {
                // Il recupero è finito: si riparte da soli, con una vibrazione leggera.
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                avvisoRecuperoDato = false
            } else if sessione.inRecupero {
                // Cinque secondi prima della fine del recupero: un colpo leggero per prepararsi a partire.
                let resto = sessione.recuperoRimanente(adesso: istante)
                if resto <= 5, resto > 0, !avvisoRecuperoDato {
                    avvisoRecuperoDato = true
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                }
            } else {
                avvisoRecuperoDato = false
            }
        }
        .confirmationDialog(
            Text("guidato.termina.titolo"),
            isPresented: $confermaTermina,
            titleVisibility: .visible
        ) {
            Button("guidato.termina.conferma", role: .destructive) {
                sessione.termina(adesso: Date())
                concludi()
            }
            Button("guidato.continua", role: .cancel) {}
        }
    }

    private func vistaNormale(_ passo: Passo?) -> some View {
        VStack(spacing: 0) {
            if let passo {
                intestazione(passo)
                Spacer(minLength: 8)
                centro(passo)
                Spacer(minLength: 8)
            } else {
                Spacer()
            }
            totale
            pulsanti
                .padding(.top, 12)
            barraCoach(passo)
                .padding(.top, 8)
                .padding(.bottom, 8)
        }
        .padding(.horizontal, 20)
        .sfondoApp()
    }

    /// Modalità a bordo vasca: sfondo nero, testo bianco, numeri enormi. Un tocco sul centro vale "Fatto" / "Vai".
    private func vistaBordoVasca(_ passo: Passo?) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                if let passo {
                    Text(verbatim: testo("guidato.serie", passo.indiceSerie + 1, sessione.avanzamento.piano.serieTotali))
                        .font(Tema.titolo2)
                        .foregroundStyle(Color.white)
                }
                Spacer(minLength: 8)
                Button {
                    bordoVasca = false
                } label: {
                    Text("guidato.bordoVasca.esci")
                        .font(Tema.sottotitolo)
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 14)
                        .frame(minHeight: 44)
                        .overlay(Capsule().stroke(Color.white.opacity(0.8), lineWidth: 1.5))
                }
                .buttonStyle(.plain)
                Button {
                    confermaTermina = true
                } label: {
                    Text("guidato.termina")
                        .font(Tema.sottotitolo)
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 14)
                        .frame(minHeight: 44)
                        .overlay(Capsule().stroke(Color.white.opacity(0.8), lineWidth: 1.5))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 12)
            if let passo {
                BarraSerieGuidata(totali: sessione.avanzamento.piano.serieTotali, corrente: passo.indiceSerie)
                    .padding(.top, 8)
            }
            ZStack {
                Color.clear
                if let passo {
                    centro(passo, grande: true)
                }
            }
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                guard !sessione.inPausa else { return }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                avanti()
            }
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(Text(LocalizedStringKey(sessione.inRecupero ? "guidato.vai" : "guidato.fatto")))
            Text("guidato.bordoVasca.suggerimento")
                .font(Tema.piccolo)
                .foregroundStyle(Color.white.opacity(0.75))
                .padding(.bottom, 6)
            Text(verbatim: testo(
                "guidato.totale",
                sessione.metriFatti,
                sessione.avanzamento.piano.metriTotali,
                FormatoTempo.mmss(sessione.tempoTrascorso(adesso: adesso))
            ))
            .font(Tema.sottotitolo)
            .monospacedDigit()
            .foregroundStyle(Color.white)
            .padding(.bottom, 10)
            Button {
                if sessione.inPausa {
                    sessione.riprendi(adesso: Date())
                } else {
                    sessione.pausa(adesso: Date())
                }
            } label: {
                Text(LocalizedStringKey(sessione.inPausa ? "guidato.riprendi" : "guidato.pausa"))
                    .font(Tema.bottone)
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white, lineWidth: 2))
            }
            .buttonStyle(.plain)
            .padding(.bottom, 12)
        }
        .padding(.horizontal, 20)
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    // MARK: Parti della schermata

    private func intestazione(_ passo: Passo) -> some View {
        VStack(spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: passo.tipoBlocco.etichetta)
                        .font(Tema.sottotitolo)
                        .textCase(.uppercase)
                        .foregroundStyle(Tema.testoSecondario)
                    Text(verbatim: testo("guidato.serie", passo.indiceSerie + 1, sessione.avanzamento.piano.serieTotali))
                        .font(Tema.titolo2)
                        .foregroundStyle(Tema.testo)
                }
                Spacer(minLength: 8)
                Button {
                    bordoVasca = true
                } label: {
                    Label("guidato.bordoVasca.attiva", systemImage: "arrow.up.left.and.arrow.down.right")
                        .labelStyle(.iconOnly)
                        .font(.system(.body, design: .rounded).weight(.bold))
                        .foregroundStyle(Tema.testo)
                        .frame(width: 44, height: 44)
                        .overlay(Circle().stroke(Tema.testoSecondario, lineWidth: 1.5))
                }
                .buttonStyle(.plain)
                Button {
                    confermaTermina = true
                } label: {
                    Text("guidato.termina")
                        .font(Tema.sottotitolo)
                        .foregroundStyle(Tema.testo)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .overlay(Capsule().stroke(Tema.testoSecondario, lineWidth: 1.5))
                }
                .buttonStyle(.plain)
            }
            BarraSerieGuidata(totali: sessione.avanzamento.piano.serieTotali, corrente: passo.indiceSerie)
        }
        .padding(.top, 12)
    }

    @ViewBuilder
    private func centro(_ passo: Passo, grande: Bool = false) -> some View {
        let primario: Color = grande ? Color.white : Tema.testo
        let secondario: Color = grande ? Color.white.opacity(0.85) : Tema.testoSecondario
        let dimensione: CGFloat = grande ? 220 : 120
        if sessione.inRecupero {
            VStack(spacing: 6) {
                Text("guidato.recupero")
                    .font(Tema.sottotitolo)
                    .textCase(.uppercase)
                    .foregroundStyle(Tema.turchese)
                Text(verbatim: testoRecupero(sessione.recuperoRimanente(adesso: adesso)))
                    .font(.system(size: dimensione, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Tema.turchese)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                if let prossimo = sessione.prossimoPasso {
                    Text(verbatim: testo("guidato.prossima", descrizioneBreve(prossimo)))
                        .font(Tema.corpo)
                        .foregroundStyle(secondario)
                        .multilineTextAlignment(.center)
                }
                statoPausa
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
        } else {
            VStack(spacing: 6) {
                Text(verbatim: nomeEsercizio(passo))
                    .font(Tema.titolo2)
                    .foregroundStyle(primario)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text(verbatim: dettaglio(passo))
                    .font(Tema.corpo)
                    .foregroundStyle(secondario)
                    .multilineTextAlignment(.center)
                Text(verbatim: "\(passo.distanzaMetri)")
                    .font(.system(size: dimensione, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(primario)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(verbatim: metriEVasche(passo))
                    .font(Tema.sottotitolo)
                    .foregroundStyle(secondario)
                // Solo un riferimento, senza giudizio: nessun colore di successo o di errore.
                if let obiettivo = tempoObiettivoCorrente {
                    Text(verbatim: TempoObiettivo.riga(obiettivo))
                        .font(Tema.piccolo)
                        .monospacedDigit()
                        .foregroundStyle(secondario)
                }
                statoPausa
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
        }
    }

    @ViewBuilder
    private var statoPausa: some View {
        if sessione.inPausa {
            Text("guidato.inPausa")
                .font(Tema.sottotitolo)
                .foregroundStyle(Tema.navy)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Capsule().fill(Tema.turcheseChiaro))
                .padding(.top, 6)
        }
    }

    private var totale: some View {
        Text(verbatim: testo(
            "guidato.totale",
            sessione.metriFatti,
            sessione.avanzamento.piano.metriTotali,
            FormatoTempo.mmss(sessione.tempoTrascorso(adesso: adesso))
        ))
        .font(Tema.sottotitolo)
        .monospacedDigit()
        .foregroundStyle(Tema.testo)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: Tema.raggio, style: .continuous)
                .fill(Tema.carta)
        )
    }

    private var pulsanti: some View {
        HStack(alignment: .center, spacing: 12) {
            Button {
                if sessione.inPausa {
                    sessione.riprendi(adesso: Date())
                } else {
                    sessione.pausa(adesso: Date())
                }
            } label: {
                Text(LocalizedStringKey(sessione.inPausa ? "guidato.riprendi" : "guidato.pausa"))
            }
            .buttonStyle(.secondario)
            .frame(width: 130)

            Button {
                avanti()
            } label: {
                Text(LocalizedStringKey(sessione.inRecupero ? "guidato.vai" : "guidato.fatto"))
            }
            .buttonStyle(.primario)
            .disabled(sessione.inPausa)
        }
    }

    /// Frase breve del coach con la testa piccola; cambia a ogni serie. Frasi neutre, mai colpevolizzanti.
    @ViewBuilder
    private func barraCoach(_ passo: Passo?) -> some View {
        if let coach = stato.profilo.coach {
            let numero = ((passo?.indiceSerie ?? 0) % SchermataGuidata.numeroFrasi) + 1
            HStack(spacing: 12) {
                AvatarCoach(coach: coach, espressione: .incoraggiamento, dimensione: 48)
                Text(verbatim: testo("guidato.frase.\(numero)"))
                    .font(Tema.corpo)
                    .foregroundStyle(Tema.testo)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Tema.raggio, style: .continuous)
                    .fill(Tema.carta)
            )
        }
    }

    // MARK: Azioni

    private func avanti() {
        let ora = Date()
        if sessione.inRecupero {
            sessione.saltaRecupero()
        } else {
            sessione.completaPasso(adesso: ora)
            if sessione.finito {
                concludi()
            }
        }
    }

    private func concludi() {
        guard !concluso else { return }
        concluso = true
        UIApplication.shared.isIdleTimerDisabled = false
        alTermine(sessione.metriFatti, sessione.tempoTrascorso(adesso: Date()))
    }

    // MARK: Testi

    /// Il drill ha il nome dai contenuti; altrimenti si mostra lo stile.
    private func nomeEsercizio(_ passo: Passo) -> String {
        if let id = passo.drill, let drill = stato.contenuti.drill(id: id) {
            return drill.nome
        }
        return passo.stile.etichetta
    }

    /// "Ripetizione 2 di 4", più lo stile se il nome in alto è quello di un drill, più l'intensità.
    private func dettaglio(_ passo: Passo) -> String {
        var parti: [String] = []
        if passo.ripetizioniTotali > 1 {
            parti.append(testo("guidato.ripetizione", passo.ripetizione, passo.ripetizioniTotali))
        }
        if passo.drill != nil {
            parti.append(passo.stile.etichetta)
        }
        if let intensita = passo.intensita {
            parti.append(intensita.etichetta)
        }
        return parti.joined(separator: " · ")
    }

    private func metriEVasche(_ passo: Passo) -> String {
        let lunghezza = max(1, workout.vascaMetri)
        let vasche = max(1, passo.distanzaMetri / lunghezza)
        return vasche == 1 ? testo("guidato.metriVasca", vasche) : testo("guidato.metriVasche", vasche)
    }

    /// Il tempo obiettivo della ripetizione in corso, se c'è.
    private var tempoObiettivoCorrente: Int? {
        let i = sessione.avanzamento.indice
        guard tempiObiettivo.indices.contains(i) else { return nil }
        return tempiObiettivo[i]
    }

    private func descrizioneBreve(_ passo: Passo) -> String {
        "\(passo.distanzaMetri) m · \(nomeEsercizio(passo))"
    }

    private func testoRecupero(_ secondi: Int) -> String {
        secondi >= 100 ? FormatoTempo.mmss(secondi) : "\(secondi)"
    }
}

// MARK: - Barra delle serie

/// Un segmento per serie: fatte in turchese, quella corrente in corallo, le altre sbiadite.
private struct BarraSerieGuidata: View {
    let totali: Int
    let corrente: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<max(1, totali), id: \.self) { i in
                Capsule()
                    .fill(colore(i))
                    .frame(height: 10)
            }
        }
        .accessibilityHidden(true)
    }

    private func colore(_ i: Int) -> Color {
        if i < corrente { return Tema.turchese }
        if i == corrente { return Tema.corallo }
        return Tema.turchese.opacity(0.2)
    }
}
