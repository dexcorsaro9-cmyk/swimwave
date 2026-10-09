import SwiftUI
import Charts
import SwimwaveCore

private enum VistaRiepilogo: CaseIterable, Hashable {
    case settimana, mese

    var periodo: PeriodoRiepilogo { self == .settimana ? .settimana : .mese }
    var componente: Calendar.Component { self == .settimana ? .weekOfYear : .month }
}

private struct BarraRiepilogo: Identifiable {
    let id: Int
    let etichetta: String
    let metri: Int
}

/// Numeri di un periodo (una settimana o un mese).
private struct DatiPeriodo {
    var nuotate: [NuotataCompletata]
    var somma: SommaPeriodo
    var giorniNuotati: Int
    /// Secondi ogni 100 m su tutto il periodo; nil se non ci sono metri.
    var ritmo: Double?

    init(_ nuotate: [NuotataCompletata], calendario: Calendar) {
        self.nuotate = nuotate
        let s = Riepiloghi.somma(nuotate)
        self.somma = s
        self.giorniNuotati = Set(nuotate.map { calendario.startOfDay(for: $0.data) }).count
        self.ritmo = s.metri > 0 ? Double(s.durataSecondi) / Double(s.metri) * 100.0 : nil
    }
}

/// Riepilogo della settimana o del mese: numeri, confronto neutro con il periodo prima, grafico,
/// obiettivo mensile di metri e commento del coach.
struct RiepilogoView: View {
    @Environment(StatoApp.self) private var stato
    @State private var vista: VistaRiepilogo = .settimana
    @State private var commento: String?

    var body: some View {
        let calendario = Calendar.italiano
        let oggi = Date()
        let attuale = DatiPeriodo(
            Riepiloghi.filtra(stato.nuotate, periodo: vista.periodo, rispetto: oggi, calendar: calendario),
            calendario: calendario
        )
        let precedente = DatiPeriodo(
            Riepiloghi.filtra(stato.nuotate, periodo: vista.periodo, rispetto: dataDelPeriodoPrecedente(oggi, calendario), calendar: calendario),
            calendario: calendario
        )

        SchermataAnalisi {
            VStack(alignment: .leading, spacing: 4) {
                Text("riepilogo.titolo").font(Tema.titolo2)
                Text(verbatim: sottotitolo(oggi: oggi, calendario: calendario))
                    .font(Tema.corpo)
                    .opacity(0.9)
            }
        } contenuto: {
            selettore
            numeri(attuale)
            confronto(attuale: attuale, precedente: precedente)
            grafico(attuale, oggi: oggi, calendario: calendario)
            obiettivoMensile
            cartaCoach
            if attuale.somma.nuotate > 0 {
                condividi(attuale)
            }
        }
        .task(id: stato.nuotate.count) {
            commento = await stato.commentoMese()
        }
    }

    // MARK: Periodi

    /// Una data che cade nel periodo prima di quello che contiene `oggi`.
    private func dataDelPeriodoPrecedente(_ oggi: Date, _ calendario: Calendar) -> Date {
        let inizio = calendario.dateInterval(of: vista.componente, for: oggi)?.start ?? oggi
        return calendario.date(byAdding: vista.componente, value: -1, to: inizio) ?? inizio
    }

    private func sottotitolo(oggi: Date, calendario: Calendar) -> String {
        switch vista {
        case .settimana:
            let inizio = calendario.dateInterval(of: .weekOfYear, for: oggi)?.start ?? oggi
            return testo("riepilogo.sottotitolo.settimana", FormatiUI.giornoMese(inizio))
        case .mese:
            return AnalisiFormati.meseEAnno(oggi)
        }
    }

    // MARK: Selettore e numeri

    private var selettore: some View {
        Picker(selection: $vista) {
            Text("riepilogo.vista.settimana").tag(VistaRiepilogo.settimana)
            Text("riepilogo.vista.mese").tag(VistaRiepilogo.mese)
        } label: {
            Text("riepilogo.vista.titolo")
        }
        .pickerStyle(.segmented)
    }

    private func numeri(_ d: DatiPeriodo) -> some View {
        let colonne = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
        return LazyVGrid(columns: colonne, alignment: .leading, spacing: 18) {
            NumeroAnalisi(valore: FormatiUI.numero(d.somma.nuotate), etichetta: testo("riepilogo.nuotate"), simbolo: "figure.pool.swim")
            NumeroAnalisi(valore: AnalisiFormati.metri(d.somma.metri), etichetta: testo("riepilogo.metri"), simbolo: "drop.fill")
            NumeroAnalisi(valore: AnalisiFormati.durata(d.somma.durataSecondi), etichetta: testo("riepilogo.tempo"), simbolo: "clock.fill")
            NumeroAnalisi(valore: d.ritmo.map { AnalisiFormati.ritmo($0) } ?? "–", etichetta: testo("riepilogo.ritmo"), simbolo: "speedometer")
            NumeroAnalisi(valore: FormatiUI.numero(d.giorniNuotati), etichetta: testo("riepilogo.giorni"), simbolo: "calendar")
        }
        .carta()
    }

    // MARK: Confronto

    private func confronto(attuale: DatiPeriodo, precedente: DatiPeriodo) -> some View {
        let titolo = testo(vista == .settimana ? "riepilogo.confronto.settimana" : "riepilogo.confronto.mese")
        let minutiAttuali = FormatoTempo.minutiArrotondati(attuale.somma.durataSecondi)
        let minutiPrima = FormatoTempo.minutiArrotondati(precedente.somma.durataSecondi)
        return CartaAnalisi(titolo: titolo) {
            rigaConfronto(
                etichetta: testo("riepilogo.nuotate"),
                differenza: attuale.somma.nuotate - precedente.somma.nuotate,
                testoDifferenza: { FormatiUI.numero(abs($0)) },
                prima: FormatiUI.numero(precedente.somma.nuotate)
            )
            rigaConfronto(
                etichetta: testo("riepilogo.metri"),
                differenza: attuale.somma.metri - precedente.somma.metri,
                testoDifferenza: { AnalisiFormati.metri(abs($0)) },
                prima: AnalisiFormati.metri(precedente.somma.metri)
            )
            rigaConfronto(
                etichetta: testo("riepilogo.tempo"),
                differenza: minutiAttuali - minutiPrima,
                testoDifferenza: { testo("riepilogo.durata.minuti", abs($0)) },
                prima: AnalisiFormati.durata(precedente.somma.durataSecondi)
            )
        }
    }

    /// Una freccia e un numero, sempre nello stesso colore: nessun giudizio su salita o discesa.
    private func rigaConfronto(
        etichetta: String, differenza: Int, testoDifferenza: (Int) -> String, prima: String
    ) -> some View {
        let simbolo: String
        if differenza > 0 {
            simbolo = "arrow.up"
        } else if differenza < 0 {
            simbolo = "arrow.down"
        } else {
            simbolo = "minus"
        }
        let valore = differenza == 0 ? "0" : AnalisiFormati.segno(differenza) + testoDifferenza(differenza)
        return HStack(spacing: 10) {
            Image(systemName: simbolo)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(Tema.turchese)
                .frame(width: 24)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: etichetta)
                    .font(Tema.corpo)
                    .foregroundStyle(Tema.testo)
                Text(verbatim: testo("riepilogo.confronto.prima", prima))
                    .font(Tema.piccolo)
                    .foregroundStyle(Tema.testoSecondario)
            }
            Spacer(minLength: 8)
            Text(verbatim: valore)
                .font(Tema.sottotitolo)
                .foregroundStyle(Tema.testo)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "\(etichetta): \(valore), \(testo("riepilogo.confronto.prima", prima))"))
    }

    // MARK: Grafico

    private func grafico(_ d: DatiPeriodo, oggi: Date, calendario: Calendar) -> some View {
        let barre = vista == .settimana
            ? barrePerGiorno(d.nuotate, calendario: calendario)
            : barrePerSettimana(d.nuotate, oggi: oggi, calendario: calendario)
        let titolo = testo(vista == .settimana ? "riepilogo.grafico.giorni" : "riepilogo.grafico.settimane")
        return CartaAnalisi(titolo: titolo) {
            Chart(barre) { barra in
                BarMark(
                    x: .value("Periodo", barra.etichetta),
                    y: .value("Metri", barra.metri)
                )
                .foregroundStyle(Tema.turchese)
            }
            .frame(height: 180)
            .accessibilityLabel(Text(verbatim: testo("riepilogo.grafico.accessibilita", FormatiUI.numero(d.somma.metri))))
        }
    }

    /// Metri per ciascun giorno della settimana (lunedì ... domenica).
    private func barrePerGiorno(_ nuotate: [NuotataCompletata], calendario: Calendar) -> [BarraRiepilogo] {
        var metri = [Int](repeating: 0, count: 7)
        for n in nuotate {
            let giorno = (calendario.component(.weekday, from: n.data) - calendario.firstWeekday + 7) % 7
            if giorno >= 0 && giorno < 7 { metri[giorno] += n.metri }
        }
        let nomi = AnalisiFormati.giorniBrevi
        return (0..<7).map { BarraRiepilogo(id: $0, etichetta: nomi[$0], metri: metri[$0]) }
    }

    /// Metri per ciascuna settimana che tocca il mese (contano solo le nuotate del mese).
    private func barrePerSettimana(_ nuotate: [NuotataCompletata], oggi: Date, calendario: Calendar) -> [BarraRiepilogo] {
        guard let mese = calendario.dateInterval(of: .month, for: oggi) else { return [] }
        var inizio = calendario.dateInterval(of: .weekOfYear, for: mese.start)?.start ?? mese.start
        var risultato: [BarraRiepilogo] = []
        var conta = 0
        while inizio < mese.end && conta < 8 {
            guard let prossima = calendario.date(byAdding: .weekOfYear, value: 1, to: inizio) else { break }
            let da = inizio
            let metri = nuotate.filter { $0.data >= da && $0.data < prossima }.reduce(0) { $0 + $1.metri }
            risultato.append(BarraRiepilogo(id: conta, etichetta: FormatiUI.giornoMese(da), metri: metri))
            inizio = prossima
            conta += 1
        }
        return risultato
    }

    // MARK: Obiettivo mensile

    private var sceltaObiettivo: Binding<Int?> {
        Binding(
            get: { stato.obiettivoMensileMetri },
            set: { stato.imposta(obiettivoMensile: $0) }
        )
    }

    private var opzioniObiettivo: [Int?] {
        var opzioni: [Int?] = [nil]
        opzioni.append(contentsOf: ObiettivoMensile.proposte.map { Optional($0) })
        // Un obiettivo impostato altrove, che non è tra le proposte, resta visibile nel menu.
        if let corrente = stato.obiettivoMensileMetri, !ObiettivoMensile.proposte.contains(corrente) {
            opzioni.append(corrente)
        }
        return opzioni
    }

    private var obiettivoMensile: some View {
        CartaAnalisi(titolo: testo("mensile.titolo")) {
            if let p = stato.progressoMensile {
                Text(verbatim: testo("mensile.avanzamento", FormatiUI.numero(p.metri), AnalisiFormati.metri(p.obiettivo)))
                    .font(Tema.corpo)
                    .foregroundStyle(Tema.testo)
                BarraAvanzamento(frazione: p.frazione, colore: p.raggiunto ? Tema.corallo : Tema.turchese)
                Text(verbatim: p.raggiunto
                     ? testo("mensile.raggiunto")
                     : testo("mensile.mancano", AnalisiFormati.metri(p.mancano)))
                    .font(Tema.piccolo)
                    .foregroundStyle(Tema.testoSecondario)
            } else {
                Text("mensile.invito")
                    .font(Tema.corpo)
                    .foregroundStyle(Tema.testoSecondario)
                    .fixedSize(horizontal: false, vertical: true)
            }
            MenuAnalisi(
                titolo: testo("mensile.menu"),
                opzioni: opzioniObiettivo,
                etichetta: { $0.map { AnalisiFormati.metri($0) } ?? testo("mensile.nessuno") },
                selezione: sceltaObiettivo
            )
        }
    }

    // MARK: Commento del coach

    private var coach: CoachID { stato.profilo.coach ?? .uomo }

    private var cartaCoach: some View {
        let dati = stato.datiMese()
        let frase = commento ?? fraseFissa(dati)
        return HStack(alignment: .top, spacing: 14) {
            AvatarCoach(coach: coach, espressione: espressione(dati), dimensione: 56)
            VStack(alignment: .leading, spacing: 6) {
                Text(verbatim: testo("riepilogo.commento.titolo", coach.nome))
                    .font(Tema.sottotitolo)
                    .foregroundStyle(Tema.testo)
                Text(verbatim: frase)
                    .font(Tema.corpo)
                    .foregroundStyle(Tema.testo)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .carta()
        .accessibilityElement(children: .combine)
    }

    private func espressione(_ dati: DatiMese) -> EspressioneCoach {
        if dati.nuotate == 0 { return .benvenuto }
        if stato.progressoMensile?.raggiunto == true { return .traguardo }
        return .incoraggiamento
    }

    /// Frase locale, usata quando il servizio non risponde o non c'è il consenso all'IA.
    /// Solo numeri veri del mese; tono caldo, nessun consiglio tecnico o medico, nessuna colpa.
    private func fraseFissa(_ dati: DatiMese) -> String {
        let metri = FormatiUI.numero(dati.metri)
        if dati.nuotate == 0 {
            return testo("riepilogo.commento.vuoto")
        }
        if dati.dure > 0 && dati.dure > dati.facili + dati.giuste {
            return testo("riepilogo.commento.dure")
        }
        if dati.settimaneDiFila >= 2 {
            return testo("riepilogo.commento.serie", dati.settimaneDiFila)
        }
        if dati.metriMesePrecedente > 0 && dati.metri > dati.metriMesePrecedente {
            return testo("riepilogo.commento.crescita", metri)
        }
        if dati.nuotate == 1 {
            return testo("riepilogo.commento.una", metri)
        }
        return testo("riepilogo.commento.generico", dati.nuotate, metri)
    }

    // MARK: Condividi

    private func condividi(_ d: DatiPeriodo) -> some View {
        let titolo = testo(vista == .settimana ? "riepilogo.carta.settimana" : "riepilogo.carta.mese")
        let metri = AnalisiFormati.metri(d.somma.metri)
        let tempo = AnalisiFormati.durata(d.somma.durataSecondi)
        let nuotate = testo("riepilogo.carta.nuotate", d.somma.nuotate)
        let messaggio = testo("riepilogo.condividi.testo", titolo, metri, d.somma.nuotate)
        let chiave = "\(vista)|\(d.somma.metri)|\(d.somma.nuotate)|\(d.somma.durataSecondi)"
        return PulsanteCondividiCartina(titoloAnteprima: titolo, messaggio: messaggio, chiave: chiave) {
            VStack(alignment: .leading, spacing: 6) {
                Text(verbatim: titolo)
                    .font(Tema.sottotitolo)
                    .foregroundStyle(Tema.turcheseChiaro)
                Text(verbatim: metri)
                    .font(Tema.numeroGrande)
                Text(verbatim: "\(nuotate) · \(tempo)")
                    .font(Tema.corpo)
            }
        }
        .buttonStyle(.secondario)
    }
}
