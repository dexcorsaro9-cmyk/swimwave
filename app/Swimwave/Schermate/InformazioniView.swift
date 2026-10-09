import SwiftUI

/// Informazioni su coach virtuali, intelligenza artificiale, salute e dati.
/// I testi sono in TestiInformazioni.swift (DA FAR VEDERE A UN AVVOCATO prima della pubblicazione: docs/legale/CHECKLIST.md).
struct InformazioniView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(TestiInformazioni.sezioni) { sezione in
                    blocco(sezione)
                }
                if let versione = TestiInformazioni.versione {
                    Text(verbatim: testo("info.versione", versione))
                        .font(Tema.piccolo)
                        .foregroundStyle(Tema.testoSecondario)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(16)
        }
        .sfondoApp()
        .navigationTitle("profilo.informazioni")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func blocco(_ sezione: SezioneInformazioni) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(verbatim: sezione.titolo)
                .font(Tema.sottotitolo)
                .foregroundStyle(Tema.testo)
                .accessibilityAddTraits(.isHeader)
            ForEach(sezione.paragrafi, id: \.self) { paragrafo in
                Text(verbatim: paragrafo)
                    .font(Tema.corpo)
                    .foregroundStyle(Tema.testoSecondario)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .carta()
    }
}
