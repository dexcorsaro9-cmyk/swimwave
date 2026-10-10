import SwiftUI
import SwimwaveCore

extension Attrezzo {
    var etichetta: String { testo("attrezzo.\(rawValue)") }
}

/// "Porta a bordo vasca": gli attrezzi che servono per l'allenamento, prima del pulsante Inizia.
/// Gli attrezzi vengono dai drill dell'allenamento (content/drills.json, campi `attrezzi` e `attrezzi_facoltativi`).
struct RiquadroAttrezzatura: View {
    let attrezzatura: Attrezzatura

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "bag.fill")
                    .foregroundStyle(Tema.turchese)
                    .accessibilityHidden(true)
                Text("attrezzatura.titolo")
                    .font(Tema.sottotitolo)
                    .foregroundStyle(Tema.testo)
            }
            if attrezzatura.necessari.isEmpty {
                Text("attrezzatura.nessuno")
                    .font(Tema.corpo)
                    .foregroundStyle(Tema.testoSecondario)
            } else {
                DispostoAFlusso(spaziatura: 8) {
                    ForEach(attrezzatura.necessari, id: \.self) { Etichetta(contenuto: $0.etichetta) }
                }
            }
            if !attrezzatura.facoltativi.isEmpty {
                Text("attrezzatura.facoltativi")
                    .font(Tema.piccolo.weight(.bold))
                    .foregroundStyle(Tema.testoSecondario)
                DispostoAFlusso(spaziatura: 8) {
                    ForEach(attrezzatura.facoltativi, id: \.self) { Etichetta(contenuto: $0.etichetta) }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

/// Dispone le viste una dopo l'altra e va a capo quando non c'è più spazio.
struct DispostoAFlusso: Layout {
    var spaziatura: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let larghezza = proposal.width ?? .infinity
        return disponi(larghezza: larghezza, subviews: subviews).misura
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let esito = disponi(larghezza: bounds.width, subviews: subviews)
        for (indice, punto) in esito.punti.enumerated() {
            subviews[indice].place(at: CGPoint(x: bounds.minX + punto.x, y: bounds.minY + punto.y),
                                   proposal: .unspecified)
        }
    }

    private func disponi(larghezza: CGFloat, subviews: Subviews) -> (misura: CGSize, punti: [CGPoint]) {
        var punti: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var altezzaRiga: CGFloat = 0
        var larghezzaMassima: CGFloat = 0
        for vista in subviews {
            let d = vista.sizeThatFits(.unspecified)
            if x > 0, x + d.width > larghezza {
                x = 0
                y += altezzaRiga + spaziatura
                altezzaRiga = 0
            }
            punti.append(CGPoint(x: x, y: y))
            x += d.width + spaziatura
            altezzaRiga = max(altezzaRiga, d.height)
            larghezzaMassima = max(larghezzaMassima, x - spaziatura)
        }
        return (CGSize(width: larghezzaMassima, height: y + altezzaRiga), punti)
    }
}
