import SwiftUI
import SwimwaveCore

/// Il recap del coach a fine allenamento (bozza: docs/mockup/recap-coach.html): cosa hai fatto, cosa spicca,
/// il commento, un solo consiglio tecnico dai nostri contenuti, la prossima nuotata e come recuperare.
/// Tutto è calcolato con regole sui dati (`Recap` nel pacchetto), senza IA. Dopo una nuotata "dura" il tono è più leggero.
struct RecapCoachView: View {
    let nuotataId: UUID
    /// L'allenamento seguito, se si conosce: senza, il recap non ha metri previsti né consiglio tecnico.
    let workout: Workout?
    let onChiudi: () -> Void

    @Environment(StatoApp.self) private var stato

    var body: some View {
        let profilo = stato.profilo
        let nuotata = stato.nuotate.first { $0.id == nuotataId }
        let sensazione = nuotata?.sensazione
        let dura = sensazione == .dura
        let giorno = Calendar.italiano.ordinality(of: .day, in: .year, for: nuotata?.data ?? Date()) ?? 0
        let evidenze = calcolaEvidenze(nuotata: nuotata, sensazione: sensazione)
        let errore = erroreDaConsigliare(dura: dura, giorno: giorno)

        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    intestazione(profilo: profilo, sensazione: sensazione)
                    if let nuotata {
                        numeri(nuotata)
                    }
                    if !evidenze.isEmpty {
                        sezione("recap.sezione.spicca")
                        VStack(spacing: 8) {
                            ForEach(Array(evidenze.enumerated()), id: \.offset) { _, e in
                                rigaEvidenza(e)
                            }
                        }
                    }
                    if let coach = profilo.coach {
                        sezione(testo("recap.sezione.commento", coach.nome).uppercased())
                        commento(coach: coach, sensazione: sensazione, nuotata: nuotata, errore: errore)
                    }
                    if let errore {
                        sezione("recap.sezione.consiglio")
                        consiglio(errore)
                    }
                    sezione(dura ? "recap.sezione.ripartire" : "recap.sezione.adesso")
                    prossima
                    recupero(dura: dura)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            Button(action: onChiudi) {
                Text("comune.fatto")
            }
            .buttonStyle(.primario)
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .sfondoApp()
    }

    /// L'errore comune da consigliare: solo se si conosce l'allenamento e la nuotata non è stata "dura".
    private func erroreDaConsigliare(dura: Bool, giorno: Int) -> ErroreComune? {
        guard !dura, let workout else { return nil }
        return Recap.erroreConsigliato(workout: workout, errori: stato.contenuti.errori, giorno: giorno)
    }

    /// Le cose che spiccano (calcolo fuori dal corpo della vista: nel corpo non si possono fare assegnamenti).
    private func calcolaEvidenze(nuotata: NuotataCompletata?, sensazione: Sensazione?) -> [Evidenza] {
        guard let nuotata else { return [] }
        let precedenti = stato.nuotate.filter { altra in altra.id != nuotataId }
        return Recap.evidenze(
            nuotata: nuotata,
            precedenti: precedenti,
            metriPrevisti: workout?.metriTotali ?? 0,
            sensazione: sensazione,
            progresso: stato.progressoSettimana,
            serieSettimane: stato.serieSettimane
        )
    }

    // MARK: Intestazione

    private func intestazione(profilo: Profilo, sensazione: Sensazione?) -> some View {
        let dura = sensazione == .dura
        let titolo: String
        switch sensazione {
        case .dura: titolo = testo("recap.titolo.dura")
        case .facile: titolo = testo("recap.titolo.facile", profilo.nomePulito)
        default: titolo = testo("recap.titolo.giusta", profilo.nomePulito)
        }
        return ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: dura
                    ? [Color(squaloHex: 0x9AD3DE), Color(squaloHex: 0x5EAEC6), Color(squaloHex: 0x2F7FA8)]
                    : [Color(squaloHex: 0x46CFE0), Color(squaloHex: 0x1FB5C9), Color(squaloHex: 0x145F94)],
                startPoint: .top, endPoint: .bottom
            )
            OndaSuperficie(fase: 0)
                .fill(Color.white.opacity(0.2))
                .frame(height: 14)
                .frame(maxHeight: .infinity, alignment: .top)
            HStack(alignment: .top) {
                if let coach = profilo.coach {
                    AvatarCoach(coach: coach, espressione: dura ? .dopoAllenamentoDuro : .traguardo, dimensione: 78)
                }
                Spacer(minLength: 8)
                SqualoRecap(stanco: dura)
                    .frame(width: 124)
            }
            .padding(.horizontal, 16)
            .padding(.top, 30)
            .frame(maxHeight: .infinity, alignment: .top)
            Text(verbatim: titolo)
                .font(Tema.titolo2)
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
                .padding(16)
        }
        .frame(height: 188)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .padding(.top, 8)
    }

    // MARK: Numeri

    private func numeri(_ n: NuotataCompletata) -> some View {
        HStack(spacing: 8) {
            cella(FormatiUI.numero(n.metri), "recap.numero.metri")
            cella("\(FormatoTempo.minutiArrotondati(n.durataSecondi))", "recap.numero.minuti")
            if let previsti = workout?.metriTotali, previsti > 0 {
                let percento = min(100, Int((Double(n.metri) / Double(previsti) * 100).rounded()))
                cella("\(percento)%", "recap.numero.programma")
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func cella(_ valore: String, _ etichetta: String) -> some View {
        VStack(spacing: 2) {
            Text(verbatim: valore)
                .font(Tema.titolo2)
                .foregroundStyle(Tema.testo)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(LocalizedStringKey(etichetta))
                .font(Tema.piccolo.weight(.semibold))
                .foregroundStyle(Tema.testoSecondario)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Tema.carta))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Tema.bordo, lineWidth: 1))
    }

    // MARK: Cosa spicca

    private func sezione(_ chiave: String) -> some View {
        Text(LocalizedStringKey(chiave))
            .font(Tema.piccolo.weight(.heavy))
            .foregroundStyle(Tema.testoSecondario)
            .padding(.leading, 2)
            .padding(.top, 4)
    }

    private func rigaEvidenza(_ e: Evidenza) -> some View {
        let (icona, colore, riga) = descrizione(e)
        return HStack(spacing: 10) {
            Image(systemName: icona)
                .font(.system(.footnote, design: .rounded).weight(.heavy))
                .foregroundStyle(Tema.navy)
                .frame(width: 28, height: 28)
                .background(Circle().fill(colore))
                .accessibilityHidden(true)
            Text(verbatim: riga)
                .font(Tema.corpo.weight(.semibold))
                .foregroundStyle(Tema.testo)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Tema.carta))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Tema.bordo, lineWidth: 1))
        .accessibilityElement(children: .combine)
    }

    private func descrizione(_ e: Evidenza) -> (String, Color, String) {
        switch e {
        case .piuLunga(let metri):
            return ("star.fill", Color(squaloHex: 0xFFC857), testo("recap.spicca.piuLunga", FormatiUI.numero(metri)))
        case .ritmoMigliore(let s):
            return ("star.fill", Color(squaloHex: 0xFFC857), testo("recap.spicca.ritmoMigliore", FormatoRitmo.minutiSecondi(Double(s))))
        case .piuVeloceDellUltima(let s):
            return ("bolt.fill", Tema.turcheseChiaro, testo("recap.spicca.piuVeloce", s))
        case .programmaCompleto:
            return ("checkmark", Color(squaloHex: 0x5CCB9B), testo("recap.spicca.completo"))
        case .programmaParziale(let fatti, let previsti):
            return ("checkmark", Tema.turcheseChiaro, testo("recap.spicca.parziale", FormatiUI.numero(fatti), FormatiUI.numero(previsti)))
        case .obiettivoSettimana(let fatte, let totale):
            let chiave = fatte >= totale ? "recap.spicca.obiettivoRaggiunto" : "recap.spicca.obiettivo"
            return ("target", Tema.turcheseChiaro, testo(chiave, fatte, totale))
        case .serieSettimane(let n):
            return ("flame.fill", Color(squaloHex: 0xFFC857), testo("recap.spicca.serie", n))
        }
    }

    // MARK: Commento del coach

    private func commento(coach: CoachID, sensazione: Sensazione?, nuotata: NuotataCompletata?, errore: ErroreComune?) -> some View {
        var frasi: [String] = []
        switch sensazione {
        case .dura:
            frasi.append(testo("recap.commento.dura"))
            switch nuotata?.motivoDifficolta {
            case .fiato: frasi.append(testo("recap.commento.dura.fiato"))
            case .stanchezza: frasi.append(testo("recap.commento.dura.stanchezza"))
            case .esercizio: frasi.append(testo("recap.commento.dura.esercizio"))
            default: frasi.append(testo("recap.commento.dura.altro"))
            }
        case .facile:
            frasi.append(testo("recap.commento.facile"))
        default:
            let previsti = workout?.metriTotali ?? 0
            let fatti = nuotata?.metri ?? 0
            if previsti > 0, Double(fatti) < Double(previsti) * Recap.sogliaProgrammaCompleto {
                frasi.append(testo("recap.commento.giusta.parziale", FormatiUI.numero(fatti), FormatiUI.numero(previsti)))
            } else {
                frasi.append(testo("recap.commento.giusta.completo"))
            }
        }
        if let errore {
            frasi.append(testo("recap.commento.consiglio", Self.minuscola(errore.correzione)))
        }
        return VStack(alignment: .leading, spacing: 4) {
            Text(verbatim: coach.nome)
                .font(Tema.piccolo.weight(.heavy))
                .foregroundStyle(Tema.coralloOmbra)
            Text(verbatim: frasi.joined(separator: " "))
                .font(Tema.corpo)
                .foregroundStyle(Tema.testo)
                .fixedSize(horizontal: false, vertical: true)
        }
        .carta()
        .accessibilityElement(children: .combine)
    }

    /// "Ruota testa, spalle..." -> "ruota testa, spalle..." (per incastrarla in una frase).
    private static func minuscola(_ s: String) -> String {
        guard let prima = s.first else { return s }
        return prima.lowercased() + s.dropFirst()
    }

    // MARK: Consiglio tecnico

    private func consiglio(_ e: ErroreComune) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("recap.consiglio.tipo")
                .font(Tema.piccolo.weight(.heavy))
                .foregroundStyle(Tema.navy)
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(Capsule().fill(Tema.turchese))
            // Il testo viene da content/ (italiano, non ancora localizzato).
            Text(verbatim: e.nome)
                .font(Tema.sottotitolo)
                .foregroundStyle(Tema.testo)
            Text(verbatim: e.comeSiRiconosce)
                .font(Tema.corpo)
                .foregroundStyle(Tema.testoSecondario)
            (Text("recap.consiglio.cosaFare").fontWeight(.bold) + Text(verbatim: " " + e.correzione))
                .font(Tema.corpo)
                .foregroundStyle(Tema.testo)
            if let nome = e.drill.compactMap({ stato.contenuti.drill(id: $0)?.nome }).first {
                (Text("recap.consiglio.provaloCon").fontWeight(.bold) + Text(verbatim: " " + nome))
                    .font(Tema.corpo)
                    .foregroundStyle(Tema.testo)
            }
            Text("recap.consiglio.nota")
                .font(Tema.piccolo)
                .foregroundStyle(Tema.testoSecondario)
        }
        .carta()
        .overlay(alignment: .leading) {
            Capsule().fill(Tema.turchese).frame(width: 5).padding(.vertical, 14)
        }
    }

    // MARK: E adesso?

    private var prossima: some View {
        let c = stato.consiglioDiOggi()
        return VStack(alignment: .leading, spacing: 4) {
            Text("recap.adesso.titolo")
                .font(Tema.piccolo.weight(.heavy))
                .foregroundStyle(Tema.testoSecondario)
            EtichettaTipologia(tipologia: c.tipologia, forma: .pillola)
                .font(Tema.sottotitolo)
                .foregroundStyle(Tema.testo)
            Text(LocalizedStringKey("consiglio.perche.\(c.motivo.rawValue)"))
                .font(Tema.corpo)
                .foregroundStyle(Tema.testoSecondario)
        }
        .carta()
        .accessibilityElement(children: .contain)
    }

    private func recupero(dura: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("recap.recupero.titolo")
                .font(Tema.sottotitolo)
                .foregroundStyle(.white)
            Text(LocalizedStringKey(dura ? "recap.recupero.dura" : "recap.recupero.testo"))
                .font(Tema.corpo)
                .foregroundStyle(Color.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Tema.raggio, style: .continuous)
                .fill(LinearGradient(colors: [Tema.navyChiaro, Tema.navy], startPoint: .top, endPoint: .bottom))
        )
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Personaggio del recap

/// Personaggio animato (festa o stanco) che mantiene la proporzione del fotogramma. Si ferma con "Riduci movimento" e quando l'app non è in primo piano.
struct SqualoRecap: View {
    @Environment(StatoApp.self) private var stato
    let stanco: Bool

    private var foglio: FoglioPersonaggio {
        let p = Personaggio.con(id: stato.profilo.personaggio)
        return stanco ? p.stanco : p.festa
    }

    @Environment(\.accessibilityReduceMotion) private var riduciMovimento
    @Environment(\.scenePhase) private var fase

    var body: some View {
        let ferma = riduciMovimento || fase != .active
        TimelineView(.animation(minimumInterval: 1.0 / 15.0, paused: ferma)) { linea in
            let t = ferma ? 0 : linea.date.timeIntervalSinceReferenceDate
            Canvas { contesto, dimensione in
                let immagine = contesto.resolve(Image(foglio.nome))
                let i = ferma ? 0 : Int(t * 12) % foglio.totale
                let colonna = i % FoglioPersonaggio.colonne
                let riga = i / FoglioPersonaggio.colonne
                let tutta = CGRect(x: -CGFloat(colonna) * dimensione.width, y: -CGFloat(riga) * dimensione.height,
                                   width: dimensione.width * CGFloat(FoglioPersonaggio.colonne),
                                   height: dimensione.height * CGFloat(FoglioPersonaggio.righe))
                contesto.clip(to: Path(CGRect(origin: .zero, size: dimensione)))
                contesto.draw(immagine, in: tutta)
            }
        }
        .aspectRatio(1 / foglio.proporzione, contentMode: .fit)
        .accessibilityHidden(true)
    }
}
