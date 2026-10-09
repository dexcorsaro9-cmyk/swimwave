import SwiftUI
import SwimwaveCore

/// Allenamento in acqua. Numeri grandi, una sola informazione dominante, nessuna immagine (docs/GRAFICA.md).
///  - Nuoto: i metri che mancano alla fine della ripetizione.
///  - Recupero: i secondi che mancano, in turchese.
/// Pagina 1: allenamento. Pagina 2: controlli (termina).
struct AllenamentoView: View {
    var body: some View {
        TabView {
            PaginaAllenamento()
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
                // Riga piccola: serie corrente e ripetizione.
                Text(verbatim: String(format: NSLocalizedString("watch.serie", comment: ""),
                                      passo.indiceSerie + 1, av.piano.serieTotali,
                                      passo.ripetizione, passo.ripetizioniTotali))
                    .font(.system(.footnote, design: .rounded).weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                // Informazione dominante.
                dominante(av: av, passo: passo)

                // Tempo totale.
                Text(verbatim: formattaTempo(manager.tempoTrascorso))
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .monospacedDigit()

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
        return Color.gray.opacity(0.4)
    }
}

/// Seconda pagina: termina l'allenamento. Serve un secondo tocco per evitare errori in acqua.
struct ControlliView: View {
    @EnvironmentObject private var manager: WorkoutManager
    @State private var daConfermare = false

    var body: some View {
        VStack(spacing: 8) {
            Button {
                if daConfermare {
                    manager.termina()
                } else {
                    daConfermare = true
                }
            } label: {
                Text(LocalizedStringKey(daConfermare ? "watch.termina.conferma" : "watch.termina"))
                    .font(.system(.headline, design: .rounded).weight(.heavy))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(daConfermare ? Color.red : Color.gray)
        }
        .padding(.horizontal, 4)
    }
}
