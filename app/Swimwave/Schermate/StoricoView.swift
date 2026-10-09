import SwiftUI
import SwimwaveCore

/// Le nuotate fatte, raggruppate per settimana: quelle del Watch, dell'iPhone e quelle lette da Apple Salute.
struct StoricoView: View {
    @Environment(StatoApp.self) private var stato
    @State private var daValutare: NuotataCompletata?
    @State private var mostraPermessoSalute = false

    var body: some View {
        let gruppi = gruppiPerSettimana()
        ScrollView {
            VStack(spacing: 0) {
                IntestazioneOnda {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("storico.titolo").font(Tema.titolo2)
                        Text("storico.sottotitolo").font(Tema.corpo).opacity(0.9)
                    }
                }
                VStack(spacing: 12) {
                    if stato.nuotate.isEmpty {
                        vuoto
                    } else {
                        riepilogo
                    }
                    collegaSalute
                    ForEach(gruppi) { gruppo in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(verbatim: titolo(per: gruppo.inizio))
                                .font(Tema.sottotitolo)
                                .foregroundStyle(Tema.testoSecondario)
                                .padding(.top, 8)
                                .accessibilityAddTraits(.isHeader)
                            ForEach(gruppo.nuotate) { n in
                                if n.sensazione == nil {
                                    // Senza risposta: un tocco per dire com'è andata.
                                    Button { daValutare = n } label: { RigaNuotata(nuotata: n) }
                                        .buttonStyle(.plain)
                                } else {
                                    RigaNuotata(nuotata: n)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .refreshable {
            await stato.importaDaSalute()
        }
        .sfondoApp()
        .sheet(isPresented: $mostraPermessoSalute) {
            PermessoSaluteView(onFine: { mostraPermessoSalute = false })
                .environment(stato)
        }
        .confirmationDialog(
            Text("storico.sensazione.titolo"),
            isPresented: Binding(
                get: { daValutare != nil },
                set: { if !$0 { daValutare = nil } }
            ),
            titleVisibility: .visible,
            presenting: daValutare
        ) { nuotata in
            ForEach(Sensazione.allCases, id: \.self) { s in
                Button(PresentazioneSensazione.etichetta(s)) {
                    stato.imposta(sensazione: s, perNuotata: nuotata.id)
                }
            }
            Button("comune.annulla", role: .cancel) {}
        }
    }

    // MARK: Stato vuoto e Salute

    private var vuoto: some View {
        HStack(alignment: .center, spacing: 14) {
            if let coach = stato.profilo.coach {
                AvatarCoach(coach: coach, espressione: .benvenuto, dimensione: 64)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("storico.vuoto.benvenuto")
                    .font(Tema.sottotitolo)
                    .foregroundStyle(Tema.testo)
                Text("storico.vuoto.frase")
                    .font(Tema.corpo)
                    .foregroundStyle(Tema.testoSecondario)
            }
        }
        .carta()
    }

    /// Finché non si è parlato di Apple Salute resta una strada per collegarla.
    @ViewBuilder
    private var collegaSalute: some View {
        if !stato.permessoSaluteChiesto {
            VStack(alignment: .leading, spacing: 10) {
                Text("storico.salute.titolo")
                    .font(Tema.sottotitolo)
                    .foregroundStyle(Tema.testo)
                Text("storico.salute.testo")
                    .font(Tema.corpo)
                    .foregroundStyle(Tema.testoSecondario)
                Button {
                    mostraPermessoSalute = true
                } label: {
                    Text("storico.salute.bottone")
                }
                .buttonStyle(.secondario)
            }
            .carta()
        }
    }

    // MARK: Riepilogo

    private var riepilogo: some View {
        let cal = Calendar.italiano
        let oggi = Date()
        let metriMese = stato.nuotate
            .filter { cal.isDate($0.data, equalTo: oggi, toGranularity: .month) }
            .reduce(0) { $0 + $1.metri }
        let serie = stato.serieSettimane
        return HStack(alignment: .top, spacing: 8) {
            voceRiepilogo(valore: "\(stato.nuotate.count)", etichetta: "storico.riepilogo.nuotate")
            voceRiepilogo(valore: FormatiUI.numero(metriMese), etichetta: "storico.riepilogo.metriMese")
            // Con la serie a zero non si scrive niente: nessun messaggio di perdita.
            if serie >= 1 {
                voceRiepilogo(valore: "\(serie)", etichetta: "storico.riepilogo.settimane")
            }
        }
        .carta()
    }

    private func voceRiepilogo(valore: String, etichetta: String) -> some View {
        VStack(spacing: 2) {
            Text(verbatim: valore)
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(Tema.testo)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(LocalizedStringKey(etichetta))
                .font(Tema.piccolo)
                .foregroundStyle(Tema.testoSecondario)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    // MARK: Gruppi per settimana

    private struct GruppoSettimana: Identifiable {
        let inizio: Date
        let nuotate: [NuotataCompletata]
        var id: Date { inizio }
    }

    private func gruppiPerSettimana() -> [GruppoSettimana] {
        let cal = Calendar.italiano
        var perSettimana: [Date: [NuotataCompletata]] = [:]
        for n in stato.nuotate {
            let inizio = cal.dateInterval(of: .weekOfYear, for: n.data)?.start ?? cal.startOfDay(for: n.data)
            perSettimana[inizio, default: []].append(n)
        }
        return perSettimana.keys.sorted(by: >).map { inizio in
            GruppoSettimana(
                inizio: inizio,
                nuotate: (perSettimana[inizio] ?? []).sorted { $0.data > $1.data }
            )
        }
    }

    private func titolo(per inizio: Date) -> String {
        let cal = Calendar.italiano
        let adesso = Date()
        if let corrente = cal.dateInterval(of: .weekOfYear, for: adesso)?.start {
            if cal.isDate(inizio, inSameDayAs: corrente) {
                return testo("storico.settimana.corrente")
            }
            if let scorsa = cal.date(byAdding: .weekOfYear, value: -1, to: corrente),
               cal.isDate(inizio, inSameDayAs: scorsa) {
                return testo("storico.settimana.scorsa")
            }
        }
        return testo("storico.settimana.del", FormatiUI.giornoMese(inizio))
    }
}

// MARK: - Una nuotata

private struct RigaNuotata: View {
    let nuotata: NuotataCompletata

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Tema.turchese.opacity(0.18))
                Image(systemName: simboloOrigine)
                    .font(.system(.body, design: .rounded).weight(.bold))
                    .foregroundStyle(Tema.testo)
            }
            .frame(width: 44, height: 44)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: FormatiUI.dataEOra(nuotata.data))
                    .font(Tema.sottotitolo)
                    .foregroundStyle(Tema.testo)
                if !nuotata.titolo.isEmpty {
                    Text(verbatim: nuotata.titolo)
                        .font(Tema.corpo)
                        .foregroundStyle(Tema.testo)
                }
                Text(verbatim: testo("storico.riga", nuotata.metri, FormatoTempo.minutiArrotondati(nuotata.durataSecondi)))
                    .font(Tema.piccolo)
                    .foregroundStyle(Tema.testoSecondario)
            }
            Spacer(minLength: 0)
            if let s = nuotata.sensazione {
                Etichetta(contenuto: PresentazioneSensazione.etichetta(s))
            } else {
                Text("storico.comeVa")
                    .font(Tema.piccolo.weight(.bold))
                    .foregroundStyle(Tema.coralloOmbra)
            }
        }
        .carta(padding: 14)
        .accessibilityElement(children: .combine)
    }

    private var simboloOrigine: String {
        switch nuotata.origine {
        case .watch?: return "applewatch"
        case .iphone?: return "iphone"
        case .salute?: return "heart.fill"
        case nil: return "figure.pool.swim"
        }
    }
}
