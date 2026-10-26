import SwiftUI
import SwimwaveCore

extension Tipologia {
    /// Colore della tipologia, dal calmo (verde) al forte (viola): serve a riconoscerla a colpo d'occhio (bozza: docs/mockup/oggi-direzioni.html).
    var colore: Color {
        switch self {
        case .a1: return Color(squaloHex: 0x5CCB9B)
        case .a2: return Color(squaloHex: 0x1FB5C9)
        case .b1: return Color(squaloHex: 0xFFC857)
        case .b2: return Color(squaloHex: 0xFF8A4C)
        case .c1: return Color(squaloHex: 0x9B6BFF)
        }
    }

    /// Testo sul colore della tipologia: navy, tranne sul viola dove serve il bianco per il contrasto.
    var testoSuColore: Color { self == .c1 ? .white : Tema.navy }
}

/// L'etichetta di una tipologia ("B1 · Soglia") che si può toccare: si apre una spiegazione breve della lettera.
/// Lo stile (carattere, colore, sfondo) lo dà chi la usa; qui ci sono il tocco, l'icona "i" e il foglio.
struct EtichettaTipologia: View {
    let tipologia: Tipologia
    var conIcona = true
    @State private var aperta = false

    var body: some View {
        Button {
            aperta = true
        } label: {
            HStack(spacing: 4) {
                Text(verbatim: nomeTipologia(tipologia))
                if conIcona {
                    Image(systemName: "info.circle")
                        .imageScale(.small)
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text("tipologia.spiega.hint"))
        .sheet(isPresented: $aperta) {
            SpiegazioneTipologiaView(iniziale: tipologia)
                .presentationDetents([.medium, .large])
        }
    }
}

/// Foglio con la spiegazione delle tipologie: si parte da quella toccata e si possono leggere le altre dai riquadri in alto.
struct SpiegazioneTipologiaView: View {
    let iniziale: Tipologia
    @State private var scelta: Tipologia?
    @Environment(\.dismiss) private var dismiss
    @Environment(StatoApp.self) private var stato

    private var tipologia: Tipologia { scelta ?? iniziale }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 8) {
                        ForEach(Tipologia.allCases) { t in
                            Button {
                                scelta = t
                            } label: {
                                Text(verbatim: t.rawValue.uppercased())
                                    .font(Tema.sottotitolo)
                                    .foregroundStyle(t.testoSuColore)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Capsule().fill(t.colore.opacity(t == tipologia ? 1 : 0.45)))
                                    .overlay(Capsule().stroke(Tema.testo.opacity(t == tipologia ? 0.7 : 0), lineWidth: 2))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(Text(verbatim: nomeTipologia(t)))
                            .accessibilityAddTraits(t == tipologia ? .isSelected : [])
                        }
                    }
                    .padding(.top, 20)

                    Text(LocalizedStringKey("tipologia.\(tipologia.rawValue).nome"))
                        .font(Tema.titolo2)
                        .foregroundStyle(Tema.testo)
                    Text(LocalizedStringKey("tipologia.\(tipologia.rawValue).spiega"))
                        .font(Tema.corpo)
                        .foregroundStyle(Tema.testo)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("tipologia.spiega.senti")
                            .font(Tema.piccolo.weight(.heavy))
                            .foregroundStyle(Tema.testoSecondario)
                        Text(LocalizedStringKey("tipologia.\(tipologia.rawValue).senti"))
                            .font(Tema.corpo)
                            .foregroundStyle(Tema.testo)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .carta()

                    if !tipologia.ammessa(a: .principiante) {
                        Label(testo("tipologia.spiega.solo"), systemImage: "lock.fill")
                            .font(Tema.piccolo.weight(.bold))
                            .foregroundStyle(Tema.testoSecondario)
                        if stato.profilo.categoriaLivello == .principiante {
                            Text("tipologia.spiega.perTe")
                                .font(Tema.piccolo)
                                .foregroundStyle(Tema.testoSecondario)
                        }
                    }
                    if tipologia == .b2 || tipologia == .c1 {
                        Text("tipologia.spiega.prudenza")
                            .font(Tema.piccolo.weight(.semibold))
                            .foregroundStyle(Tema.testoSecondario)
                    }

                    Text("tipologia.spiega.lettere")
                        .font(Tema.piccolo)
                        .foregroundStyle(Tema.testoSecondario)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }
            Button {
                dismiss()
            } label: {
                Text("comune.fatto")
            }
            .buttonStyle(.primario)
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .sfondoApp()
    }
}
