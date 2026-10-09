import SwiftUI
import UIKit

// Condivisione di una carta come immagine. La carta ha sempre lo stesso aspetto (navy, testo chiaro, riga "Swimwave"),
// senza il nome dell'utente, e non dipende dal tema chiaro/scuro.

/// Disegna una vista in un'immagine (3x). Nil se il disegno non riesce.
/// La vista disegnata NON eredita l'ambiente (per esempio `StatoApp`): deve contenere solo valori già pronti.
@MainActor
func immagineDaCondividere<V: View>(_ vista: V) -> Image? {
    let renderer = ImageRenderer(content: vista)
    renderer.scale = 3
    guard let immagine = renderer.uiImage else { return nil }
    return Image(uiImage: immagine)
}

/// Cornice della carta condivisa: sfondo navy, testo chiaro, in basso la riga "Swimwave". Larghezza fissa.
struct CarticinaCondivisibile<Contenuto: View>: View {
    private let contenuto: Contenuto

    init(@ViewBuilder contenuto: () -> Contenuto) {
        self.contenuto = contenuto()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            contenuto
            HStack(spacing: 6) {
                Image(systemName: "figure.pool.swim")
                Text(verbatim: "Swimwave")
            }
            .font(Tema.sottotitolo)
            .foregroundStyle(Tema.turcheseChiaro)
        }
        .foregroundStyle(Tema.testoSuNavy)
        .padding(24)
        .frame(width: 360, alignment: .leading)
        .background(
            LinearGradient(colors: [Tema.navy, Tema.navyChiaro],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
    }
}

/// Pulsante "Condividi": prepara l'immagine della carta e apre il foglio di condivisione di sistema.
/// Se l'immagine non si riesce a preparare, condivide solo il testo. Lo stile del pulsante si dà da fuori
/// (`.buttonStyle(.primario)` o `.secondario`).
struct PulsanteCondividiCartina<Contenuto: View>: View {
    /// Titolo dell'anteprima nel foglio di condivisione.
    let titoloAnteprima: String
    /// Testo che accompagna l'immagine (alcune app lo ignorano).
    let messaggio: String
    /// Cambia quando cambia il contenuto della carta: l'immagine si prepara di nuovo.
    let chiave: String
    private let contenuto: () -> Contenuto
    @State private var immagine: Image?

    init(titoloAnteprima: String, messaggio: String, chiave: String,
         @ViewBuilder contenuto: @escaping () -> Contenuto) {
        self.titoloAnteprima = titoloAnteprima
        self.messaggio = messaggio
        self.chiave = chiave
        self.contenuto = contenuto
    }

    var body: some View {
        Group {
            if let immagine {
                ShareLink(item: immagine, message: Text(verbatim: messaggio),
                          preview: SharePreview(titoloAnteprima, image: immagine)) {
                    etichetta
                }
            } else {
                ShareLink(item: messaggio) {
                    etichetta
                }
            }
        }
        .task(id: chiave) {
            await prepara()
        }
    }

    private var etichetta: some View {
        HStack(spacing: 8) {
            Image(systemName: "square.and.arrow.up")
            Text("riepilogo.condividi")
        }
    }

    @MainActor
    private func prepara() async {
        immagine = immagineDaCondividere(CarticinaCondivisibile(contenuto: contenuto))
    }
}
