import SwiftUI
import SwimwaveCore

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

                BarraSerie(totali: av.piano.serieTotali, corrente: passo.indiceSerie)
                    .padding(.vertical, 4)

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
                    .font(.system(size: 64, weight: .heavy, design: .rounded))
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
                    .font(.system(size: 64, weight: .heavy, design: .rounded))
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

/// Nuotata libera: nessuna scheda. Metri grandi, cronometro sotto, ambiente piccolo in alto.
/// Pausa e termina sono nella pagina dei controlli (la stessa dell'allenamento guidato).
struct PaginaLibera: View {
    @EnvironmentObject private var manager: WorkoutManager

    var body: some View {
        VStack(spacing: 2) {
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

            VStack(spacing: 0) {
                Text(verbatim: "\(Int(manager.metriTotali.rounded()))")
                    .font(.system(size: 64, weight: .heavy, design: .rounded))
                    .foregroundStyle(WatchTema.turchese)
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
        .padding(.horizontal, 4)
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
