import SwiftUI
import SwimwaveCore

/// Segnaposto: per ora mostra le nuotate che il Watch consegna all'app.
/// La lettura delle nuotate da Apple Salute (HealthKit) è da fare.
struct StoricoView: View {
    @Environment(StatoApp.self) private var stato

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                IntestazioneOnda {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("storico.titolo").font(Tema.titolo2)
                        Text("storico.sottotitolo").font(Tema.corpo).opacity(0.9)
                    }
                }
                VStack(spacing: 12) {
                    if stato.nuotate.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("storico.vuoto.titolo")
                                .font(Tema.sottotitolo)
                                .foregroundStyle(Tema.testo)
                            Text("storico.vuoto.testo")
                                .font(Tema.corpo)
                                .foregroundStyle(Tema.testoSecondario)
                        }
                        .carta()
                    } else {
                        ForEach(stato.nuotate) { n in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(verbatim: n.data.formatted(date: .abbreviated, time: .shortened))
                                    .font(Tema.sottotitolo)
                                    .foregroundStyle(Tema.testo)
                                Text(verbatim: testo("storico.riga", n.metri, n.durataSecondi / 60))
                                    .font(Tema.corpo)
                                    .foregroundStyle(Tema.testoSecondario)
                            }
                            .carta()
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .sfondoApp()
    }
}
