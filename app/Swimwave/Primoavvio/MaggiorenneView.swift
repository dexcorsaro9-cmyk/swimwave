import SwiftUI

/// Prima schermata in assoluto: "Hai almeno 18 anni?" (docs/legale/CHECKLIST.md, sezione D).
/// È una dichiarazione, non una verifica. Qui non c'è il coach (si sceglie dopo) e non si raccoglie nessun dato:
/// con "No" non si va avanti.
struct MaggiorenneView: View {
    @Environment(StatoApp.self) private var stato
    @State private var rifiutato = false

    var body: some View {
        VStack(spacing: 0) {
            IntestazioneOnda {
                VStack(alignment: .leading, spacing: 6) {
                    Text("maggiorenne.titolo").font(Tema.titolo2)
                    Text("maggiorenne.sottotitolo").font(Tema.corpo).opacity(0.9)
                }
            }
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: rifiutato ? "hand.wave.fill" : "figure.pool.swim")
                        .font(.system(size: 54, weight: .semibold))
                        .foregroundStyle(Tema.navy)
                        .frame(width: 110, height: 110)
                        .background(Circle().fill(Tema.turcheseChiaro))
                        .overlay(Circle().stroke(Tema.turchese, lineWidth: 4))
                        .accessibilityHidden(true)
                    if rifiutato {
                        messaggioGentile
                    } else {
                        domanda
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
            }
            piede
        }
        .animation(.easeInOut(duration: 0.2), value: rifiutato)
    }

    private var domanda: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("maggiorenne.domanda")
                .font(Tema.titolo2)
                .foregroundStyle(Tema.testo)
                .fixedSize(horizontal: false, vertical: true)
            Text("maggiorenne.spiegazione")
                .font(Tema.corpo)
                .foregroundStyle(Tema.testoSecondario)
                .fixedSize(horizontal: false, vertical: true)
        }
        .carta(padding: 18)
    }

    private var messaggioGentile: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("maggiorenne.no.titolo")
                .font(Tema.titolo2)
                .foregroundStyle(Tema.testo)
                .fixedSize(horizontal: false, vertical: true)
            Text("maggiorenne.no.testo")
                .font(Tema.corpo)
                .foregroundStyle(Tema.testoSecondario)
                .fixedSize(horizontal: false, vertical: true)
        }
        .carta(padding: 18)
    }

    @ViewBuilder
    private var piede: some View {
        VStack(spacing: 10) {
            if rifiutato {
                // Per correggere un tocco sbagliato. Non si salva nulla.
                Button { rifiutato = false } label: { Text("maggiorenne.no.indietro") }
                    .buttonStyle(.secondario)
            } else {
                Button { stato.confermaMaggiorenne() } label: { Text("maggiorenne.si") }
                    .buttonStyle(.primario)
                Button { rifiutato = true } label: { Text("maggiorenne.no") }
                    .font(Tema.sottotitolo)
                    .foregroundStyle(Tema.testoSecondario)
                    .padding(.vertical, 6)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}
