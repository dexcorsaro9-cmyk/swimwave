import SwiftUI
import SwimwaveCore

/// Il coach spiega i promemoria del ritmo Spronami, poi compare la richiesta del sistema.
/// Si mostra una volta dopo il consenso all'IA (se il ritmo è Spronami) e quando si passa a Spronami dal Profilo.
struct PermessoNotificheView: View {
    @Environment(StatoApp.self) private var stato
    let onFine: () -> Void

    var body: some View {
        SchermataPermesso(
            espressione: .benvenuto,
            simbolo: "bell.fill",
            titolo: testo("permesso.notifiche.titolo"),
            frasi: [testo("permesso.notifiche.frase1"), testo("permesso.notifiche.frase2")],
            nota: testo("permesso.notifiche.nota"),
            richiedi: { await stato.riprogrammaPromemoria(chiediPermesso: true) },
            onFine: onFine
        )
    }
}
