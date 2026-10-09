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

#Preview("Sensazione") {
    VStack(spacing: 24) {
        SceltaSensazione(selezionata: .giusta, azione: { _ in })
        SceltaSensazione(compatta: true, azione: { _ in })
    }
    .padding()
    .sfondoApp()
}
