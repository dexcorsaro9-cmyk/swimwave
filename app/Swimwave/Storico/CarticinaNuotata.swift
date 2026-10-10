import SwiftUI
import SwimwaveCore

/// La carta da condividere come immagine (vedi `immagineDaCondividere` in Analisi/Condividi.swift).
/// Larghezza fissa 340 pt e aspetto fisso (navy con testo chiaro), uguale in tema chiaro e scuro.
/// Font a misura fissa: l'immagine non cambia con la dimensione del testo scelta sul telefono.
/// Niente nome dell'utente, niente coach.
struct CarticinaNuotata: View {
    let nuotata: NuotataCompletata

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: FormatiStorico.titolo(nuotata))
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .lineLimit(2)
                Text(verbatim: FormatiStorico.dataLunga(nuotata.data))
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .opacity(0.85)
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(verbatim: FormatiUI.numero(nuotata.metri))
                    .font(.system(size: 68, weight: .heavy, design: .rounded))
                    .foregroundStyle(Tema.turcheseChiaro)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text("condividi.unita.metri")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(Tema.turcheseChiaro)
            }

            HStack(alignment: .top, spacing: 24) {
                voce(valore: FormatoTempo.mmss(nuotata.durataSecondi), etichetta: "condividi.tempo")
                if let r = nuotata.ritmoPer100Secondi {
                    voce(valore: FormatoRitmo.minutiSecondi(r), etichetta: "condividi.ritmo")
                }
                if nuotata.ambiente != .acqueLibere, let v = nuotata.vascaMetri, v > 0 {
                    voce(valore: "\(v) m", etichetta: "condividi.vasca")
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "water.waves")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Tema.turcheseChiaro)
                Text(verbatim: "Swimwave")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                Spacer(minLength: 0)
            }
            .padding(.top, 4)
        }
        .foregroundStyle(Tema.testoSuNavy)
        .padding(24)
        .frame(width: 340, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(LinearGradient(colors: [Tema.navy, Tema.navyChiaro],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
        )
    }

    private func voce(valore: String, etichetta: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: valore)
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(LocalizedStringKey(etichetta))
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .opacity(0.85)
        }
    }
}

#Preview("Carticina") {
    CarticinaNuotata(nuotata: NuotataCompletata(
        data: Date(), metri: 800, durataSecondi: 1450, titolo: "Resistenza facile"
    ))
    .padding()
}
