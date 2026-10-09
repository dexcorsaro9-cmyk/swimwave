import SwiftUI
import Charts
import SwimwaveCore

private enum PeriodoAndamento: CaseIterable, Hashable {
    case settimane8, mesi6, mesi12

    var etichetta: String {
        switch self {
        case .settimane8: return testo("andamento.periodo.settimane8")
        case .mesi6: return testo("andamento.periodo.mesi6")
        case .mesi12: return testo("andamento.periodo.mesi12")
        }
    }

    var perSettimana: Bool { self == .settimane8 }

    var quanti: Int {
        switch self {
        case .settimane8: return 8
        case .mesi6: return 6
        case .mesi12: return 12
        }
    }
}

private enum FiltroVasca: CaseIterable, Hashable {
    case tutte, vasca25, vasca50, acqueLibere

    var etichetta: String {
        switch self {
        case .tutte: return testo("andamento.vasca.tutte")
        case .vasca25: return testo("andamento.vasca.25")
        case .vasca50: return testo("andamento.vasca.50")
        case .acqueLibere: return testo("andamento.vasca.acqueLibere")
        }
    }

    /// Le nuotate senza il dato della vasca contano solo in "Tutte le vasche".
    func accetta(_ n: NuotataCompletata) -> Bool {
        switch self {
        case .tutte: return true
        case .vasca25: return n.ambiente != .acqueLibere && n.vascaMetri == 25
        case .vasca50: return n.ambiente != .acqueLibere && n.vascaMetri == 50
        case .acqueLibere: return n.ambiente == .acqueLibere
        }
    }
}

private struct BarraMetri: Identifiable {
    let id: Date
    let etichetta: String
    let metri: Int
}

private struct PuntoRitmo: Identifiable {
    let id: UUID
    let data: Date
    /// Secondi ogni 100 m.
    let ritmo: Double
}

private struct DatiAndamento {
    var barre: [BarraMetri]
    var punti: [PuntoRitmo]
    var somma: SommaPeriodo
}

/// Andamento: grafici dei metri e del ritmo, con scelta del periodo e della vasca. Ha il suo scorrimento e non ha
/// intestazione (la mette lo Storico, che lo contiene). Sfondo non impostato: lo dà chi lo contiene.
/// Mostra solo numeri calcolati dalle nuotate, senza commenti.
struct AndamentoView: View {
    @Environment(StatoApp.self) private var stato
    @State private var periodo: PeriodoAndamento = .settimane8
    @State private var filtro: FiltroVasca = .tutte

    var body: some View {
        let dati = calcola()
        ScrollView {
            VStack(spacing: 12) {
                scelte
                if stato.nuotate.isEmpty {
                    vuoto(chiave: "andamento.vuoto.testo")
                } else if dati.somma.nuotate == 0 {
                    vuoto(chiave: "andamento.vuoto.filtro")
                } else {
                    riepilogo(dati.somma)
                    graficoMetri(dati)
                    graficoRitmo(dati)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
    }

    // MARK: Calcolo

    private func calcola() -> DatiAndamento {
        let calendario = Calendar.italiano
        let oggi = Date()
        let filtrate = stato.nuotate.filter { filtro.accetta($0) }

        let somme: [SommaPeriodo]
        if periodo.perSettimana {
            somme = Riepiloghi.perSettimana(nuotate: filtrate, quante: periodo.quanti, rispetto: oggi, calendar: calendario)
        } else {
            somme = Riepiloghi.perMese(nuotate: filtrate, quanti: periodo.quanti, rispetto: oggi, calendar: calendario)
        }
        let barre = somme.map { s in
            BarraMetri(
                id: s.inizio,
                etichetta: periodo.perSettimana ? FormatiUI.giornoMese(s.inizio) : AnalisiFormati.meseBreve(s.inizio),
                metri: s.metri
            )
        }

        let inizio = somme.first?.inizio ?? Date.distantPast
        let nelPeriodo = filtrate.filter { $0.data >= inizio }
        let punti = nelPeriodo
            .filter { $0.metri >= 200 && ($0.ritmoPer100Secondi ?? 0) > 0 }
            .sorted { $0.data < $1.data }
            .compactMap { n -> PuntoRitmo? in
                guard let r = n.ritmoPer100Secondi else { return nil }
                return PuntoRitmo(id: n.id, data: n.data, ritmo: r)
            }
        return DatiAndamento(barre: barre, punti: punti, somma: Riepiloghi.somma(nelPeriodo))
    }

    // MARK: Parti

    private var scelte: some View {
        VStack(spacing: 10) {
            MenuAnalisi(
                titolo: testo("andamento.periodo.titolo"),
                opzioni: PeriodoAndamento.allCases,
                etichetta: { $0.etichetta },
                selezione: $periodo
            )
            MenuAnalisi(
                titolo: testo("andamento.vasca.titolo"),
                opzioni: FiltroVasca.allCases,
                etichetta: { $0.etichetta },
                selezione: $filtro
            )
        }
    }

    private func vuoto(chiave: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.bar")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(Tema.turchese)
                .accessibilityHidden(true)
            Text(LocalizedStringKey(chiave))
                .font(Tema.corpo)
                .foregroundStyle(Tema.testoSecondario)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .carta(padding: 24)
    }

    private func riepilogo(_ somma: SommaPeriodo) -> some View {
        HStack(alignment: .top, spacing: 12) {
            NumeroAnalisi(valore: AnalisiFormati.metri(somma.metri), etichetta: testo("andamento.riepilogo.metri"))
            NumeroAnalisi(valore: FormatiUI.numero(somma.nuotate), etichetta: testo("andamento.riepilogo.nuotate"))
            NumeroAnalisi(valore: AnalisiFormati.durata(somma.durataSecondi), etichetta: testo("andamento.riepilogo.tempo"))
        }
        .carta()
    }

    private func graficoMetri(_ dati: DatiAndamento) -> some View {
        let piuAlto = dati.barre.map(\.metri).max() ?? 0
        return CartaAnalisi(titolo: testo(periodo.perSettimana ? "andamento.metri.titoloSettimana" : "andamento.metri.titoloMese")) {
            Chart(dati.barre) { barra in
                BarMark(
                    x: .value("Periodo", barra.etichetta),
                    y: .value("Metri", barra.metri)
                )
                .foregroundStyle(Tema.turchese)
            }
            .frame(height: 200)
            .accessibilityLabel(Text(verbatim: testo("andamento.metri.accessibilita",
                                                     FormatiUI.numero(dati.somma.metri),
                                                     FormatiUI.numero(piuAlto))))
        }
    }

    @ViewBuilder
    private func graficoRitmo(_ dati: DatiAndamento) -> some View {
        CartaAnalisi(titolo: testo("andamento.ritmo.titolo")) {
            if dati.punti.isEmpty {
                Text("andamento.ritmo.vuoto")
                    .font(Tema.corpo)
                    .foregroundStyle(Tema.testoSecondario)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                let valori = dati.punti.map(\.ritmo)
                let piuVeloce = valori.min() ?? 0
                let piuLento = valori.max() ?? 0
                let margine = max(3.0, (piuLento - piuVeloce) * 0.15)
                // Il ritmo si disegna con il segno cambiato: così il ritmo più veloce (meno secondi) sta in alto.
                // Le etichette dell'asse tolgono il segno di nuovo.
                let dominio = (-(piuLento + margine))...(-(piuVeloce - margine))
                Chart(dati.punti) { punto in
                    LineMark(
                        x: .value("Data", punto.data),
                        y: .value("Ritmo", -punto.ritmo)
                    )
                    .foregroundStyle(Tema.corallo)
                    PointMark(
                        x: .value("Data", punto.data),
                        y: .value("Ritmo", -punto.ritmo)
                    )
                    .foregroundStyle(Tema.corallo)
                }
                .chartYScale(domain: dominio)
                .chartYAxis {
                    AxisMarks(values: .automatic) { valore in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = valore.as(Double.self) {
                                Text(verbatim: FormatoRitmo.minutiSecondi(-v))
                            }
                        }
                    }
                }
                .frame(height: 200)
                .accessibilityLabel(Text(verbatim: testo("andamento.ritmo.accessibilita",
                                                         dati.punti.count,
                                                         FormatoRitmo.minutiSecondi(piuVeloce),
                                                         FormatoRitmo.minutiSecondi(piuLento))))
                Text("andamento.ritmo.nota")
                    .font(Tema.piccolo)
                    .foregroundStyle(Tema.testoSecondario)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
