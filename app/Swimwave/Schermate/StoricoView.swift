import SwiftUI
import SwimwaveCore

/// La scheda Storico: in alto un menu a segmenti (Nuotate / Calendario / Andamento), sotto una riga di carte
/// che portano a Riepilogo, Record, Traguardi e Il tuo anno, poi il contenuto della sezione scelta.
struct StoricoView: View {
    @Environment(StatoApp.self) private var stato
    @State private var sezione: Sezione = .nuotate
    @State private var mostraPermessoSalute = false
    // Modo "Confronta": si toccano due nuotate, poi si apre il confronto.
    @State private var confrontando = false
    @State private var scelte: [UUID] = []
    @State private var mostraConfronto = false

    private enum Sezione: Hashable {
        case nuotate, calendario, andamento
    }

    var body: some View {
        NavigationStack {
            principale
                .sfondoApp()
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(isPresented: $mostraConfronto) {
                    destinazioneConfronto
                }
        }
        .sheet(isPresented: $mostraPermessoSalute) {
            PermessoSaluteView(onFine: { mostraPermessoSalute = false })
                .environment(stato)
        }
        .onChange(of: sezione) { _, nuova in
            if nuova != .nuotate { terminaConfronto() }
        }
        .onChange(of: mostraConfronto) { _, aperto in
            // Tornati dal confronto si esce dal modo di selezione.
            if !aperto { terminaConfronto() }
        }
    }

    // MARK: Struttura

    @ViewBuilder
    private var principale: some View {
        if sezione == .andamento {
            // AndamentoView ha il suo scorrimento: qui restano fissi solo intestazione e menu a segmenti.
            VStack(spacing: 0) {
                intestazione
                selettore
                AndamentoView()
            }
        } else {
            ScrollView {
                VStack(spacing: 0) {
                    intestazione
                    selettore
                    schede
                    VStack(spacing: 12) {
                        if sezione == .nuotate {
                            elencoNuotate
                        } else {
                            CalendarioView()
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
            .safeAreaInset(edge: .bottom) {
                if confrontando && sezione == .nuotate {
                    barraConfronto
                }
            }
        }
    }

    private var intestazione: some View {
        IntestazioneOnda {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("storico.titolo").font(Tema.titolo2)
                    Text("storico.sottotitolo").font(Tema.corpo).opacity(0.9)
                }
                Spacer(minLength: 0)
                if stato.nuotate.count >= 2 {
                    Button {
                        if confrontando {
                            terminaConfronto()
                        } else {
                            sezione = .nuotate
                            confrontando = true
                            scelte = []
                        }
                    } label: {
                        Text(LocalizedStringKey(confrontando ? "comune.annulla" : "storico.confronta"))
                            .font(Tema.piccolo.weight(.bold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .overlay(Capsule().stroke(Tema.testoSuNavy, lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var selettore: some View {
        Picker("storico.sezione", selection: $sezione) {
            Text("storico.sezione.nuotate").tag(Sezione.nuotate)
            Text("storico.sezione.calendario").tag(Sezione.calendario)
            Text("storico.sezione.andamento").tag(Sezione.andamento)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 8)
    }

    // MARK: Carte verso le analisi

    private var schede: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) {
                NavigationLink { RiepilogoView() } label: {
                    SchedaRapida(icona: "chart.bar.fill", titolo: testo("storico.scheda.riepilogo"), dato: datoRiepilogo)
                }
                NavigationLink { RecordView() } label: {
                    SchedaRapida(icona: "star.fill", titolo: testo("storico.scheda.record"), dato: datoRecord)
                }
                NavigationLink { TraguardiView() } label: {
                    SchedaRapida(icona: "rosette", titolo: testo("storico.scheda.traguardi"), dato: datoTraguardi)
                }
                NavigationLink { IlTuoAnnoView() } label: {
                    SchedaRapida(icona: "calendar", titolo: testo("storico.scheda.anno"), dato: datoAnno)
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
    }

    private var datoRiepilogo: String {
        let nelMese = Riepiloghi.filtra(stato.nuotate, periodo: .mese, rispetto: Date(), calendar: .italiano).count
        return nelMese == 1 ? testo("storico.dato.nuotateMese.una") : testo("storico.dato.nuotateMese.altre", nelMese)
    }

    private var datoRecord: String {
        if let piuLunga = stato.records.nuotataPiuLunga, piuLunga.metri > 0 {
            return testo("storico.dato.record", FormatiUI.numero(piuLunga.metri))
        }
        return testo("storico.dato.record.vuoto")
    }

    private var datoTraguardi: String {
        let elenco = stato.medaglie
        let ottenute = elenco.filter { $0.ottenuta }.count
        return testo("storico.dato.traguardi", ottenute, elenco.count)
    }

    private var datoAnno: String {
        let anno = Calendar.italiano.component(.year, from: Date())
        let metri = stato.riepilogoAnno(anno).metri
        return testo("storico.dato.anno", FormatiUI.numero(metri))
    }

    // MARK: Elenco delle nuotate

    @ViewBuilder
    private var elencoNuotate: some View {
        if stato.nuotate.isEmpty {
            vuoto
        } else {
            riepilogo
        }
        collegaSalute
        if confrontando {
            istruzioneConfronto
        }
        ForEach(gruppiPerSettimana()) { gruppo in
            VStack(alignment: .leading, spacing: 10) {
                Text(verbatim: titolo(per: gruppo.inizio))
                    .font(Tema.sottotitolo)
                    .foregroundStyle(Tema.testoSecondario)
                    .padding(.top, 8)
                    .accessibilityAddTraits(.isHeader)
                ForEach(gruppo.nuotate) { n in
                    riga(n)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func riga(_ n: NuotataCompletata) -> some View {
        if confrontando {
            Button { alterna(n.id) } label: {
                RigaNuotata(nuotata: n, selezione: scelte.contains(n.id))
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink {
                DettaglioNuotataView(nuotata: n)
            } label: {
                RigaNuotata(nuotata: n)
            }
            .buttonStyle(.plain)
            .contextMenu {
                // Risposta rapida a "com'è andata?" senza aprire il dettaglio.
                ForEach(Sensazione.allCases, id: \.self) { s in
                    Button {
                        stato.imposta(sensazione: s, perNuotata: n.id)
                    } label: {
                        Label(PresentazioneSensazione.etichetta(s), systemImage: PresentazioneSensazione.simbolo(s))
                    }
                }
            }
        }
    }

    // MARK: Confronto

    private var istruzioneConfronto: some View {
        Text(verbatim: testo("storico.confronta.istruzione", scelte.count))
            .font(Tema.sottotitolo)
            .foregroundStyle(Tema.testo)
            .carta(padding: 14)
            .accessibilityAddTraits(.isHeader)
    }

    private var barraConfronto: some View {
        Button {
            mostraConfronto = true
        } label: {
            Text("storico.confronta.apri")
        }
        .buttonStyle(.primario)
        .disabled(scelte.count != 2)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(Tema.sfondo.opacity(0.95))
    }

    private func alterna(_ id: UUID) {
        if let i = scelte.firstIndex(of: id) {
            scelte.remove(at: i)
        } else if scelte.count >= 2 {
            scelte = [scelte[1], id]
        } else {
            scelte.append(id)
        }
    }

    private func terminaConfronto() {
        confrontando = false
        scelte = []
        mostraConfronto = false
    }

    @ViewBuilder
    private var destinazioneConfronto: some View {
        // La più vecchia è A, la più recente è B: la differenza (B meno A) racconta il cambiamento nel tempo.
        let due = scelte
            .compactMap { id in stato.nuotate.first(where: { $0.id == id }) }
            .sorted { $0.data < $1.data }
        if due.count == 2 {
            ConfrontoView(a: due[0], b: due[1])
        } else {
            EmptyView()
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

// MARK: - Carta verso un'analisi

private struct SchedaRapida: View {
    let icona: String
    let titolo: String
    let dato: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                Circle().fill(Tema.turchese.opacity(0.18))
                Image(systemName: icona)
                    .font(.system(.body, design: .rounded).weight(.bold))
                    .foregroundStyle(Tema.testo)
            }
            .frame(width: 40, height: 40)
            .accessibilityHidden(true)
            Text(verbatim: titolo)
                .font(Tema.sottotitolo)
                .foregroundStyle(Tema.testo)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(verbatim: dato)
                .font(Tema.piccolo)
                .foregroundStyle(Tema.testoSecondario)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
        }
        .frame(minHeight: 120, alignment: .topLeading)
        .carta(padding: 14)
        .frame(width: 160)
        .accessibilityElement(children: .combine)
    }
}
