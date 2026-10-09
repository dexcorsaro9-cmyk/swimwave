import SwiftUI
import SwimwaveCore

/// Il coach spiega perché legge le nuotate da Apple Salute, poi compare la richiesta del sistema.
/// Si mostra dalla schermata Oggi (la prima volta) e dal Profilo, se `!stato.permessoSaluteChiesto`.
struct PermessoSaluteView: View {
    @Environment(StatoApp.self) private var stato
    let onFine: () -> Void

    var body: some View {
        SchermataPermesso(
            espressione: .incoraggiamento,
            simbolo: "heart.fill",
            titolo: testo("permesso.salute.titolo"),
            frasi: [testo("permesso.salute.frase1"), testo("permesso.salute.frase2")],
            nota: testo("permesso.salute.nota"),
            richiedi: { await stato.importaDaSalute(chiediPermesso: true) },
            onFine: onFine
        )
    }
}
