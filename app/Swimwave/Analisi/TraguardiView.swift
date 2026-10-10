import SwiftUI
import UIKit
import SwimwaveCore

// La collezione delle medaglie, il dettaglio che si inclina col telefono e la celebrazione a schermo intero.
// Grafica disegnata da noi in SwiftUI (vedi MedagliaMetallica.swift), senza immagini esterne.

extension Medaglia {
    /// Nome mostrato, dalla chiave "medaglia.<id>.nome".
    var nome: String { testo("medaglia.\(id).nome") }

    /// Descrizione breve, dalla chiave "medaglia.<id>.descrizione".
    var descrizione: String { testo("medaglia.\(id).descrizione") }

    /// Simbolo di sistema al centro della medaglia.
    var simbolo: String {
        switch id {
        case "prima-nuotata", "metri-1000": return "drop.fill"
        case "nuotate-10", "nuotate-25": return "figure.pool.swim"
        case "nuotate-50", "metri-10000", "serie-12", "serie-26", "test-ritmo": return "star.fill"
        case "nuotate-100", "metri-50000", "metri-100000", "serie-52": return "trophy.fill"
        case "metri-5000": return "flag.fill"
        case "metri-25000", "serie-2", "serie-4", "serie-8": return "flame.fill"
        case "traversata-messina": return "ferry.fill"
        case "traversata-bonifacio": return "sailboat.fill"
        case "traversata-gibilterra": return "globe.europe.africa.fill"
        case "traversata-manica": return "water.waves"
        case "fedele-vasca": return "heart.fill"
        case "cento-continui": return "infinity"
        default: return categoria == .percorso ? "flag.fill" : "star.fill"
        }
    }

    /// Scritta breve sul bordo della medaglia: la soglia ("10", "5k", "3,1k", "4"); vuota per le medaglie senza numero.
    var scrittaSoglia: String {
        switch categoria {
        case .nuotate:
            return soglia > 1 ? String(soglia) : ""
        case .distanza:
            return soglia >= 1000 ? "\(soglia / 1000)k" : String(soglia)
        case .traversate:
            if soglia % 1000 == 0 { return "\(soglia / 1000)k" }
            return String(format: "%.1fk", Double(soglia) / 1000).replacingOccurrences(of: ".", with: ",")
        case .costanza:
            return String(soglia)
        case .percorso:
            if id.hasPrefix("tappa-") { return String(id.dropFirst("tappa-".count)) }
            return ""
        }
    }

    /// Frazione di avanzamento verso la soglia, tra 0 e 1.
    var frazione: Double {
        guard soglia > 0 else { return ottenuta ? 1 : 0 }
        return max(0, min(1, Double(attuale) / Double(soglia)))
    }

    /// "3.200 di 5.000 m" oppure "3 di 10". Vuoto per le medaglie con soglia 1 (o si ha, o non si ha).
    var testoAvanzamento: String {
        guard soglia > 1 else { return "" }
        let a = FormatiUI.numero(min(attuale, soglia))
        let s = FormatiUI.numero(soglia)
        let inMetri = categoria == .distanza || categoria == .traversate
        return inMetri ? testo("medaglia.avanzamento.metri", a, s) : testo("medaglia.avanzamento", a, s)
    }

    var titoloCategoria: String {
        switch categoria {
        case .nuotate: return testo("traguardi.categoria.nuotate")
        case .distanza: return testo("traguardi.categoria.distanza")
        case .traversate: return testo("traguardi.categoria.traversate")
        case .costanza: return testo("traguardi.categoria.costanza")
        case .percorso: return testo("traguardi.categoria.percorso")
        }
    }
}

// MARK: - Fondale

/// Sfondo scuro con un alone del colore del metallo.
private struct FondaleMedaglia: View {
    var metallo: TavolozzaMetallo?

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.black, Tema.navy, Color.black], startPoint: .top, endPoint: .bottom)
            if let metallo {
                RadialGradient(colors: [metallo.medio.opacity(0.35), Color.clear],
                               center: .center, startRadius: 10, endRadius: 380)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Collezione

/// La collezione dei traguardi: un anello con il totale, la prossima medaglia e le medaglie per categoria.
struct TraguardiView: View {
    @Environment(StatoApp.self) private var stato
    @State private var selezionata: Medaglia?

    private let colonne = Array(repeating: GridItem(.flexible(), spacing: 8, alignment: .top), count: 3)

    var body: some View {
        let tutte = stato.medaglie
        let ottenute = tutte.filter { $0.ottenuta }.count
        ScrollView {
            VStack(spacing: 28) {
                testata(ottenute: ottenute, totale: tutte.count)
                if let prossima = tutte.filter({ !$0.ottenuta && $0.soglia > 1 && $0.attuale > 0 })
                    .max(by: { $0.frazione < $1.frazione }) {
                    cartaProssima(prossima)
                }
                ForEach(CategoriaMedaglia.allCases, id: \.self) { categoria in
                    let dellaCategoria = tutte.filter { $0.categoria == categoria }
                    if !dellaCategoria.isEmpty {
                        sezione(categoria, dellaCategoria)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(FondaleMedaglia(metallo: nil))
        .navigationTitle(Text("traguardi.titolo"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .preferredColorScheme(.dark)
        .fullScreenCover(item: $selezionata) { medaglia in
            DettaglioMedaglia(medaglia: medaglia)
        }
    }

    // MARK: Testata

    private func testata(ottenute: Int, totale: Int) -> some View {
        let frazione = totale > 0 ? Double(ottenute) / Double(totale) : 0
        return VStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.10), lineWidth: 16)
                Circle()
                    .trim(from: 0, to: max(0.001, frazione))
                    .stroke(
                        AngularGradient(colors: [Tema.turchese, Tema.turcheseChiaro, Tema.corallo, Tema.turchese],
                                        center: .center),
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: Tema.turchese.opacity(0.5), radius: 10)
                VStack(spacing: 0) {
                    Text(verbatim: "\(ottenute)")
                        .font(.system(size: 58, weight: .heavy, design: .rounded))
                        .foregroundStyle(Tema.testo)
                        .monospacedDigit()
                    Text(verbatim: testo("traguardi.suTotale", totale))
                        .font(Tema.corpo)
                        .foregroundStyle(Tema.testoSecondario)
                }
            }
            .frame(width: 176, height: 176)
            .padding(.top, 8)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: testo("traguardi.conteggio", ottenute, totale)))
            Text("traguardi.titolo2")
                .font(Tema.titolo2)
                .foregroundStyle(Tema.testo)
                .accessibilityAddTraits(.isHeader)
        }
    }

    private func cartaProssima(_ medaglia: Medaglia) -> some View {
        Button {
            selezionata = medaglia
        } label: {
            HStack(spacing: 14) {
                MedagliaMetallica(medaglia: medaglia, dimensione: 56)
                    .opacity(0.9)
                VStack(alignment: .leading, spacing: 6) {
                    Text("traguardi.prossima")
                        .font(Tema.piccolo.weight(.bold))
                        .foregroundStyle(Tema.testoSecondario)
                    Text(verbatim: medaglia.nome)
                        .font(Tema.sottotitolo)
                        .foregroundStyle(Tema.testo)
                    BarraAvanzamento(frazione: medaglia.frazione)
                    Text(verbatim: medaglia.testoAvanzamento)
                        .font(Tema.piccolo)
                        .foregroundStyle(Tema.testoSecondario)
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: Tema.raggio, style: .continuous)
                    .fill(Color.white.opacity(0.07))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Tema.raggio, style: .continuous)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: testo("traguardi.accessibilita.inCorso", medaglia.nome, medaglia.testoAvanzamento)))
        .accessibilityAddTraits(.isButton)
    }

    // MARK: Sezioni

    private func sezione(_ categoria: CategoriaMedaglia, _ medaglie: [Medaglia]) -> some View {
        let fatte = medaglie.filter { $0.ottenuta }.count
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(verbatim: medaglie[0].titoloCategoria)
                    .font(Tema.piccolo.weight(.heavy))
                    .textCase(.uppercase)
                    .tracking(1.5)
                    .foregroundStyle(Tema.testoSecondario)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Text(verbatim: "\(fatte)/\(medaglie.count)")
                    .font(Tema.piccolo.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(Tema.testoSecondario)
            }
            LazyVGrid(columns: colonne, alignment: .center, spacing: 22) {
                ForEach(medaglie) { medaglia in
                    cella(medaglia)
                }
            }
        }
    }

    private func cella(_ medaglia: Medaglia) -> some View {
        Button {
            selezionata = medaglia
        } label: {
            VStack(spacing: 8) {
                MedagliaMetallica(medaglia: medaglia, dimensione: 92)
                Text(verbatim: medaglia.nome)
                    .font(Tema.piccolo.weight(.semibold))
                    .foregroundStyle(medaglia.ottenuta ? Tema.testo : Tema.testoSecondario)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)
                if !medaglia.ottenuta && medaglia.soglia > 1 && medaglia.attuale > 0 {
                    BarraAvanzamento(frazione: medaglia.frazione)
                        .padding(.horizontal, 6)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: etichettaAccessibile(medaglia)))
        .accessibilityAddTraits(.isButton)
    }

    private func etichettaAccessibile(_ medaglia: Medaglia) -> String {
        if medaglia.ottenuta {
            return testo("traguardi.accessibilita.ottenuto", medaglia.nome)
        }
        let avanzamento = medaglia.testoAvanzamento
        if avanzamento.isEmpty {
            return testo("traguardi.accessibilita.daOttenere", medaglia.nome)
        }
        return testo("traguardi.accessibilita.inCorso", medaglia.nome, avanzamento)
    }
}

// MARK: - Dettaglio

/// Una medaglia in grande a schermo intero. Si inclina con il telefono e con il dito; l'inclinazione sposta anche i riflessi.
struct DettaglioMedaglia: View {
    let medaglia: Medaglia

    @Environment(\.dismiss) private var chiudi
    @Environment(\.accessibilityReduceMotion) private var riduciMovimento
    @State private var motore = MotoreInclinazione()
    @State private var trascinamento: CGSize = .zero

    private var inclinazione: CGSize {
        CGSize(width: max(-1, min(1, motore.x + trascinamento.width)),
               height: max(-1, min(1, motore.y + trascinamento.height)))
    }

    var body: some View {
        let tilt = inclinazione
        ZStack {
            FondaleMedaglia(metallo: medaglia.ottenuta ? medaglia.metallo : nil)
            if medaglia.ottenuta && !riduciMovimento {
                RaggiDiLuce(colore: medaglia.metallo.luce)
                    .ignoresSafeArea()
            }
            VStack(spacing: 18) {
                HStack {
                    Spacer()
                    Button {
                        chiudi()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Color.white)
                            .frame(width: 48, height: 48)
                    }
                    .accessibilityLabel(Text("comune.chiudi"))
                }
                Spacer(minLength: 0)
                MedagliaMetallica(medaglia: medaglia, dimensione: 250, inclinazione: tilt)
                    .rotation3DEffect(.degrees(Double(tilt.width) * 24), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
                    .rotation3DEffect(.degrees(Double(-tilt.height) * 24), axis: (x: 1, y: 0, z: 0), perspective: 0.5)
                    .gesture(
                        DragGesture()
                            .onChanged { valore in
                                trascinamento = CGSize(width: valore.translation.width / 110,
                                                       height: valore.translation.height / 110)
                            }
                            .onEnded { _ in
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) {
                                    trascinamento = .zero
                                }
                            }
                    )
                    .padding(.vertical, 12)
                testi
                Spacer(minLength: 0)
                if medaglia.ottenuta {
                    PulsanteCondividiCartina(
                        titoloAnteprima: medaglia.nome,
                        messaggio: testo("medaglia.condividi.messaggio", medaglia.nome),
                        chiave: medaglia.id
                    ) {
                        CarticinaMedaglia(medaglia: medaglia)
                    }
                    .buttonStyle(.primario)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .preferredColorScheme(.dark)
        .onAppear { if !riduciMovimento { motore.avvia() } }
        .onDisappear { motore.ferma() }
    }

    private var testi: some View {
        VStack(spacing: 10) {
            Text(verbatim: medaglia.nome)
                .font(Tema.titolo2)
                .foregroundStyle(Tema.testo)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            Text(verbatim: medaglia.descrizione)
                .font(Tema.corpo)
                .foregroundStyle(Tema.testoSecondario)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if medaglia.ottenuta {
                Label {
                    Text("medaglia.ottenuta")
                } icon: {
                    Image(systemName: "checkmark.seal.fill")
                }
                .font(Tema.sottotitolo)
                .foregroundStyle(medaglia.metallo.luce)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule().fill(medaglia.metallo.medio.opacity(0.25)))
            } else if medaglia.soglia > 1 {
                VStack(spacing: 8) {
                    BarraAvanzamento(frazione: medaglia.frazione)
                    Text(verbatim: medaglia.testoAvanzamento)
                        .font(Tema.sottotitolo)
                        .foregroundStyle(Tema.testo)
                }
                .padding(.horizontal, 24)
            } else {
                Text("medaglia.nonAncora")
                    .font(Tema.corpo)
                    .foregroundStyle(Tema.testoSecondario)
            }
        }
    }
}

// MARK: - Carta da condividere

/// La medaglia per la condivisione come immagine (vedi `CarticinaCondivisibile`): solo valori, nessun nome dell'utente.
struct CarticinaMedaglia: View {
    let medaglia: Medaglia

    var body: some View {
        VStack(spacing: 14) {
            MedagliaMetallica(medaglia: medaglia, dimensione: 220, inclinazione: CGSize(width: 0.25, height: -0.1))
                .padding(.top, 4)
            Text(verbatim: medaglia.nome)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .multilineTextAlignment(.center)
            Text(verbatim: medaglia.descrizione)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .multilineTextAlignment(.center)
                .opacity(0.85)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Celebrazione

/// Schermata a tutto schermo per una medaglia appena ottenuta: coriandoli, raggi di luce, medaglia che gira e si ferma.
/// Con "Riduci movimento" attivo restano solo la medaglia e i testi.
struct CelebrazioneMedaglia: View {
    let medaglia: Medaglia
    /// Quante altre medaglie nuove aspettano dopo questa.
    let restanti: Int
    let alChiudere: () -> Void

    @Environment(\.accessibilityReduceMotion) private var riduciMovimento
    @State private var motore = MotoreInclinazione()
    @State private var trascinamento: CGSize = .zero
    @State private var appare = false
    @State private var rotazione: Double = 540

    private var inclinazione: CGSize {
        CGSize(width: max(-1, min(1, motore.x + trascinamento.width)),
               height: max(-1, min(1, motore.y + trascinamento.height)))
    }

    var body: some View {
        let m = medaglia.metallo
        let tilt = inclinazione
        ZStack {
            FondaleMedaglia(metallo: m)
            if !riduciMovimento {
                RaggiDiLuce(colore: m.luce)
                    .ignoresSafeArea()
                Coriandoli(colori: [m.luce, m.medio, Tema.corallo, Tema.turchese, Tema.turcheseChiaro, Color.white])
                    .ignoresSafeArea()
            }
            VStack(spacing: 16) {
                Spacer(minLength: 0)
                Text("celebrazione.titolo")
                    .font(Tema.sottotitolo)
                    .textCase(.uppercase)
                    .tracking(4)
                    .foregroundStyle(m.luce)
                    .opacity(appare ? 1 : 0)
                MedagliaMetallica(medaglia: medaglia, dimensione: 260, inclinazione: tilt)
                    .rotation3DEffect(.degrees(rotazione), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
                    .rotation3DEffect(.degrees(Double(tilt.width) * 22), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
                    .rotation3DEffect(.degrees(Double(-tilt.height) * 22), axis: (x: 1, y: 0, z: 0), perspective: 0.5)
                    .scaleEffect(appare ? 1 : 0.15)
                    .gesture(
                        DragGesture()
                            .onChanged { valore in
                                trascinamento = CGSize(width: valore.translation.width / 110,
                                                       height: valore.translation.height / 110)
                            }
                            .onEnded { _ in
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) {
                                    trascinamento = .zero
                                }
                            }
                    )
                    .padding(.vertical, 10)
                Text(verbatim: medaglia.nome)
                    .font(Tema.titolo)
                    .foregroundStyle(Tema.testo)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)
                    .opacity(appare ? 1 : 0)
                    .accessibilityAddTraits(.isHeader)
                Text(verbatim: medaglia.descrizione)
                    .font(Tema.corpo)
                    .foregroundStyle(Tema.testoSecondario)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(appare ? 1 : 0)
                Spacer(minLength: 0)
                VStack(spacing: 6) {
                    Button {
                        alChiudere()
                    } label: {
                        Text(LocalizedStringKey(restanti > 0 ? "celebrazione.prossima" : "celebrazione.continua"))
                    }
                    .buttonStyle(.primario)
                    PulsanteCondividiCartina(
                        titoloAnteprima: medaglia.nome,
                        messaggio: testo("medaglia.condividi.messaggio", medaglia.nome),
                        chiave: medaglia.id
                    ) {
                        CarticinaMedaglia(medaglia: medaglia)
                    }
                    .buttonStyle(.secondario)
                }
                .opacity(appare ? 1 : 0)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            if riduciMovimento {
                appare = true
                rotazione = 0
                return
            }
            withAnimation(.spring(response: 1.1, dampingFraction: 0.62)) {
                appare = true
                rotazione = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                UIImpactFeedback.colpo()
            }
            motore.avvia()
        }
        .onDisappear { motore.ferma() }
        .accessibilityAction(.escape) { alChiudere() }
    }
}

/// Un colpo di vibrazione deciso, per il momento in cui la medaglia si ferma.
private enum UIImpactFeedback {
    static func colpo() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }
}

#Preview("Medaglie") {
    let m = Medaglia(id: "traversata-messina", ottenuta: true, soglia: 3100, attuale: 3200, categoria: .traversate)
    let l = Medaglia(id: "metri-5000", ottenuta: false, soglia: 5000, attuale: 2000, categoria: .distanza)
    return HStack(spacing: 20) {
        MedagliaMetallica(medaglia: m, dimensione: 120)
        MedagliaMetallica(medaglia: l, dimensione: 120)
    }
    .padding()
    .background(Color.black)
}
