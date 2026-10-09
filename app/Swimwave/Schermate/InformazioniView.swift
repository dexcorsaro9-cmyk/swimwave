import SwiftUI

/// Informazioni su coach virtuali e IA. Il testo completo e' un SEGNAPOSTO: va scritto e verificato prima del rilascio
/// (AI Act, linee guida degli store, GDPR). Quando esisteranno i documenti in docs/legale/ andranno collegati qui.
struct InformazioniView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                blocco("info.coach.titolo", "info.coach.testo")
                blocco("info.ia.titolo", "info.ia.testo")
                blocco("info.salute.titolo", "info.salute.testo")
                blocco("info.dati.titolo", "info.dati.testo")
                Text("info.segnaposto")
                    .font(Tema.piccolo)
                    .foregroundStyle(Tema.testoSecondario)
            }
            .padding(16)
        }
        .sfondoApp()
        .navigationTitle("profilo.informazioni")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func blocco(_ titolo: String, _ testo: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(LocalizedStringKey(titolo)).font(Tema.sottotitolo).foregroundStyle(Tema.testo)
            Text(LocalizedStringKey(testo)).font(Tema.corpo).foregroundStyle(Tema.testoSecondario)
        }
        .carta()
    }
}
