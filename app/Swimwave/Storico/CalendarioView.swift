import SwiftUI
import SwimwaveCore

/// Il calendario del mese: i giorni con nuotate sono cerchi turchesi (più metri, colore più pieno),
/// oggi ha il bordo corallo. Toccando un giorno con nuotate sotto la griglia compare l'elenco di quel giorno.
/// Si usa dentro lo Storico (che ha già il NavigationStack e lo scorrimento).
struct CalendarioView: View {
    @Environment(StatoApp.self) private var stato
    @State private var mese: Date = CalendarioView.inizioMese(Date())
    @State private var giornoScelto: Date?

    private static func inizioMese(_ data: Date) -> Date {
        Calendar.italiano.dateInterval(of: .month, for: data)?.start ?? data
    }

    private let colonne = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        let celle = stato.celleCalendario(mese: mese)
        let piuMetri = celle.map(\.metri).max() ?? 0
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 12) {
                barraMese
                totale(celle)
                LazyVGrid(columns: colonne, spacing: 6) {
                    ForEach(Array(FormatiStorico.inizialiGiorni.enumerated()), id: \.offset) { _, lettera in
                        Text(verbatim: lettera)
                            .font(Tema.piccolo.weight(.bold))
                            .foregroundStyle(Tema.testoSecondario)
                            .accessibilityHidden(true)
                    }
                    ForEach(Array(celle.enumerated()), id: \.offset) { _, cella in
                        cellaGiorno(cella, piuMetri: piuMetri)
                    }
                }
            }
            .carta()

            if let giorno = giornoScelto {
                elencoGiorno(giorno)
            }
        }
    }

    // MARK: Mese

    private var barraMese: some View {
        HStack {
            Button {
                cambiaMese(di: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .frame(width: 44, height: 44)
            }
            .disabled(!puoiAndareIndietro)
            .accessibilityLabel(Text("calendario.mesePrecedente"))

            Spacer(minLength: 0)
            Text(verbatim: FormatiStorico.meseAnno(mese))
                .font(Tema.sottotitolo)
                .foregroundStyle(Tema.testo)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 0)

            Button {
                cambiaMese(di: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .frame(width: 44, height: 44)
            }
            .disabled(!puoiAndareAvanti)
            .accessibilityLabel(Text("calendario.meseSuccessivo"))
        }
        .foregroundStyle(Tema.testo)
    }

    /// Non si va oltre il mese corrente.
    private var puoiAndareAvanti: Bool {
        mese < CalendarioView.inizioMese(Date())
    }

    /// Non si va prima del mese della nuotata più vecchia (senza nuotate, non si va prima del mese corrente).
    private var puoiAndareIndietro: Bool {
        let primo = stato.nuotate.map(\.data).min() ?? Date()
        return mese > CalendarioView.inizioMese(primo)
    }

    private func cambiaMese(di passo: Int) {
        guard let nuovo = Calendar.italiano.date(byAdding: .month, value: passo, to: mese) else { return }
        let inizio = CalendarioView.inizioMese(nuovo)
        if inizio > CalendarioView.inizioMese(Date()) { return }
        mese = inizio
        giornoScelto = nil
    }

    private func totale(_ celle: [CellaCalendario]) -> some View {
        let nuotate = celle.reduce(0) { $0 + $1.nuotate }
        let metri = celle.reduce(0) { $0 + $1.metri }
        let riga: String
        if nuotate == 0 {
            riga = testo("calendario.totale.nessuna")
        } else if nuotate == 1 {
            riga = testo("calendario.totale.una", FormatiUI.numero(metri))
        } else {
            riga = testo("calendario.totale.altre", nuotate, FormatiUI.numero(metri))
        }
        return Text(verbatim: riga)
            .font(Tema.corpo)
            .foregroundStyle(Tema.testoSecondario)
    }

    // MARK: Celle

    @ViewBuilder
    private func cellaGiorno(_ cella: CellaCalendario, piuMetri: Int) -> some View {
        if let giorno = cella.giorno, let data = cella.data {
            let oggi = Calendar.italiano.isDateInToday(data)
            let scelto = giornoScelto.map { Calendar.italiano.isDate($0, inSameDayAs: data) } ?? false
            if cella.nuotate > 0 {
                Button {
                    giornoScelto = scelto ? nil : data
                } label: {
                    disco(giorno: giorno, livello: livello(metri: cella.metri, piuMetri: piuMetri), oggi: oggi, scelto: scelto)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(verbatim: etichetta(cella, data: data, oggi: oggi)))
                .accessibilityAddTraits(scelto ? .isSelected : [])
            } else {
                disco(giorno: giorno, livello: 0, oggi: oggi, scelto: false)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(verbatim: etichetta(cella, data: data, oggi: oggi)))
            }
        } else {
            Color.clear.frame(height: 40)
                .accessibilityHidden(true)
        }
    }

    private func disco(giorno: Int, livello: Int, oggi: Bool, scelto: Bool) -> some View {
        ZStack {
            if livello > 0 {
                Circle().fill(Tema.turchese.opacity(opacita(livello)))
            }
            if scelto {
                Circle().strokeBorder(Tema.testo, lineWidth: 2).padding(4)
            }
            if oggi {
                Circle().strokeBorder(Tema.corallo, lineWidth: 3)
            }
            Text(verbatim: "\(giorno)")
                .font(Tema.piccolo.weight(livello > 0 ? .bold : .regular))
                .foregroundStyle(livello == 3 ? Tema.navy : Tema.testo)
        }
        .frame(height: 40)
        .frame(maxWidth: 40)
        .frame(maxWidth: .infinity)
    }

    /// Tre livelli semplici in base ai metri del giorno rispetto al giorno più lungo del mese: 1, 2 o 3.
    private func livello(metri: Int, piuMetri: Int) -> Int {
        guard piuMetri > 0 else { return 1 }
        let quota = Double(metri) / Double(piuMetri)
        if quota <= 1.0 / 3.0 { return 1 }
        if quota <= 2.0 / 3.0 { return 2 }
        return 3
    }

    private func opacita(_ livello: Int) -> Double {
        switch livello {
        case 1: return 0.3
        case 2: return 0.6
        default: return 1.0
        }
    }

    private func etichetta(_ cella: CellaCalendario, data: Date, oggi: Bool) -> String {
        let giorno = FormatiStorico.giornoMeseLungo(data)
        var testoEtichetta: String
        if cella.nuotate == 0 {
            testoEtichetta = giorno
        } else if cella.nuotate == 1 {
            testoEtichetta = testo("calendario.cella.una", giorno)
        } else {
            testoEtichetta = testo("calendario.cella.altre", giorno, cella.nuotate)
        }
        if oggi {
            testoEtichetta += ", " + testo("calendario.oggi")
        }
        return testoEtichetta
    }

    // MARK: Nuotate del giorno

    private func elencoGiorno(_ giorno: Date) -> some View {
        let cal = Calendar.italiano
        let delGiorno = stato.nuotate
            .filter { cal.isDate($0.data, inSameDayAs: giorno) }
            .sorted { $0.data > $1.data }
        return VStack(alignment: .leading, spacing: 10) {
            Text(verbatim: FormatiStorico.dataLunga(giorno))
                .font(Tema.sottotitolo)
                .foregroundStyle(Tema.testoSecondario)
                .padding(.top, 4)
                .accessibilityAddTraits(.isHeader)
            ForEach(delGiorno) { n in
                NavigationLink {
                    DettaglioNuotataView(nuotata: n)
                } label: {
                    RigaNuotata(nuotata: n)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
