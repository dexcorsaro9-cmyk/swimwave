import SwiftUI
import SwimwaveCore

// Grafica dei traguardi: disegnata da noi in SwiftUI (cerchi, anelli e simboli di sistema), senza immagini esterne.

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
        default: return categoria == .percorso ? "flag.fill" : "star.fill"
        }
    }

    /// Colore dell'anello, per categoria.
    var coloreAnello: Color {
        switch categoria {
        case .nuotate, .costanza: return Tema.turchese
        case .distanza, .percorso: return Tema.corallo
        }
    }

    /// Scritta breve sul bordo della medaglia: la soglia ("10", "5k", "4"); vuota per le medaglie senza numero.
    var scrittaSoglia: String {
        switch categoria {
        case .nuotate:
            return soglia > 1 ? String(soglia) : ""
        case .distanza:
            return soglia >= 1000 ? "\(soglia / 1000)k" : String(soglia)
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
        return categoria == .distanza ? testo("medaglia.avanzamento.metri", a, s) : testo("medaglia.avanzamento", a, s)
    }
}

/// Medaglia tonda: anello colorato, disco navy e simbolo; se non ottenuta, grigio tenue con il lucchetto.
struct MedagliaTonda: View {
    let medaglia: Medaglia
    var dimensione: CGFloat = 76

    var body: some View {
        ZStack {
            if medaglia.ottenuta {
                Circle().fill(medaglia.coloreAnello)
                Circle()
                    .fill(LinearGradient(colors: [Tema.navyChiaro, Tema.navy],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .padding(dimensione * 0.08)
                Circle()
                    .strokeBorder(Tema.testoSuNavy.opacity(0.25), lineWidth: max(1, dimensione * 0.012))
                    .padding(dimensione * 0.16)
                Image(systemName: medaglia.simbolo)
                    .font(.system(size: dimensione * 0.36, weight: .bold, design: .rounded))
                    .foregroundStyle(Tema.testoSuNavy)
                if !medaglia.scrittaSoglia.isEmpty {
                    Text(verbatim: medaglia.scrittaSoglia)
                        .font(.system(size: dimensione * 0.17, weight: .heavy, design: .rounded))
                        .foregroundStyle(Tema.navy)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .padding(.horizontal, dimensione * 0.08)
                        .padding(.vertical, dimensione * 0.02)
                        .background(Capsule().fill(medaglia.coloreAnello))
                        .overlay(Capsule().stroke(Tema.navy, lineWidth: max(1, dimensione * 0.02)))
                        .offset(y: dimensione * 0.40)
                }
            } else {
                Circle().fill(Tema.testoSecondario.opacity(0.12))
                Circle()
                    .strokeBorder(Tema.testoSecondario.opacity(0.25), lineWidth: max(2, dimensione * 0.06))
                Image(systemName: "lock.fill")
                    .font(.system(size: dimensione * 0.30, weight: .bold, design: .rounded))
                    .foregroundStyle(Tema.testoSecondario.opacity(0.6))
            }
        }
        .frame(width: dimensione, height: dimensione)
        .accessibilityHidden(true)
    }
}

/// La collezione dei traguardi, divisi per categoria.
struct TraguardiView: View {
    @Environment(StatoApp.self) private var stato
    @State private var selezionata: Medaglia?

    private let colonne = Array(repeating: GridItem(.flexible(), spacing: 12, alignment: .top), count: 3)

    var body: some View {
        let tutte = stato.medaglie
        let ottenute = tutte.filter { $0.ottenuta }.count
        SchermataAnalisi {
            VStack(alignment: .leading, spacing: 4) {
                Text("traguardi.titolo").font(Tema.titolo2)
                Text(verbatim: testo("traguardi.conteggio", ottenute, tutte.count))
                    .font(Tema.corpo)
                    .opacity(0.9)
            }
        } contenuto: {
            ForEach(CategoriaMedaglia.allCases, id: \.self) { categoria in
                let dellaCategoria = tutte.filter { $0.categoria == categoria }
                if !dellaCategoria.isEmpty {
                    CartaAnalisi(titolo: titolo(categoria)) {
                        LazyVGrid(columns: colonne, alignment: .center, spacing: 18) {
                            ForEach(dellaCategoria) { medaglia in
                                cella(medaglia)
                            }
                        }
                    }
                }
            }
        }
        .sheet(item: $selezionata) { medaglia in
            FoglioMedaglia(medaglia: medaglia)
        }
    }

    private func titolo(_ categoria: CategoriaMedaglia) -> String {
        switch categoria {
        case .nuotate: return testo("traguardi.categoria.nuotate")
        case .distanza: return testo("traguardi.categoria.distanza")
        case .costanza: return testo("traguardi.categoria.costanza")
        case .percorso: return testo("traguardi.categoria.percorso")
        }
    }

    private func cella(_ medaglia: Medaglia) -> some View {
        Button {
            selezionata = medaglia
        } label: {
            VStack(spacing: 6) {
                MedagliaTonda(medaglia: medaglia, dimensione: 76)
                Text(verbatim: medaglia.nome)
                    .font(Tema.piccolo.weight(.semibold))
                    .foregroundStyle(medaglia.ottenuta ? Tema.testo : Tema.testoSecondario)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)
                if !medaglia.ottenuta && medaglia.soglia > 1 {
                    BarraAvanzamento(frazione: medaglia.frazione)
                        .padding(.horizontal, 4)
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

/// Il foglio con una medaglia in grande: nome, descrizione, avanzamento.
struct FoglioMedaglia: View {
    let medaglia: Medaglia
    @Environment(\.dismiss) private var chiudi

    var body: some View {
        VStack(spacing: 16) {
            MedagliaTonda(medaglia: medaglia, dimensione: 160)
                .padding(.top, 28)
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
                Text("medaglia.ottenuta")
                    .font(Tema.sottotitolo)
                    .foregroundStyle(Tema.testo)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Tema.turcheseChiaro.opacity(0.35)))
            } else {
                VStack(spacing: 8) {
                    if medaglia.soglia > 1 {
                        BarraAvanzamento(frazione: medaglia.frazione)
                        Text(verbatim: medaglia.testoAvanzamento)
                            .font(Tema.sottotitolo)
                            .foregroundStyle(Tema.testo)
                    } else {
                        Text("medaglia.nonAncora")
                            .font(Tema.corpo)
                            .foregroundStyle(Tema.testoSecondario)
                    }
                }
                .padding(.horizontal, 32)
            }
            Spacer(minLength: 8)
            Button {
                chiudi()
            } label: {
                Text("comune.chiudi")
            }
            .buttonStyle(.secondario)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
        .sfondoApp()
        .presentationDetents([.medium, .large])
    }
}
