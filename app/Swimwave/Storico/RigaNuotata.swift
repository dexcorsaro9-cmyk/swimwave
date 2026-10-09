import SwiftUI
import SwimwaveCore

/// Una nuotata nell'elenco: carta con icona dell'origine, data, titolo, metri e minuti, sensazione.
/// `selezione`: nil = modo normale (compare la freccia); true/false = modo "Confronta" (compare la spunta).
struct RigaNuotata: View {
    let nuotata: NuotataCompletata
    var selezione: Bool? = nil

    var body: some View {
        HStack(spacing: 12) {
            if let scelta = selezione {
                Image(systemName: scelta ? "checkmark.circle.fill" : "circle")
                    .font(.system(.title2, design: .rounded))
                    .foregroundStyle(scelta ? Tema.turchese : Tema.testoSecondario)
                    .accessibilityHidden(true)
            }
            ZStack {
                Circle().fill(Tema.turchese.opacity(0.18))
                Image(systemName: simboloOrigine)
                    .font(.system(.body, design: .rounded).weight(.bold))
                    .foregroundStyle(Tema.testo)
            }
            .frame(width: 44, height: 44)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: FormatiUI.dataEOra(nuotata.data))
                    .font(Tema.sottotitolo)
                    .foregroundStyle(Tema.testo)
                if !nuotata.titolo.isEmpty {
                    Text(verbatim: nuotata.titolo)
                        .font(Tema.corpo)
                        .foregroundStyle(Tema.testo)
                }
                Text(verbatim: testo("storico.riga", nuotata.metri, FormatoTempo.minutiArrotondati(nuotata.durataSecondi)))
                    .font(Tema.piccolo)
                    .foregroundStyle(Tema.testoSecondario)
            }
            Spacer(minLength: 0)
            if let s = nuotata.sensazione {
                Etichetta(contenuto: PresentazioneSensazione.etichetta(s))
            } else {
                Text("storico.comeVa")
                    .font(Tema.piccolo.weight(.bold))
                    .foregroundStyle(Tema.coralloOmbra)
            }
            if selezione == nil {
                Image(systemName: "chevron.right")
                    .font(.system(.footnote, design: .rounded).weight(.bold))
                    .foregroundStyle(Tema.testoSecondario)
                    .accessibilityHidden(true)
            }
        }
        .carta(padding: 14)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(selezione == true ? .isSelected : [])
    }

    private var simboloOrigine: String {
        switch nuotata.origine {
        case .watch?: return "applewatch"
        case .iphone?: return "iphone"
        case .salute?: return "heart.fill"
        case nil: return "figure.pool.swim"
        }
    }
}
