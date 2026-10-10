import SwiftUI
import SwimwaveCore

/// Testi e simboli della domanda "facile, giusta o dura?".
enum PresentazioneSensazione {
    static func etichetta(_ s: Sensazione) -> String {
        switch s {
        case .facile: return testo("sensazione.facile")
        case .giusta: return testo("sensazione.giusta")
        case .dura: return testo("sensazione.dura")
        }
    }

    static func simbolo(_ s: Sensazione) -> String {
        switch s {
        case .facile: return "face.smiling"
        case .giusta: return "hand.thumbsup.fill"
        case .dura: return "bolt.fill"
        }
    }

    static func colore(_ s: Sensazione) -> Color {
        switch s {
        case .facile: return Tema.turchese
        case .giusta: return Tema.turcheseChiaro
        case .dura: return Tema.corallo
        }
    }
}

/// Tre pulsanti tondi: Facile / Giusta / Dura. Usata a fine allenamento, nella carta di Oggi e (come tre pulsanti) altrove.
struct SceltaSensazione: View {
    var selezionata: Sensazione?
    var compatta = false
    let azione: (Sensazione) -> Void

    var body: some View {
        let diametro: CGFloat = compatta ? 60 : 92
        HStack(alignment: .top, spacing: 12) {
            ForEach(Sensazione.allCases, id: \.self) { s in
                Button {
                    azione(s)
                } label: {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle().fill(PresentazioneSensazione.colore(s))
                            if selezionata == s {
                                Circle().stroke(Tema.testo, lineWidth: 4)
                            }
                            Image(systemName: PresentazioneSensazione.simbolo(s))
                                .font(.system(size: diametro * 0.4, weight: .bold, design: .rounded))
                                .foregroundStyle(Tema.navy)
                        }
                        .frame(width: diametro, height: diametro)
                        Text(verbatim: PresentazioneSensazione.etichetta(s))
                            .font(compatta ? Tema.piccolo.weight(.bold) : Tema.sottotitolo)
                            .foregroundStyle(Tema.testo)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(verbatim: PresentazioneSensazione.etichetta(s)))
                .accessibilityAddTraits(selezionata == s ? .isSelected : [])
            }
        }
    }
}

/// "Cosa non andava?": compare solo dopo "Dura". Tre pulsanti e un "Non saprei", un tocco solo.
/// Il motivo resta sul telefono e serve ad alleggerire il prossimo allenamento.
struct SceltaMotivoDifficolta: View {
    var selezionato: MotivoDifficolta?
    let azione: (MotivoDifficolta) -> Void

    private static let voci: [(MotivoDifficolta, String, String)] = [
        (.fiato, "lungs.fill", "motivo.fiato"),
        (.stanchezza, "battery.25percent", "motivo.stanchezza"),
        (.esercizio, "figure.pool.swim", "motivo.esercizio"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("motivo.titolo")
                .font(Tema.sottotitolo)
                .foregroundStyle(Tema.testo)
            ForEach(Self.voci, id: \.0) { motivo, simbolo, chiave in
                Button {
                    azione(motivo)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: simbolo)
                            .font(.system(.title3, design: .rounded).weight(.bold))
                            .frame(width: 32)
                            .accessibilityHidden(true)
                        Text(LocalizedStringKey(chiave))
                            .font(Tema.corpo.weight(.semibold))
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 0)
                        if selezionato == motivo {
                            Image(systemName: "checkmark.circle.fill")
                                .accessibilityHidden(true)
                        }
                    }
                    .foregroundStyle(Tema.testo)
                    .padding(.horizontal, 14)
                    .frame(minHeight: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(selezionato == motivo ? Tema.corallo.opacity(0.35) : Tema.turchese.opacity(0.14))
                    )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selezionato == motivo ? .isSelected : [])
            }
            if selezionato == nil || selezionato == .altro {
                Button {
                    azione(.altro)
                } label: {
                    Text("motivo.nonSaprei")
                        .font(Tema.piccolo.weight(.bold))
                        .foregroundStyle(selezionato == .altro ? Tema.testo : Tema.testoSecondario)
                        .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
            } else {
                Text("motivo.nota")
                    .font(Tema.piccolo)
                    .foregroundStyle(Tema.testoSecondario)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("Sensazione") {
    VStack(spacing: 24) {
        SceltaSensazione(selezionata: .giusta, azione: { _ in })
        SceltaSensazione(compatta: true, azione: { _ in })
    }
    .padding()
    .sfondoApp()
}
