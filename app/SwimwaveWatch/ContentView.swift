import SwiftUI
import SwimwaveCore

/// Schermata iniziale del Watch: in attesa dell'allenamento, pronto a partire, in corso, finito.
struct ContentView: View {
    @EnvironmentObject private var manager: WorkoutManager

    var body: some View {
        Group {
            switch manager.stato {
            case .inAttesa:
                InAttesaView()
            case .pronto:
                ProntoView()
            case .inCorso:
                AllenamentoView()
            case .finito:
                RiepilogoView()
            }
        }
    }
}

struct InAttesaView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("watch.attesa.titolo")
                .font(.system(.headline, design: .rounded))
                .multilineTextAlignment(.center)
            Text("watch.attesa.testo")
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct ProntoView: View {
    @EnvironmentObject private var manager: WorkoutManager

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                if let w = manager.workout {
                    // Titolo da content/ (italiano, non localizzato).
                    Text(verbatim: w.titolo)
                        .font(.system(.headline, design: .rounded))
                        .multilineTextAlignment(.center)
                    Text(verbatim: String(format: NSLocalizedString("watch.pronto.riga", comment: ""), w.metriTotali, w.durataStimataMin))
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Button {
                    manager.inizia()
                } label: {
                    Text("watch.inizia")
                        .font(.system(.title3, design: .rounded).weight(.heavy))
                        .foregroundStyle(WatchTema.navy)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(WatchTema.corallo)
                if let errore = manager.messaggioErrore {
                    Text(verbatim: errore)
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
}

struct RiepilogoView: View {
    @EnvironmentObject private var manager: WorkoutManager

    var body: some View {
        ScrollView {
            VStack(spacing: 6) {
                Text("watch.fine.titolo")
                    .font(.system(.headline, design: .rounded))
                if let r = manager.riepilogo {
                    Text(verbatim: "\(r.metri)")
                        .font(.system(size: 52, weight: .heavy, design: .rounded))
                        .foregroundStyle(WatchTema.turchese)
                        .minimumScaleFactor(0.5)
                    Text("watch.metri")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text(verbatim: formattaTempo(TimeInterval(r.durataSecondi)))
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .monospacedDigit()
                }
                Button {
                    manager.chiudiRiepilogo()
                } label: {
                    Text("watch.fine.chiudi")
                        .font(.system(.title3, design: .rounded).weight(.heavy))
                        .foregroundStyle(WatchTema.navy)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(WatchTema.corallo)
            }
        }
    }
}
