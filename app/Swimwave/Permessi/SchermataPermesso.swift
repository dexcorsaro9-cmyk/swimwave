import SwiftUI
import SwimwaveCore

/// Schermata a tutto schermo in cui il coach spiega perché serve un permesso, prima che compaia la richiesta del sistema.
/// Usata da PermessoSaluteView e PermessoNotificheView. Il pulsante principale esegue `richiedi` (che chiama il sistema)
/// e poi `onFine`; "Più tardi" chiama solo `onFine`. Nessun linguaggio colpevolizzante.
struct SchermataPermesso: View {
    @Environment(StatoApp.self) private var stato

    let espressione: EspressioneCoach
    let simbolo: String
    let titolo: String
    let frasi: [String]
    let nota: String
    let richiedi: () async -> Void
    let onFine: () -> Void

    @State private var inCorso = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    avatar
                        .padding(.top, 32)
                    Text(verbatim: titolo)
                        .font(Tema.titolo2)
                        .foregroundStyle(Tema.testo)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(frasi, id: \.self) { frase in
                            Text(verbatim: frase)
                                .font(Tema.corpo)
                                .foregroundStyle(Tema.testo)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .carta(padding: 18)
                    Text(verbatim: nota)
                        .font(Tema.piccolo)
                        .foregroundStyle(Tema.testoSecondario)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            VStack(spacing: 10) {
                Button(action: continua) { Text("permesso.continua") }
                    .buttonStyle(.primario)
                Button(action: onFine) { Text("permesso.piuTardi") }
                    .buttonStyle(.secondario)
            }
            .disabled(inCorso)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .sfondoApp()
    }

    /// Avatar del coach scelto, con l'espressione adatta; se per qualche motivo il coach non c'è, un simbolo.
    @ViewBuilder
    private var avatar: some View {
        if let coach = stato.profilo.coach {
            AvatarCoach(coach: coach, espressione: espressione, dimensione: 120)
        } else {
            Image(systemName: simbolo)
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(Tema.navy)
                .frame(width: 120, height: 120)
                .background(Circle().fill(Tema.turcheseChiaro))
                .accessibilityHidden(true)
        }
    }

    private func continua() {
        inCorso = true
        Task { @MainActor in
            await richiedi()
            inCorso = false
            onFine()
        }
    }
}
