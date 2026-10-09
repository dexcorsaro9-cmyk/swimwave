import SwiftUI
import SwimwaveCore

// Formati e piccoli componenti condivisi dalle schermate di analisi (Andamento, Riepilogo, Il tuo anno, Record, Traguardi).
// I testi vengono tutti da Localizable.xcstrings; nomi di mesi e giorni sempre in italiano.

enum AnalisiFormati {
    static let locale = Locale(identifier: "it_IT")

    private static let nomiMesi: [String] = {
        let f = DateFormatter()
        f.locale = locale
        return f.standaloneMonthSymbols ?? []
    }()

    private static let giorniBreviDaDomenica: [String] = {
        let f = DateFormatter()
        f.locale = locale
        return f.shortStandaloneWeekdaySymbols ?? []
    }()

    private static let meseBreveFormato: DateFormatter = {
        let f = DateFormatter()
        f.locale = locale
        f.setLocalizedDateFormatFromTemplate("MMM")
        return f
    }()

    private static let dataLungaFormato: DateFormatter = {
        let f = DateFormatter()
        f.locale = locale
        f.setLocalizedDateFormatFromTemplate("dMMMMyyyy")
        return f
    }()

    /// Nome del mese, 1...12, con l'iniziale maiuscola: "Ottobre". Stringa vuota se il numero non è valido.
    static func nomeMese(_ mese: Int) -> String {
        guard mese >= 1, mese <= nomiMesi.count else { return "" }
        return maiuscola(nomiMesi[mese - 1])
    }

    /// "Ottobre 2026"
    static func meseEAnno(_ data: Date) -> String {
        let c = Calendar.italiano
        return "\(nomeMese(c.component(.month, from: data))) \(c.component(.year, from: data))"
    }

    /// Giorni della settimana abbreviati, dal lunedì: "lun", "mar", ... (la settimana italiana comincia il lunedì).
    static var giorniBrevi: [String] {
        guard giorniBreviDaDomenica.count == 7 else { return ["", "", "", "", "", "", ""] }
        return (0..<7).map { giorniBreviDaDomenica[($0 + 1) % 7] }
    }

    /// "ott"
    static func meseBreve(_ data: Date) -> String {
        meseBreveFormato.string(from: data)
    }

    /// "9 ottobre 2026"
    static func dataLunga(_ data: Date) -> String {
        dataLungaFormato.string(from: data)
    }

    private static func maiuscola(_ s: String) -> String {
        guard let primo = s.first else { return s }
        return String(primo).uppercased() + String(s.dropFirst())
    }

    // MARK: Numeri con unità

    /// "4.200 m"
    static func metri(_ m: Int) -> String {
        testo("riepilogo.unita.metri", FormatiUI.numero(m))
    }

    /// "1:35 / 100 m"
    static func ritmo(_ secondiPer100: Double) -> String {
        testo("riepilogo.unita.ritmo", FormatoRitmo.minutiSecondi(secondiPer100))
    }

    /// "45 min", "2 h", "2 h 15 min" (minuti arrotondati).
    static func durata(_ secondi: Int) -> String {
        let totale = FormatoTempo.minutiArrotondati(secondi)
        let ore = totale / 60
        let minuti = totale % 60
        if ore == 0 { return testo("riepilogo.durata.minuti", minuti) }
        if minuti == 0 { return testo("riepilogo.durata.ore", ore) }
        return testo("riepilogo.durata.oreMinuti", ore, minuti)
    }

    /// Differenza con il segno: "+3", "-2", "0". Il testo dopo il numero (per esempio " m") si aggiunge fuori.
    static func segno(_ differenza: Int) -> String {
        if differenza > 0 { return "+" }
        if differenza < 0 { return "-" }
        return ""
    }
}

/// Un numero con la sua etichetta, per le righe di riepilogo.
struct NumeroAnalisi: View {
    let valore: String
    let etichetta: String
    var simbolo: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let simbolo {
                Image(systemName: simbolo)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(Tema.turchese)
                    .accessibilityHidden(true)
            }
            Text(verbatim: valore)
                .font(Tema.titolo2)
                .foregroundStyle(Tema.testo)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(verbatim: etichetta)
                .font(Tema.piccolo)
                .foregroundStyle(Tema.testoSecondario)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "\(etichetta): \(valore)"))
    }
}

/// Menu a tendina nello stile di `MenuScelta`, ma con un valore sempre scelto (niente "Scegli").
struct MenuAnalisi<Valore: Hashable>: View {
    let titolo: String
    let opzioni: [Valore]
    let etichetta: (Valore) -> String
    @Binding var selezione: Valore

    var body: some View {
        Picker(titolo, selection: $selezione) {
            ForEach(opzioni, id: \.self) { opzione in
                Text(verbatim: etichetta(opzione)).tag(opzione)
            }
        }
        .pickerStyle(.menu)
        .labelsHidden()
        .tint(Tema.testo)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Tema.turchese, lineWidth: 2)
        )
        .accessibilityLabel(Text(verbatim: titolo))
    }
}

/// Schermata di analisi: intestazione a onda e, sotto, le carte. Per le schermate raggiunte con un `NavigationLink`.
struct SchermataAnalisi<Intestazione: View, Contenuto: View>: View {
    private let intestazione: Intestazione
    private let contenuto: Contenuto

    init(@ViewBuilder intestazione: () -> Intestazione, @ViewBuilder contenuto: () -> Contenuto) {
        self.intestazione = intestazione()
        self.contenuto = contenuto()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                IntestazioneOnda {
                    intestazione
                }
                VStack(spacing: 12) {
                    contenuto
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .sfondoApp()
        // Il titolo sta nell'intestazione; la barra serve solo per tornare indietro.
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }
}

/// Carta con un titolo di sezione.
struct CartaAnalisi<Contenuto: View>: View {
    let titolo: String?
    private let contenuto: Contenuto

    init(titolo: String? = nil, @ViewBuilder contenuto: () -> Contenuto) {
        self.titolo = titolo
        self.contenuto = contenuto()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let titolo {
                Text(verbatim: titolo)
                    .font(Tema.sottotitolo)
                    .foregroundStyle(Tema.testo)
                    .accessibilityAddTraits(.isHeader)
            }
            contenuto
        }
        .carta()
    }
}
