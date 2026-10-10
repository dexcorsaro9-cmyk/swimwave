import SwiftUI
import SwimwaveCore

/// Fine dell'allenamento seguito sul telefono: riepilogo e domanda "Com'è andata?".
/// Se la risposta è "Dura" il coach dice una parola in un popup con un solo pulsante.
struct FineAllenamentoView: View {
    let nuotataId: UUID
    let metri: Int
    let durataSecondi: Int
    let onChiudi: () -> Void

    @Environment(StatoApp.self) private var stato
    @State private var popup: PopupCoach?

    private var selezionata: Sensazione? {
        stato.nuotate.first(where: { $0.id == nuotataId })?.sensazione
    }

    private var motivo: MotivoDifficolta? {
        stato.nuotate.first(where: { $0.id == nuotataId })?.motivoDifficolta
    }

    var body: some View {
        let profilo = stato.profilo
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    if let coach = profilo.coach {
                        AvatarCoach(coach: coach, espressione: .traguardo, dimensione: 120)
                            .padding(.top, 24)
                    }
                    Text(verbatim: testo("fine.titolo", profilo.nomePulito))
                        .font(Tema.titolo2)
                        .foregroundStyle(Tema.testo)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    riepilogo

                    VStack(spacing: 6) {
                        Text("fine.domanda")
                            .font(Tema.titolo2)
                            .foregroundStyle(Tema.testo)
                        Text("fine.nota")
                            .font(Tema.piccolo)
                            .foregroundStyle(Tema.testoSecondario)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 4)

                    SceltaSensazione(selezionata: selezionata) { s in
                        rispondi(s)
                    }

                    if selezionata == .dura {
                        SceltaMotivoDifficolta(selezionato: motivo) { m in
                            stato.imposta(motivoDifficolta: m, perNuotata: nuotataId)
                        }
                        .carta()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            Button(action: onChiudi) {
                Text("comune.fatto")
            }
            .buttonStyle(.primario)
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .sfondoApp()
        .coachPopup($popup, coach: profilo.coach) { _ in
            [PulsantePopup(titolo: testo("popup.bottone.ok"), principale: true) { popup = nil }]
        }
    }

    private var riepilogo: some View {
        HStack(spacing: 0) {
            colonna(valore: FormatiUI.numero(metri), etichetta: "fine.metri")
            colonna(valore: "\(FormatoTempo.minutiArrotondati(durataSecondi))", etichetta: "fine.minuti")
        }
        .carta()
        .accessibilityElement(children: .combine)
    }

    private func colonna(valore: String, etichetta: String) -> some View {
        VStack(spacing: 2) {
            Text(verbatim: valore)
                .font(Tema.numeroGrande)
                .foregroundStyle(Tema.testo)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(LocalizedStringKey(etichetta))
                .font(Tema.corpo)
                .foregroundStyle(Tema.testoSecondario)
        }
        .frame(maxWidth: .infinity)
    }

    private func rispondi(_ s: Sensazione) {
        let precedente = selezionata
        stato.imposta(sensazione: s, perNuotata: nuotataId)
        if s == .dura, precedente != .dura {
            popup = PopupCoach(
                momento: .dopoAllenamentoDuro,
                espressione: .dopoAllenamentoDuro,
                messaggio: testo("popup.dopoAllenamentoDuro.messaggio", stato.profilo.nomePulito)
            )
        }
    }
}
