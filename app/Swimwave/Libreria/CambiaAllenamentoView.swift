import SwiftUI
import SwimwaveCore

/// Il foglio di "Cambia allenamento": due strade, la libreria o la richiesta al coach.
/// Chi lo presenta passa due azioni: `chiudi` chiude il foglio, `inizia` apre la schermata guidata.
struct CambiaAllenamentoView: View {
    let chiudi: () -> Void
    let inizia: (Workout) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    NavigationLink {
                        LibreriaView(chiudi: chiudi, inizia: inizia)
                    } label: {
                        scelta(icona: "list.bullet.rectangle", titolo: "libreria.cambia.libreria.titolo",
                               sottotitolo: "libreria.cambia.libreria.sottotitolo")
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        ChiediAlCoachView(chiudi: chiudi, inizia: inizia)
                    } label: {
                        scelta(icona: "bubble.left.fill", titolo: "libreria.cambia.coach.titolo",
                               sottotitolo: "libreria.cambia.coach.sottotitolo")
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
            }
            .sfondoApp()
            .navigationTitle(Text("libreria.cambia"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("comune.chiudi") { chiudi() }
                }
            }
        }
    }

    private func scelta(icona: String, titolo: String, sottotitolo: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Tema.turchese.opacity(0.18))
                Image(systemName: icona)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(Tema.testo)
            }
            .frame(width: 44, height: 44)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(LocalizedStringKey(titolo))
                    .font(Tema.sottotitolo)
                    .foregroundStyle(Tema.testo)
                    .multilineTextAlignment(.leading)
                Text(LocalizedStringKey(sottotitolo))
                    .font(Tema.piccolo)
                    .foregroundStyle(Tema.testoSecondario)
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .foregroundStyle(Tema.testoSecondario)
                .accessibilityHidden(true)
        }
        .carta(padding: 14)
        .accessibilityElement(children: .combine)
    }
}
