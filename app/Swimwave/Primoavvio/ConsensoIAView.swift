import SwiftUI
import SwimwaveCore

/// Consenso all'uso dell'intelligenza artificiale. È il punto in cui l'utente viene informato e sceglie
/// (AI Act art. 50, GDPR, linee guida Apple 5.1.2(i): TESTI DA FAR VERIFICARE A UN AVVOCATO, vedi docs/legale/CHECKLIST.md, punto C3).
/// Il coach, scelto prima, parla in prima persona e dice qui una volta sola che è un personaggio virtuale.
/// Dire "no" non blocca nulla: l'app usa gli allenamenti fissi preparati dal team.
struct ConsensoIAView: View {
    @Environment(StatoApp.self) private var stato
    @State private var mostraInformazioni = false

    private var nomeCoach: String { stato.profilo.coach?.nome ?? "Swimwave" }

    var body: some View {
        VStack(spacing: 0) {
            IntestazioneOnda {
                HStack(spacing: 14) {
                    if let coach = stato.profilo.coach {
                        AvatarCoach(coach: coach, espressione: .benvenuto, dimensione: 64)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(verbatim: nomeCoach).font(Tema.sottotitolo)
                        Text("consenso.titolo").font(Tema.titolo2)
                    }
                }
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 16) {
                        punto("sparkles", testo("consenso.ia", nomeCoach))
                        punto("lock.shield.fill", testo("consenso.dati"))
                        punto("list.bullet.rectangle.fill", testo("consenso.no"))
                        punto("slider.horizontal.3", testo("consenso.cambio"))
                    }
                    .carta(padding: 18)

                    Button { mostraInformazioni = true } label: { Text("consenso.maggioriInformazioni") }
                        .font(Tema.sottotitolo)
                        .foregroundStyle(Tema.testo)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            VStack(spacing: 10) {
                Button { stato.imposta(consensoIA: true) } label: { Text("consenso.vaBene") }
                    .buttonStyle(.primario)
                Button { stato.imposta(consensoIA: false) } label: { Text("consenso.preferiscoNo") }
                    .buttonStyle(.secondario)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .sheet(isPresented: $mostraInformazioni) {
            NavigationStack {
                InformazioniView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button { mostraInformazioni = false } label: { Text("comune.chiudi") }
                        }
                    }
            }
        }
    }

    private func punto(_ simbolo: String, _ contenuto: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: simbolo)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Tema.turchese)
                .frame(width: 30)
                .accessibilityHidden(true)
            Text(verbatim: contenuto)
                .font(Tema.corpo)
                .foregroundStyle(Tema.testo)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
