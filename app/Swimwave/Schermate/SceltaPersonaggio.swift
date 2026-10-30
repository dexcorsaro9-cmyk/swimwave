import SwiftUI
import SwimwaveCore

/// Primo fotogramma del personaggio, fermo: serve per le schede della scelta.
struct AnteprimaPersonaggio: View {
    let personaggio: Personaggio

    var body: some View {
        let foglio = personaggio.nuota
        Canvas { contesto, dimensione in
            let immagine = contesto.resolve(Image(foglio.nome))
            let tutta = CGRect(x: 0, y: 0,
                               width: dimensione.width * CGFloat(FoglioPersonaggio.colonne),
                               height: dimensione.height * CGFloat(foglio.righe))
            contesto.clip(to: Path(CGRect(origin: .zero, size: dimensione)))
            contesto.draw(immagine, in: tutta)
        }
        .aspectRatio(1 / foglio.proporzione, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

/// Griglia dei personaggi disponibili. `scelto` è l'id; nil = il primo (lo squalo).
struct GrigliaPersonaggi: View {
    @Binding var scelto: String?

    private let colonne = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        let corrente = Personaggio.con(id: scelto)
        LazyVGrid(columns: colonne, spacing: 12) {
            ForEach(Personaggio.disponibili) { p in
                let selezionato = p == corrente
                Button { scelto = p.id } label: {
                    VStack(spacing: 6) {
                        AnteprimaPersonaggio(personaggio: p)
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(LinearGradient(colors: Tipologia.a2.acqua, startPoint: .top, endPoint: .bottom))
                            )
                        Text(LocalizedStringKey(p.chiaveSpecie))
                            .font(Tema.piccolo.weight(.bold))
                            .foregroundStyle(Tema.testo)
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(selezionato ? Tema.turchese : Color.clear, lineWidth: 3)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selezionato ? [.isSelected, .isButton] : .isButton)
            }
        }
    }
}

/// Schermata del primo avvio, dopo la scelta del coach (si salta se c'è un solo personaggio).
struct SceltaPersonaggioView: View {
    @Binding var scelto: String?
    let continua: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            IntestazioneOnda {
                VStack(alignment: .leading, spacing: 6) {
                    Text("personaggio.scelta.titolo").font(Tema.titolo2)
                    Text("personaggio.scelta.sottotitolo").font(Tema.corpo).opacity(0.9)
                }
            }
            ScrollView {
                GrigliaPersonaggi(scelto: $scelto)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
            }
            Button(action: continua) { Text("comune.continua") }
                .buttonStyle(.primario)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
        }
    }
}
