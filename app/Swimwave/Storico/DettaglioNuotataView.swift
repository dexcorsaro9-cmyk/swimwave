import SwiftUI
import Charts
import SwimwaveCore

/// Il dettaglio di una nuotata: numeri, sensazione, vasche, nota personale, correzione, condivisione, eliminazione.
/// Riceve una copia, ma rilegge sempre la versione aggiornata da `stato.nuotate` (cerca per id).
struct DettaglioNuotataView: View {
    @Environment(StatoApp.self) private var stato
    @Environment(\.dismiss) private var dismiss

    private let iniziale: NuotataCompletata
    @State private var bozzaNota: String
    @State private var mostraCorrezione = false
    @State private var chiediEliminazione = false
    @State private var immagine: Image?
    @FocusState private var notaInFocus: Bool

    init(nuotata: NuotataCompletata) {
        self.iniziale = nuotata
        _bozzaNota = State(initialValue: nuotata.nota ?? "")
    }

    /// La versione più recente della nuotata (se è stata eliminata, resta la copia ricevuta mentre la schermata si chiude).
    private var corrente: NuotataCompletata {
        stato.nuotate.first(where: { $0.id == iniziale.id }) ?? iniziale
    }

    private static let limiteNota = 500

    var body: some View {
        let n = corrente
        ScrollView {
            VStack(spacing: 16) {
                testata(n)
                numeriPrincipali(n)
                altriNumeri(n)
                sensazione
                if let confronto = Efficienza.confronto(di: n, con: stato.nuotate) {
                    SezioneScivolamento(confronto: confronto)
                }
                if let vasche = n.vasche {
                    let quote = Efficienza.distribuzioneStili(vasche)
                    if !quote.isEmpty {
                        SezioneStili(quote: quote)
                    }
                }
                if let vasche = n.vasche, !vasche.isEmpty {
                    SezioneVasche(nuotata: n, vasche: vasche)
                }
                sezioneNota
                azioni(n)
            }
            .padding(16)
        }
        .scrollDismissesKeyboard(.interactively)
        .sfondoApp()
        .navigationTitle("dettaglio.titolo")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("comune.fatto") { notaInFocus = false }
            }
        }
        .sheet(isPresented: $mostraCorrezione) {
            CorrezioneView(metri: n.metri, durataSecondi: n.durataSecondi) { metri, durata in
                stato.correggi(nuotataConId: iniziale.id, metri: metri, durataSecondi: durata)
            }
        }
        .confirmationDialog("dettaglio.elimina.titolo", isPresented: $chiediEliminazione, titleVisibility: .visible) {
            Button("dettaglio.elimina.conferma", role: .destructive) {
                stato.elimina(nuotataConId: iniziale.id)
                dismiss()
            }
            Button("comune.annulla", role: .cancel) {}
        } message: {
            Text("dettaglio.elimina.messaggio")
        }
        .onAppear { aggiornaImmagine(n) }
        .onChange(of: n) { _, nuova in aggiornaImmagine(nuova) }
        .onDisappear { salvaNotaSeCambiata() }
    }

    // MARK: Testata

    private func testata(_ n: NuotataCompletata) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(verbatim: FormatiStorico.dataLunga(n.data))
                .font(Tema.titolo2)
                .foregroundStyle(Tema.testo)
            Text(verbatim: FormatiStorico.ora(n.data))
                .font(Tema.corpo)
                .foregroundStyle(Tema.testoSecondario)
            if !n.titolo.isEmpty {
                Text(verbatim: n.titolo)
                    .font(Tema.sottotitolo)
                    .foregroundStyle(Tema.testo)
            }
            VStack(alignment: .leading, spacing: 6) {
                if let o = origine(n.origine) {
                    riga(simbolo: o.simbolo, testoRiga: o.nome)
                }
                if let a = ambiente(n) {
                    riga(simbolo: a.simbolo, testoRiga: a.nome)
                }
                if n.corretta == true {
                    Etichetta(contenuto: testo("dettaglio.corretta"))
                }
            }
            .padding(.top, 4)
        }
        .carta()
    }

    private func riga(simbolo: String, testoRiga: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: simbolo)
                .font(.system(.body, design: .rounded).weight(.bold))
                .foregroundStyle(Tema.testo)
                .frame(width: 26)
                .accessibilityHidden(true)
            Text(verbatim: testoRiga)
                .font(Tema.corpo)
                .foregroundStyle(Tema.testo)
        }
        .accessibilityElement(children: .combine)
    }

    private func origine(_ o: OrigineNuotata?) -> (simbolo: String, nome: String)? {
        switch o {
        case .watch?: return ("applewatch", testo("dettaglio.origine.watch"))
        case .iphone?: return ("iphone", testo("dettaglio.origine.iphone"))
        case .salute?: return ("heart.fill", testo("dettaglio.origine.salute"))
        case nil: return nil
        }
    }

    private func ambiente(_ n: NuotataCompletata) -> (simbolo: String, nome: String)? {
        let lunghezza = (n.vascaMetri ?? 0) > 0 ? n.vascaMetri : nil
        switch n.ambiente {
        case .vasca?:
            if let l = lunghezza { return ("figure.pool.swim", testo("dettaglio.ambiente.vascaDa", l)) }
            return ("figure.pool.swim", testo("dettaglio.ambiente.vasca"))
        case .acqueLibere?:
            return ("water.waves", testo("dettaglio.ambiente.acqueLibere"))
        case nil:
            if let l = lunghezza { return ("figure.pool.swim", testo("dettaglio.ambiente.vascaDa", l)) }
            return nil
        }
    }

    // MARK: Numeri

    private func numeriPrincipali(_ n: NuotataCompletata) -> some View {
        HStack(alignment: .top, spacing: 8) {
            NumeroGrande(valore: FormatiUI.numero(n.metri), etichetta: testo("dettaglio.etichetta.metri"), dimensione: 34)
            NumeroGrande(valore: FormatoTempo.mmss(n.durataSecondi), etichetta: testo("dettaglio.etichetta.tempo"), dimensione: 34)
            if let r = n.ritmoPer100Secondi {
                NumeroGrande(valore: FormatoRitmo.minutiSecondi(r), etichetta: testo("dettaglio.etichetta.ritmo"), dimensione: 34)
            }
        }
        .carta()
    }

    @ViewBuilder
    private func altriNumeri(_ n: NuotataCompletata) -> some View {
        let voci = vociSecondarie(n)
        if !voci.isEmpty {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(voci, id: \.etichetta) { v in
                    NumeroGrande(valore: v.valore, etichetta: v.etichetta, dimensione: 28)
                        .carta(padding: 14)
                }
            }
        }
    }

    /// Calorie, frequenza cardiaca media, bracciate: solo quelle che ci sono.
    private func vociSecondarie(_ n: NuotataCompletata) -> [(valore: String, etichetta: String)] {
        var voci: [(valore: String, etichetta: String)] = []
        if let c = n.calorie {
            voci.append((FormatiUI.numero(c), testo("dettaglio.etichetta.calorie")))
        }
        if let f = n.frequenzaCardiacaMedia {
            voci.append(("\(f)", testo("dettaglio.etichetta.frequenza")))
        }
        if let b = n.bracciate {
            voci.append((FormatiUI.numero(b), testo("dettaglio.etichetta.bracciate")))
        }
        if let bv = n.bracciatePerVasca {
            voci.append((FormatiStorico.decimale(bv), testo("dettaglio.etichetta.bracciatePerVasca")))
        }
        return voci
    }

    // MARK: Sensazione

    private var sensazione: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("storico.comeVa")
                .font(Tema.sottotitolo)
                .foregroundStyle(Tema.testo)
            MenuScelta(
                titolo: testo("storico.comeVa"),
                opzioni: Sensazione.allCases,
                etichetta: { PresentazioneSensazione.etichetta($0) },
                selezione: Binding<Sensazione?>(
                    get: { corrente.sensazione },
                    set: { nuova in
                        if let s = nuova {
                            stato.imposta(sensazione: s, perNuotata: iniziale.id)
                        }
                    }
                )
            )
        }
        .carta()
    }

    // MARK: Nota

    private var notaCambiata: Bool {
        bozzaNota.trimmingCharacters(in: .whitespacesAndNewlines) != (corrente.nota ?? "")
    }

    private var sezioneNota: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("dettaglio.nota.titolo")
                .font(Tema.sottotitolo)
                .foregroundStyle(Tema.testo)
            TextField("dettaglio.nota.segnaposto", text: $bozzaNota, axis: .vertical)
                .lineLimit(3...8)
                .focused($notaInFocus)
                .font(Tema.corpo)
                .foregroundStyle(Tema.testo)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Tema.turchese, lineWidth: 2)
                )
                .onChange(of: bozzaNota) { _, nuovo in
                    if nuovo.count > DettaglioNuotataView.limiteNota {
                        bozzaNota = String(nuovo.prefix(DettaglioNuotataView.limiteNota))
                    }
                }
                .onChange(of: notaInFocus) { _, inFocus in
                    // Finita la modifica, la nota si salva da sola.
                    if !inFocus { salvaNotaSeCambiata() }
                }
            HStack {
                Text(verbatim: testo("dettaglio.nota.conteggio", bozzaNota.count, DettaglioNuotataView.limiteNota))
                    .font(Tema.piccolo)
                    .foregroundStyle(Tema.testoSecondario)
                Spacer(minLength: 0)
            }
            Button {
                notaInFocus = false
                salvaNotaSeCambiata()
            } label: {
                Text("dettaglio.nota.salva")
            }
            .buttonStyle(.secondario)
            .disabled(!notaCambiata)
        }
        .carta()
    }

    private func salvaNotaSeCambiata() {
        guard notaCambiata else { return }
        stato.imposta(nota: bozzaNota, perNuotata: iniziale.id)
    }

    // MARK: Azioni

    private func azioni(_ n: NuotataCompletata) -> some View {
        VStack(spacing: 12) {
            Button {
                mostraCorrezione = true
            } label: {
                Text("dettaglio.correggi")
            }
            .buttonStyle(.secondario)

            ShareLink(item: testoCondivisione(n)) {
                Label("dettaglio.condividi.testo", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.secondario)

            if let img = immagine {
                ShareLink(item: img, preview: SharePreview(FormatiStorico.titolo(n), image: img)) {
                    Label("dettaglio.condividi.immagine", systemImage: "photo")
                }
                .buttonStyle(.secondario)
            }

            Button(role: .destructive) {
                chiediEliminazione = true
            } label: {
                Text("dettaglio.elimina")
            }
            .buttonStyle(.secondario)
        }
        .padding(.top, 4)
    }

    private func testoCondivisione(_ n: NuotataCompletata) -> String {
        testo("condividi.testo", FormatiStorico.giornoMeseLungo(n.data), FormatiUI.numero(n.metri), FormatoTempo.mmss(n.durataSecondi))
    }

    private func aggiornaImmagine(_ n: NuotataCompletata) {
        Task { @MainActor in
            immagine = immagineDaCondividere(CarticinaNuotata(nuotata: n))
        }
    }
}

// MARK: - Un numero grande con la sua etichetta

private struct NumeroGrande: View {
    let valore: String
    let etichetta: String
    let dimensione: CGFloat

    var body: some View {
        VStack(spacing: 2) {
            Text(verbatim: valore)
                .font(.system(size: dimensione, weight: .heavy, design: .rounded))
                .foregroundStyle(Tema.testo)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(verbatim: etichetta)
                .font(Tema.piccolo)
                .foregroundStyle(Tema.testoSecondario)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Scivolamento

/// "Come scivoli": le bracciate per vasca di oggi contro l'ultima volta nella stessa vasca, in una frase sola.
private struct SezioneScivolamento: View {
    let confronto: ConfrontoBracciate

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text("dettaglio.scivolamento.titolo")
                    .font(Tema.sottotitolo)
                    .foregroundStyle(Tema.testo)
            } icon: {
                Image(systemName: simbolo)
                    .foregroundStyle(Tema.turchese)
            }
            .accessibilityAddTraits(.isHeader)
            Text(verbatim: frase)
                .font(Tema.corpo)
                .foregroundStyle(Tema.testo)
                .fixedSize(horizontal: false, vertical: true)
            Text("dettaglio.scivolamento.nota")
                .font(Tema.piccolo)
                .foregroundStyle(Tema.testoSecondario)
        }
        .carta()
    }

    private var simbolo: String {
        switch confronto {
        case .meno: return "arrow.down.right.circle.fill"
        case .simile: return "equal.circle.fill"
        case .piu: return "arrow.up.right.circle.fill"
        }
    }

    private var frase: String {
        switch confronto {
        case .meno(let oggi, let prima):
            return testo("dettaglio.scivolamento.meno", FormatiStorico.decimale(oggi), FormatiStorico.decimale(prima))
        case .simile(let oggi, _):
            return testo("dettaglio.scivolamento.simile", FormatiStorico.decimale(oggi))
        case .piu(let oggi, let prima):
            return testo("dettaglio.scivolamento.piu", FormatiStorico.decimale(oggi), FormatiStorico.decimale(prima))
        }
    }
}

// MARK: - Stili

/// Gli stili nuotati in una ciambella, con la percentuale di ogni stile. Solo stili che l'orologio ha riconosciuto.
private struct SezioneStili: View {
    let quote: [QuotaStile]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("dettaglio.stili.titolo")
                .font(Tema.sottotitolo)
                .foregroundStyle(Tema.testo)
                .accessibilityAddTraits(.isHeader)
            HStack(alignment: .center, spacing: 18) {
                Chart(quote) { q in
                    SectorMark(
                        angle: .value(testo("dettaglio.stili.metri"), q.metri),
                        innerRadius: .ratio(0.6),
                        angularInset: quote.count > 1 ? 2 : 0
                    )
                    .cornerRadius(4)
                    .foregroundStyle(colore(q.stile))
                }
                .chartLegend(.hidden)
                .frame(width: 130, height: 130)
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(quote) { q in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(colore(q.stile))
                                .frame(width: 12, height: 12)
                                .accessibilityHidden(true)
                            Text(verbatim: q.stile.etichetta)
                                .font(Tema.corpo)
                                .foregroundStyle(Tema.testo)
                            Spacer(minLength: 4)
                            Text(verbatim: "\(q.percentuale)%")
                                .font(Tema.sottotitolo)
                                .monospacedDigit()
                                .foregroundStyle(Tema.testo)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
        .carta()
    }

    /// Un colore per stile, scelti perché si distinguano anche con il tema scuro.
    private func colore(_ stile: Stile) -> Color {
        switch stile {
        case .libero: return Tema.turchese
        case .dorso: return Color(red: 0.36, green: 0.55, blue: 0.95)
        case .rana: return Tema.corallo
        case .delfino: return Color(red: 0.62, green: 0.45, blue: 0.92)
        case .misto: return Tema.testoSecondario
        }
    }
}

// MARK: - Vasche

/// Tempi per vasca (o per tratto, in acque libere): grafico a barre, vasca più veloce e più lenta, tempo medio e,
/// solo se ci sono anche le bracciate della nuotata, uno SWOLF indicativo. Le bracciate per ogni singola vasca
/// non le abbiamo e non le inventiamo.
private struct SezioneVasche: View {
    let nuotata: NuotataCompletata
    let vasche: [SplitVasca]

    private struct PuntoVasca: Identifiable {
        let numero: Int
        let secondi: Double
        var id: Int { numero }
    }

    private var tratti: Bool { nuotata.ambiente == .acqueLibere }

    /// Solo le vasche con un tempo vero, col loro numero (parte da 1).
    private var punti: [PuntoVasca] {
        vasche.enumerated()
            .filter { $0.element.durataSecondi > 0 }
            .map { PuntoVasca(numero: $0.offset + 1, secondi: $0.element.durataSecondi) }
    }

    var body: some View {
        let punti = self.punti
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedStringKey(tratti ? "dettaglio.tratti.titolo" : "dettaglio.vasche.titolo"))
                .font(Tema.sottotitolo)
                .foregroundStyle(Tema.testo)
                .accessibilityAddTraits(.isHeader)

            if punti.isEmpty {
                Text("dettaglio.vasche.senzaTempi")
                    .font(Tema.corpo)
                    .foregroundStyle(Tema.testoSecondario)
            } else {
                riepilogo(punti)
                grafico(punti)
                if let s = swolf(punti) {
                    swolfRiga(s)
                }
                elenco
            }
            Text(LocalizedStringKey(tratti ? "dettaglio.tratti.senzaBracciate" : "dettaglio.vasche.senzaBracciate"))
                .font(Tema.piccolo)
                .foregroundStyle(Tema.testoSecondario)
        }
        .carta()
    }

    // MARK: Riepilogo

    private func riepilogo(_ punti: [PuntoVasca]) -> some View {
        let medio = punti.reduce(0.0) { $0 + $1.secondi } / Double(punti.count)
        let veloce = punti.min(by: { $0.secondi < $1.secondi })
        let lenta = punti.max(by: { $0.secondi < $1.secondi })
        return VStack(spacing: 8) {
            voce(tratti ? "dettaglio.tratti.medio" : "dettaglio.vasche.medio", FormatiStorico.tempoVasca(medio))
            if let v = veloce {
                voce(tratti ? "dettaglio.tratti.piuVeloce" : "dettaglio.vasche.piuVeloce",
                     testo(tratti ? "dettaglio.tratti.valore" : "dettaglio.vasche.valore", v.numero, FormatiStorico.tempoVasca(v.secondi)))
            }
            if let l = lenta {
                voce(tratti ? "dettaglio.tratti.piuLenta" : "dettaglio.vasche.piuLenta",
                     testo(tratti ? "dettaglio.tratti.valore" : "dettaglio.vasche.valore", l.numero, FormatiStorico.tempoVasca(l.secondi)))
            }
        }
    }

    private func voce(_ chiave: String, _ valore: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(LocalizedStringKey(chiave))
                .font(Tema.corpo)
                .foregroundStyle(Tema.testoSecondario)
            Spacer(minLength: 8)
            Text(verbatim: valore)
                .font(Tema.sottotitolo)
                .foregroundStyle(Tema.testo)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Grafico

    private func grafico(_ punti: [PuntoVasca]) -> some View {
        // Con tante vasche si scrive solo qualche numero sull'asse.
        let passo = max(1, Int((Double(punti.count) / 6.0).rounded(.up)))
        let etichette = punti.filter { ($0.numero - 1) % passo == 0 }.map { String($0.numero) }
        return VStack(alignment: .leading, spacing: 6) {
            Text(LocalizedStringKey(tratti ? "dettaglio.tratti.grafico" : "dettaglio.vasche.grafico"))
                .font(Tema.piccolo)
                .foregroundStyle(Tema.testoSecondario)
            Chart(punti) { p in
                BarMark(
                    x: .value(testo(tratti ? "dettaglio.tratti.asse" : "dettaglio.vasche.asse"), String(p.numero)),
                    y: .value(testo("dettaglio.vasche.assePassi"), p.secondi)
                )
                .foregroundStyle(Tema.turchese)
            }
            .chartXAxis {
                AxisMarks(values: etichette)
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 180)
        }
    }

    // MARK: SWOLF indicativo

    /// Tempo medio per vasca (secondi) + bracciate per vasca medie. Solo se la nuotata ha le bracciate e tutte le vasche
    /// misurano quanto la vasca dichiarata (altrimenti i due numeri non parlano della stessa cosa).
    private func swolf(_ punti: [PuntoVasca]) -> Int? {
        guard !tratti,
              let bracciate = nuotata.bracciatePerVasca,
              let lunghezza = nuotata.vascaMetri, lunghezza > 0,
              !punti.isEmpty,
              vasche.allSatisfy({ $0.metri == lunghezza }) else { return nil }
        let medio = punti.reduce(0.0) { $0 + $1.secondi } / Double(punti.count)
        return Int((medio + bracciate).rounded())
    }

    private func swolfRiga(_ valore: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            voce("dettaglio.swolf.titolo", "\(valore)")
            Text("dettaglio.swolf.nota")
                .font(Tema.piccolo)
                .foregroundStyle(Tema.testoSecondario)
        }
    }

    // MARK: Elenco

    private var elenco: some View {
        DisclosureGroup {
            VStack(spacing: 0) {
                ForEach(Array(vasche.enumerated()), id: \.offset) { indice, vasca in
                    if indice > 0 {
                        Divider().overlay(Tema.bordo)
                    }
                    HStack {
                        Text(verbatim: testo(tratti ? "dettaglio.tratti.numero" : "dettaglio.vasche.numero", indice + 1))
                            .font(Tema.corpo)
                            .foregroundStyle(Tema.testo)
                        if let stile = vasca.stile {
                            Text(verbatim: stile.etichetta)
                                .font(Tema.piccolo)
                                .foregroundStyle(Tema.testoSecondario)
                        }
                        Spacer(minLength: 8)
                        Text(verbatim: vasca.durataSecondi > 0 ? FormatiStorico.tempoVasca(vasca.durataSecondi) : "–")
                            .font(Tema.sottotitolo)
                            .foregroundStyle(Tema.testo)
                    }
                    .padding(.vertical, 8)
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(.top, 6)
        } label: {
            Text(LocalizedStringKey(tratti ? "dettaglio.tratti.tutti" : "dettaglio.vasche.tutte"))
                .font(Tema.sottotitolo)
                .foregroundStyle(Tema.testo)
        }
        .tint(Tema.testo)
    }
}
