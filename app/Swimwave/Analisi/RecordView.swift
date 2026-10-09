import SwiftUI
import SwimwaveCore

/// I record personali e i migliori tempi, calcolati dalle nuotate dell'utente.
/// Il ritmo migliore è un ritmo MEDIO di tutta la nuotata; i migliori tempi non sono tempi ufficiali.
struct RecordView: View {
    @Environment(StatoApp.self) private var stato

    var body: some View {
        let r = stato.records
        SchermataAnalisi {
            VStack(alignment: .leading, spacing: 4) {
                Text("record.titolo").font(Tema.titolo2)
                Text("record.sottotitolo").font(Tema.corpo).opacity(0.9)
            }
        } contenuto: {
            if r.nuotateTotali == 0 {
                vuoto
            } else {
                recordPersonali(r)
                totali(r)
                if r.tempo200 != nil || r.tempo400 != nil {
                    testRitmo(r)
                }
            }
            miglioriTempi
        }
    }

    // MARK: Parti

    private var vuoto: some View {
        VStack(spacing: 10) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(Tema.corallo)
                .accessibilityHidden(true)
            Text("record.vuoto")
                .font(Tema.corpo)
                .foregroundStyle(Tema.testoSecondario)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .carta(padding: 24)
    }

    @ViewBuilder
    private func recordPersonali(_ r: RecordPersonali) -> some View {
        if let n = r.nuotataPiuLunga {
            NavigationLink {
                DettaglioNuotataView(nuotata: n)
            } label: {
                rigaRecord(
                    titolo: testo("record.piuLunga"),
                    valore: AnalisiFormati.metri(n.metri),
                    dettaglio: AnalisiFormati.dataLunga(n.data),
                    simbolo: "figure.pool.swim",
                    tocca: true
                )
            }
            .buttonStyle(.plain)
        }
        if let n = r.ritmoMigliore, let ritmo = n.ritmoPer100Secondi {
            NavigationLink {
                DettaglioNuotataView(nuotata: n)
            } label: {
                rigaRecord(
                    titolo: testo("record.ritmo"),
                    valore: AnalisiFormati.ritmo(ritmo),
                    dettaglio: testo("record.ritmo.nota") + " · " + AnalisiFormati.dataLunga(n.data),
                    simbolo: "speedometer",
                    tocca: true
                )
            }
            .buttonStyle(.plain)
        }
        if let s = r.settimanaPiuLunga {
            rigaRecord(
                titolo: testo("record.settimana"),
                valore: AnalisiFormati.metri(s.metri),
                dettaglio: testo("record.settimana.dettaglio", FormatiUI.giornoMese(s.inizio), s.nuotate),
                simbolo: "calendar",
                tocca: false
            )
        }
        if r.serieMassimaSettimane > 0 {
            rigaRecord(
                titolo: testo("record.serie"),
                valore: testo("record.serie.valore", r.serieMassimaSettimane),
                dettaglio: nil,
                simbolo: "flame.fill",
                tocca: false
            )
        }
    }

    private func totali(_ r: RecordPersonali) -> some View {
        CartaAnalisi(titolo: testo("record.totali")) {
            HStack(alignment: .top, spacing: 12) {
                NumeroAnalisi(valore: FormatiUI.numero(r.nuotateTotali), etichetta: testo("record.totali.nuotate"))
                NumeroAnalisi(valore: AnalisiFormati.metri(r.metriTotali), etichetta: testo("record.totali.metri"))
            }
        }
    }

    private func testRitmo(_ r: RecordPersonali) -> some View {
        CartaAnalisi(titolo: testo("record.test")) {
            HStack(alignment: .top, spacing: 12) {
                if let t = r.tempo200 {
                    NumeroAnalisi(valore: FormatoTempo.mmss(t), etichetta: testo("record.test.200"))
                }
                if let t = r.tempo400 {
                    NumeroAnalisi(valore: FormatoTempo.mmss(t), etichetta: testo("record.test.400"))
                }
            }
        }
    }

    // MARK: Migliori tempi

    private var miglioriTempi: some View {
        let tempi = stato.miglioriTempi
        return CartaAnalisi(titolo: testo("record.tempi.titolo")) {
            if tempi.isEmpty {
                Text("record.tempi.vuoto")
                    .font(Tema.corpo)
                    .foregroundStyle(Tema.testoSecondario)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(tempi, id: \.distanzaMetri) { tempo in
                    rigaTempo(tempo)
                }
            }
            Text("record.tempi.nota")
                .font(Tema.piccolo)
                .foregroundStyle(Tema.testoSecondario)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func rigaTempo(_ t: MigliorTempo) -> some View {
        let riga = HStack(alignment: .firstTextBaseline, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: AnalisiFormati.metri(t.distanzaMetri))
                    .font(Tema.sottotitolo)
                    .foregroundStyle(Tema.testo)
                Text(verbatim: AnalisiFormati.dataLunga(t.data))
                    .font(Tema.piccolo)
                    .foregroundStyle(Tema.testoSecondario)
            }
            Spacer(minLength: 8)
            Text(verbatim: FormatoRitmo.minutiSecondi(t.secondi))
                .font(Tema.titolo2)
                .foregroundStyle(Tema.testo)
        }
        if let nuotata = stato.nuotate.first(where: { $0.id == t.nuotataId }) {
            NavigationLink {
                DettaglioNuotataView(nuotata: nuotata)
            } label: {
                HStack(spacing: 8) {
                    riga
                    Image(systemName: "chevron.right")
                        .font(.system(.footnote, design: .rounded).weight(.bold))
                        .foregroundStyle(Tema.testoSecondario)
                        .accessibilityHidden(true)
                }
            }
            .buttonStyle(.plain)
        } else {
            riga
        }
    }

    // MARK: Riga

    private func rigaRecord(titolo: String, valore: String, dettaglio: String?, simbolo: String, tocca: Bool) -> some View {
        HStack(spacing: 14) {
            Image(systemName: simbolo)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(Tema.navy)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Tema.turcheseChiaro))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: titolo)
                    .font(Tema.piccolo)
                    .foregroundStyle(Tema.testoSecondario)
                Text(verbatim: valore)
                    .font(Tema.titolo2)
                    .foregroundStyle(Tema.testo)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if let dettaglio {
                    Text(verbatim: dettaglio)
                        .font(Tema.piccolo)
                        .foregroundStyle(Tema.testoSecondario)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 8)
            if tocca {
                Image(systemName: "chevron.right")
                    .font(.system(.footnote, design: .rounded).weight(.bold))
                    .foregroundStyle(Tema.testoSecondario)
                    .accessibilityHidden(true)
            }
        }
        .carta()
        .accessibilityElement(children: .combine)
    }
}
