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
            case .sceltaLibera:
                SceltaLiberaView()
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
        ScrollView {
            VStack(spacing: 8) {
                Text("watch.attesa.titolo")
                    .font(.system(.headline, design: .rounded))
                    .multilineTextAlignment(.center)
                Text("watch.attesa.testo")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                PulsanteNuotataLibera()
            }
            .padding(.horizontal, 4)
        }
    }
}

/// Secondo pulsante della schermata iniziale: apre la scelta tra vasca e acque libere. Grande, si usa bagnati.
struct PulsanteNuotataLibera: View {
    @EnvironmentObject private var manager: WorkoutManager

    var body: some View {
        Button {
            manager.apriSceltaLibera()
        } label: {
            Text("watch.libera.pulsante")
                .font(.system(.title3, design: .rounded).weight(.heavy))
                .foregroundStyle(WatchTema.navy)
                .frame(maxWidth: .infinity)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(WatchTema.turchese)
    }
}

/// Tre pulsanti grandi (si usano bagnati) prima di avviare la nuotata libera: vasca 25 m, vasca 50 m, acque libere.
struct SceltaLiberaView: View {
    @EnvironmentObject private var manager: WorkoutManager

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text("watch.libera.scelta")
                    .font(.system(.headline, design: .rounded))
                    .multilineTextAlignment(.center)

                pulsanteVasca(25, colore: WatchTema.turchese)
                pulsanteVasca(50, colore: WatchTema.turchese)

                Button {
                    manager.iniziaLibera(in: .acqueLibere)
                } label: {
                    Text("watch.libera.acque")
                        .font(.system(.title3, design: .rounded).weight(.heavy))
                        .foregroundStyle(WatchTema.navy)
                        .frame(maxWidth: .infinity)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(WatchTema.corallo)

                Text("watch.libera.nota")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                if let errore = manager.messaggioErrore {
                    Text(verbatim: errore)
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Button {
                    manager.annullaSceltaLibera()
                } label: {
                    Text("watch.libera.indietro")
                        .font(.system(.headline, design: .rounded))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(.horizontal, 4)
        }
    }

    private func pulsanteVasca(_ metri: Int, colore: Color) -> some View {
        Button {
            manager.iniziaLibera(in: .vasca, vascaMetri: metri)
        } label: {
            Text(verbatim: String(format: NSLocalizedString("watch.libera.vasca", comment: ""), metri))
                .font(.system(.title3, design: .rounded).weight(.heavy))
                .foregroundStyle(WatchTema.navy)
                .frame(maxWidth: .infinity)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(colore)
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
                .controlSize(.large)
                .tint(WatchTema.corallo)
                PulsanteNuotataLibera()
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
                    // Dati in più, piccoli, solo se il Watch li ha misurati.
                    if r.calorie != nil || r.frequenzaCardiacaMedia != nil {
                        HStack(spacing: 12) {
                            if let kcal = r.calorie {
                                Text(verbatim: String(format: NSLocalizedString("watch.fine.calorie", comment: ""), kcal))
                            }
                            if let fc = r.frequenzaCardiacaMedia {
                                Text(verbatim: String(format: NSLocalizedString("watch.fine.fc", comment: ""), fc))
                            }
                        }
                        .font(.system(.footnote, design: .rounded).weight(.semibold))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    }
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
