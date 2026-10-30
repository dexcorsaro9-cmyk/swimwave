import SwiftUI
import SwimwaveCore
import WatchKit

/// Allenamento in acqua. Numeri grandi, una sola informazione dominante, nessuna immagine (docs/GRAFICA.md).
///  - Nuoto: i metri che mancano alla fine della ripetizione.
///  - Recupero: i secondi che mancano, in turchese.
/// Pagina 1: allenamento. Pagina 2: controlli (pausa/riprendi e termina). In pausa si legge "In pausa" e i numeri sono attenuati.
struct AllenamentoView: View {
    @EnvironmentObject private var manager: WorkoutManager

    var body: some View {
        TabView {
            if manager.modo == .libera {
                PaginaLibera()
            } else {
                PaginaAllenamento()
            }
            ControlliView()
        }
        .tabViewStyle(.page)
    }
}

struct PaginaAllenamento: View {
    @EnvironmentObject private var manager: WorkoutManager

    /// Il numero dominante: un po' più piccolo sugli orologi da 40/41 mm, per fare posto allo squalo senza tagliare nulla.
    private var dimensioneNumero: CGFloat { WKInterfaceDevice.current().screenBounds.height < 220 ? 54 : 64 }

    var body: some View {
        if let av = manager.avanzamento, let passo = av.passoCorrente {
            VStack(spacing: 2) {
                // Riga piccola: serie corrente e ripetizione. In pausa lascia il posto alla scritta "In pausa".
                if manager.inPausa {
                    Text("watch.inpausa")
                        .font(.system(.headline, design: .rounded).weight(.heavy))
                        .foregroundStyle(WatchTema.corallo)
                        .lineLimit(1)
                } else {
                    Text(verbatim: String(format: NSLocalizedString("watch.serie", comment: ""),
                                          passo.indiceSerie + 1, av.piano.serieTotali,
                                          passo.ripetizione, passo.ripetizioniTotali))
                        .font(.system(.footnote, design: .rounded).weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                // Informazione dominante (attenuata in pausa).
                dominante(av: av, passo: passo)
                    .opacity(manager.inPausa ? 0.35 : 1)

                // Tempo totale (fermo in pausa).
                Text(verbatim: formattaTempo(manager.tempoTrascorso))
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .monospacedDigit()
                    .opacity(manager.inPausa ? 0.35 : 1)

                // Lo squalo nuota lungo la corsia con l'avanzamento della ripetizione; sotto, i segmenti delle serie.
                // Nel recupero resta a fine corsia e galleggia piano. Una nuova ripetizione lo riporta all'inizio senza scivolare all'indietro.
                VStack(spacing: 1) {
                    // Nel recupero lo squalo sbadiglia e dondola; nella serie principale è concentrato; nel resto nuota tranquillo.
                    CorsiaSqualo(progresso: progressoRipetizione(av: av, passo: passo),
                                 nuota: !isRecupero(av), inPausa: manager.inPausa,
                                 foglio: isRecupero(av) ? .stanco : (passo.tipoBlocco == .principale ? .concentrato : .nuota))
                        .id(passo.indiceSerie * 1000 + passo.ripetizione)
                    BarraSerie(totali: av.piano.serieTotali, corrente: passo.indiceSerie)
                }
                .padding(.vertical, 2)

                Button {
                    manager.avanti()
                } label: {
                    Text(LocalizedStringKey(isRecupero(av) ? "watch.vai" : "watch.fatto"))
                        .font(.system(.headline, design: .rounded).weight(.heavy))
                        .foregroundStyle(WatchTema.navy)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(WatchTema.corallo)
                .disabled(manager.inPausa)
            }
            .padding(.horizontal, 4)
        } else {
            Text("watch.fine.titolo")
        }
    }

    /// Quanto della ripetizione è stato nuotato (0...1). Nel recupero la ripetizione è finita: 1.
    private func progressoRipetizione(av: AvanzamentoAllenamento, passo: Passo) -> Double {
        if isRecupero(av) { return 1 }
        guard passo.distanzaMetri > 0 else { return 0 }
        return min(1, max(0, manager.metriNellaRipetizione / Double(passo.distanzaMetri)))
    }

    private func isRecupero(_ av: AvanzamentoAllenamento) -> Bool {
        if case .recupero = av.fase { return true }
        return false
    }

    @ViewBuilder
    private func dominante(av: AvanzamentoAllenamento, passo: Passo) -> some View {
        if isRecupero(av) {
            VStack(spacing: 0) {
                Text("watch.recupero")
                    .font(.system(.footnote, design: .rounded).weight(.bold))
                    .foregroundStyle(WatchTema.turchese)
                Text(verbatim: "\(manager.recuperoRimanente)")
                    .font(.system(size: dimensioneNumero, weight: .heavy, design: .rounded))
                    .foregroundStyle(WatchTema.turchese)
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
        } else {
            VStack(spacing: 0) {
                // Quanto manca alla fine della ripetizione (non scende sotto zero).
                let mancano = max(0, passo.distanzaMetri - Int(manager.metriNellaRipetizione.rounded()))
                Text(verbatim: "\(mancano)")
                    .font(.system(size: dimensioneNumero, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                // Stile della ripetizione, piccolo.
                Text(LocalizedStringKey(chiaveStile(passo.stile)))
                    .font(.system(.footnote, design: .rounded).weight(.semibold))
                    .foregroundStyle(.secondary)
                // Tempo obiettivo della ripetizione, solo se l'iPhone lo ha mandato. È un riferimento: nessun colore di giudizio.
                if let obiettivo = manager.obiettivoCorrente {
                    Text(verbatim: String(format: NSLocalizedString("watch.obiettivo", comment: ""),
                                          formattaObiettivo(obiettivo)))
                        .font(.system(.footnote, design: .rounded).weight(.semibold))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
    }

    private func chiaveStile(_ s: Stile) -> String {
        switch s {
        case .libero: return "stile.libero"
        case .dorso: return "stile.dorso"
        case .rana: return "stile.rana"
        case .delfino: return "stile.delfino"
        case .misto: return "stile.misto"
        }
    }
}

/// Nuotata libera: nessuna scheda. La schermata principale ha metri grandi e cronometro; un tocco mostra tutti gli altri
/// dati insieme (ritmo medio ogni 100 m, battito, calorie, vasche in piscina, bracciate), un altro tocco torna ai metri.
/// Un dato che l'orologio non ha ancora misurato si mostra come "--", senza inventare nulla.
/// Nella nuotata libera il Blocco Acqua non si attiva, così il tocco funziona subito, senza girare la corona.
/// Pausa e termina sono nella pagina dei controlli (la stessa dell'allenamento guidato).
struct PaginaLibera: View {
    @EnvironmentObject private var manager: WorkoutManager
    @State private var mostraDettagli = false

    private let turchese = WatchTema.turchese
    private let ambra = Color(red: 1.0, green: 0.78, blue: 0.34)
    private let arancio = Color(red: 1.0, green: 0.54, blue: 0.30)
    private let menta = Color(red: 0.36, green: 0.80, blue: 0.61)
    private let viola = Color(red: 0.61, green: 0.42, blue: 1.0)

    var body: some View {
        Group {
            if mostraDettagli { dettagli } else { principale }
        }
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            mostraDettagli.toggle()
            WKInterfaceDevice.current().play(.click)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    // MARK: Schermata principale

    private var principale: some View {
        VStack(spacing: 2) {
            intestazione

            VStack(spacing: 0) {
                Text(verbatim: "\(Int(manager.metriTotali.rounded()))")
                    .font(.system(size: 64, weight: .heavy, design: .rounded))
                    .foregroundStyle(turchese)
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text("watch.metri")
                    .font(.system(.footnote, design: .rounded).weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .opacity(manager.inPausa ? 0.35 : 1)

            Text(verbatim: formattaTempo(manager.tempoTrascorso))
                .font(.system(.title2, design: .rounded).weight(.bold))
                .monospacedDigit()
                .padding(.top, 4)
                .opacity(manager.inPausa ? 0.35 : 1)
        }
    }

    // MARK: Tutti gli altri dati

    private var dettagli: some View {
        VStack(spacing: 4) {
            if manager.inPausa {
                Text("watch.inpausa")
                    .font(.system(.footnote, design: .rounded).weight(.heavy))
                    .foregroundStyle(WatchTema.corallo)
                    .lineLimit(1)
            }
            Text(verbatim: formattaTempo(manager.tempoTrascorso))
                .font(.system(.title3, design: .rounded).weight(.bold))
                .monospacedDigit()
                .opacity(manager.inPausa ? 0.35 : 1)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)], spacing: 4) {
                cella(ritmoPer100 ?? "--", "watch.libera.ritmo", ambra)
                cella(manager.frequenzaCardiaca.map(String.init) ?? "--", "watch.libera.cuore", WatchTema.corallo)
                cella(manager.calorieAttive.map(String.init) ?? "--", "watch.libera.calorie", arancio)
                if manager.ambiente == .vasca {
                    cella("\(Int(manager.metriTotali) / max(1, manager.vascaMetriScelti))", "watch.libera.vasche", menta)
                }
                cella(manager.bracciateTotali.map(String.init) ?? "--", "watch.libera.bracciate", viola)
            }
            .opacity(manager.inPausa ? 0.35 : 1)
        }
    }

    private func cella(_ valore: String, _ etichetta: String, _ colore: Color) -> some View {
        VStack(spacing: 0) {
            Text(verbatim: valore)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(colore)
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(LocalizedStringKey(etichetta))
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Pezzi comuni

    @ViewBuilder
    private var intestazione: some View {
        if manager.inPausa {
            Text("watch.inpausa")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(WatchTema.corallo)
                .lineLimit(1)
        } else {
            Text(verbatim: manager.ambiente == .vasca
                 ? String(format: NSLocalizedString("watch.libera.vasca", comment: ""), manager.vascaMetriScelti)
                 : NSLocalizedString("watch.libera.acque", comment: ""))
                .font(.system(.footnote, design: .rounded).weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    /// Ritmo medio ogni 100 m dall'inizio. Prima di 25 m il dato sarebbe troppo ballerino: "--".
    private var ritmoPer100: String? {
        guard manager.metriTotali >= 25, manager.tempoTrascorso > 0 else { return nil }
        return FormatoRitmo.minutiSecondi(manager.tempoTrascorso / manager.metriTotali * 100)
    }
}

/// Un segmento per serie: fatte in turchese, quella corrente in corallo, le altre in grigio.
struct BarraSerie: View {
    let totali: Int
    let corrente: Int

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<max(1, totali), id: \.self) { i in
                Capsule()
                    .fill(colore(i))
                    .frame(height: 6)
            }
        }
        .accessibilityHidden(true)
    }

    private func colore(_ i: Int) -> Color {
        if i < corrente { return WatchTema.turchese }
        if i == corrente { return WatchTema.corallo }
        return Color.secondary.opacity(0.4)
    }
}

/// Seconda pagina: pausa/riprendi e termina. Pulsanti grandi (si usano con le mani bagnate).
/// Per terminare servono due tocchi (il secondo entro 4 secondi) per evitare errori in acqua.
struct ControlliView: View {
    @EnvironmentObject private var manager: WorkoutManager
    @State private var daConfermare = false

    var body: some View {
        VStack(spacing: 8) {
            if manager.inPausa {
                Text("watch.inpausa")
                    .font(.system(.headline, design: .rounded).weight(.heavy))
                    .foregroundStyle(WatchTema.corallo)
            }

            Button {
                daConfermare = false
                if manager.inPausa {
                    manager.riprendi()
                } else {
                    manager.pausa()
                }
            } label: {
                Text(LocalizedStringKey(manager.inPausa ? "watch.riprendi" : "watch.pausa"))
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                    .foregroundStyle(WatchTema.navy)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(WatchTema.turchese)

            Button {
                if daConfermare {
                    daConfermare = false
                    manager.termina()
                } else {
                    daConfermare = true
                }
            } label: {
                Text(LocalizedStringKey(daConfermare ? "watch.termina.conferma" : "watch.termina"))
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                    .foregroundStyle(daConfermare ? WatchTema.navy : Color.primary)
                    .frame(maxWidth: .infinity)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(daConfermare ? WatchTema.corallo : Color.secondary.opacity(0.5))
        }
        .padding(.horizontal, 4)
        // La conferma scade da sola dopo 4 secondi (o quando si lascia la pagina).
        .task(id: daConfermare) {
            guard daConfermare else { return }
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            daConfermare = false
        }
    }
}
