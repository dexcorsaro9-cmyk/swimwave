import SwiftUI
import SwimwaveCore

/// Il riepilogo di un anno di nuotate: grandi numeri, mese migliore, nuotata più lunga, un paragone di distanze.
/// Solo numeri calcolati dalle nuotate dell'utente.
struct IlTuoAnnoView: View {
    @Environment(StatoApp.self) private var stato
    @State private var annoScelto: Int?

    /// Anni tra cui scegliere: quelli con nuotate, o solo l'anno corrente se non ce ne sono.
    private var anni: [Int] {
        let elenco = stato.anniConNuotate
        if elenco.isEmpty { return [Calendar.italiano.component(.year, from: Date())] }
        return elenco
    }

    private var anno: Int {
        if let a = annoScelto, anni.contains(a) { return a }
        return anni.first ?? Calendar.italiano.component(.year, from: Date())
    }

    private var sceltaAnno: Binding<Int> {
        Binding(get: { anno }, set: { annoScelto = $0 })
    }

    var body: some View {
        let r = stato.riepilogoAnno(anno)
        SchermataAnalisi {
            VStack(alignment: .leading, spacing: 6) {
                Text("anno.titolo").font(Tema.titolo2)
                Text(verbatim: String(r.anno)).font(Tema.numeroGrande)
            }
        } contenuto: {
            if anni.count > 1 {
                MenuAnalisi(
                    titolo: testo("anno.menu"),
                    opzioni: anni,
                    etichetta: { String($0) },
                    selezione: sceltaAnno
                )
            }
            if r.nuotate == 0 {
                vuoto
            }
            grandeNumero(r)
            numeri(r)
            if r.nuotate > 0 {
                meseMigliore(r)
                nuotataPiuLunga(r)
                paragoni(r)
                condividi(r)
            }
        }
    }

    // MARK: Parti

    private var vuoto: some View {
        Text("anno.vuoto")
            .font(Tema.corpo)
            .foregroundStyle(Tema.testoSecondario)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .carta(padding: 24)
    }

    /// Il numero grande, sul navy: i metri dell'anno.
    private func grandeNumero(_ r: RiepilogoAnno) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("anno.metri")
                .font(Tema.sottotitolo)
                .foregroundStyle(Tema.turcheseChiaro)
            Text(verbatim: AnalisiFormati.metri(r.metri))
                .font(Tema.numeroGrande)
                .foregroundStyle(Tema.testoSuNavy)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Tema.raggio, style: .continuous)
                .fill(LinearGradient(colors: [Tema.navy, Tema.navyChiaro],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "\(testo("anno.metri")): \(AnalisiFormati.metri(r.metri))"))
    }

    private func numeri(_ r: RiepilogoAnno) -> some View {
        let colonne = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
        return LazyVGrid(columns: colonne, alignment: .leading, spacing: 18) {
            NumeroAnalisi(valore: FormatiUI.numero(r.nuotate), etichetta: testo("anno.nuotate"), simbolo: "figure.pool.swim")
            NumeroAnalisi(valore: AnalisiFormati.durata(r.durataSecondi), etichetta: testo("anno.tempo"), simbolo: "clock.fill")
            NumeroAnalisi(valore: FormatiUI.numero(r.giorniNuotati), etichetta: testo("anno.giorni"), simbolo: "calendar")
            NumeroAnalisi(valore: FormatiUI.numero(r.settimaneConObiettivo), etichetta: testo("anno.settimane"), simbolo: "flag.fill")
        }
        .carta()
    }

    @ViewBuilder
    private func meseMigliore(_ r: RiepilogoAnno) -> some View {
        if let mese = r.meseMigliore {
            CartaAnalisi(titolo: testo("anno.meseMigliore")) {
                HStack(alignment: .firstTextBaseline) {
                    Text(verbatim: AnalisiFormati.nomeMese(mese))
                        .font(Tema.titolo2)
                        .foregroundStyle(Tema.testo)
                    Spacer(minLength: 8)
                    Text(verbatim: AnalisiFormati.metri(r.metriMeseMigliore))
                        .font(Tema.sottotitolo)
                        .foregroundStyle(Tema.testoSecondario)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    @ViewBuilder
    private func nuotataPiuLunga(_ r: RiepilogoAnno) -> some View {
        if let n = r.nuotataPiuLunga {
            CartaAnalisi(titolo: testo("anno.piuLunga")) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(verbatim: AnalisiFormati.metri(n.metri))
                            .font(Tema.titolo2)
                            .foregroundStyle(Tema.testo)
                        Text(verbatim: AnalisiFormati.dataLunga(n.data))
                            .font(Tema.piccolo)
                            .foregroundStyle(Tema.testoSecondario)
                    }
                    Spacer(minLength: 8)
                    Text(verbatim: AnalisiFormati.durata(n.durataSecondi))
                        .font(Tema.sottotitolo)
                        .foregroundStyle(Tema.testoSecondario)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    /// Paragoni fatti solo di aritmetica: un tratto di 1 km, una vasca da 50 m.
    @ViewBuilder
    private func paragoni(_ r: RiepilogoAnno) -> some View {
        let chilometri = r.metri / 1000
        let vasche = r.metri / 50
        if chilometri >= 1 || vasche >= 2 {
            CartaAnalisi(titolo: testo("anno.paragone.titolo")) {
                if chilometri == 1 {
                    Text("anno.paragone.km.una")
                        .font(Tema.corpo)
                        .foregroundStyle(Tema.testo)
                } else if chilometri > 1 {
                    Text(verbatim: testo("anno.paragone.km.molte", chilometri))
                        .font(Tema.corpo)
                        .foregroundStyle(Tema.testo)
                }
                if vasche >= 2 {
                    Text(verbatim: testo("anno.paragone.vasche", FormatiUI.numero(vasche)))
                        .font(Tema.corpo)
                        .foregroundStyle(Tema.testo)
                }
            }
        }
    }

    // MARK: Condividi

    private func condividi(_ r: RiepilogoAnno) -> some View {
        let titolo = testo("anno.carta.titolo", r.anno)
        let metri = AnalisiFormati.metri(r.metri)
        let nuotate = testo("anno.carta.nuotate", r.nuotate)
        let tempo = AnalisiFormati.durata(r.durataSecondi)
        let giorni = testo("anno.carta.giorni", r.giorniNuotati)
        let messaggio = testo("anno.condividi.testo", r.anno, metri, r.nuotate)
        let chiave = "\(r.anno)|\(r.metri)|\(r.nuotate)|\(r.durataSecondi)|\(r.giorniNuotati)"
        return PulsanteCondividiCartina(titoloAnteprima: titolo, messaggio: messaggio, chiave: chiave) {
            VStack(alignment: .leading, spacing: 8) {
                Text(verbatim: titolo)
                    .font(Tema.sottotitolo)
                    .foregroundStyle(Tema.turcheseChiaro)
                Text(verbatim: metri)
                    .font(Tema.numeroGrande)
                Text(verbatim: "\(nuotate) · \(tempo)")
                    .font(Tema.corpo)
                Text(verbatim: giorni)
                    .font(Tema.corpo)
            }
        }
        .buttonStyle(.primario)
    }
}
