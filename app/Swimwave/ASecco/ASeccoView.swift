import SwiftUI

/// Esercizi a secco (mobilità, spalle, core, gambe) letti da content/a-secco.json.
/// Si vedono solo quelli approvati (nelle build di debug anche le bozze). Va presentata come foglio: ha il suo `NavigationStack`.
struct ASeccoView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var esercizi: [EsercizioASecco] = []
    @State private var caricato = false

    /// Ordine dei gruppi e valori di `gruppo` nel file.
    private static let ordineGruppi = ["mobilita", "spalle", "core", "gambe"]

    private struct GruppoASecco: Identifiable {
        let id: String
        let titolo: String
        let esercizi: [EsercizioASecco]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    avviso
                    if caricato && esercizi.isEmpty {
                        vuoto
                    } else {
                        ForEach(gruppi) { gruppo in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(verbatim: gruppo.titolo)
                                    .font(Tema.sottotitolo)
                                    .foregroundStyle(Tema.testo)
                                ForEach(gruppo.esercizi) { e in
                                    riga(e)
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
            .sfondoApp()
            .navigationTitle(Text("asecco.titolo"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("comune.chiudi") { dismiss() }
                }
            }
        }
        .onAppear {
            if !caricato {
                esercizi = CaricatoreASecco.carica()
                caricato = true
            }
        }
    }

    // MARK: Parti

    private var avviso: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle.fill")
                .font(.system(.title3, design: .rounded))
                .foregroundStyle(Tema.turchese)
                .accessibilityHidden(true)
            Text("asecco.avviso")
                .font(Tema.corpo)
                .foregroundStyle(Tema.testo)
                .fixedSize(horizontal: false, vertical: true)
        }
        .carta()
    }

    private var vuoto: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("asecco.vuoto.titolo")
                .font(Tema.sottotitolo)
                .foregroundStyle(Tema.testo)
            Text("asecco.vuoto.testo")
                .font(Tema.corpo)
                .foregroundStyle(Tema.testoSecondario)
        }
        .carta()
    }

    private var gruppi: [GruppoASecco] {
        var risultato: [GruppoASecco] = []
        for chiave in ASeccoView.ordineGruppi {
            let dentro = esercizi.filter { $0.gruppo == chiave }
            if !dentro.isEmpty {
                risultato.append(GruppoASecco(id: chiave, titolo: testo("asecco.gruppo.\(chiave)"), esercizi: dentro))
            }
        }
        // Un gruppo che qui non ha un titolo non fa sparire gli esercizi.
        let altri = esercizi.filter { !ASeccoView.ordineGruppi.contains($0.gruppo) }
        if !altri.isEmpty {
            risultato.append(GruppoASecco(id: "altri", titolo: testo("asecco.gruppo.altri"), esercizi: altri))
        }
        return risultato
    }

    private func riga(_ e: EsercizioASecco) -> some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 12) {
                if e.stato != "approvato" {
                    // Le bozze si vedono solo nelle build di debug.
                    Etichetta(contenuto: "BOZZA (solo debug)")
                }
                campo("asecco.scopo", e.scopo)
                campo("asecco.esecuzione", e.esecuzione)
                if let r = e.ripetizioni, !r.isEmpty { campo("asecco.ripetizioni", r) }
                if let a = e.attenzione, !a.isEmpty { campo("asecco.attenzione", a) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 10)
        } label: {
            // I testi vengono da content/a-secco.json (italiano, non ancora localizzati).
            Text(verbatim: e.nome)
                .font(Tema.sottotitolo)
                .foregroundStyle(Tema.testo)
                .multilineTextAlignment(.leading)
        }
        .tint(Tema.testo)
        .carta(padding: 14)
    }

    private func campo(_ chiave: String, _ valore: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(LocalizedStringKey(chiave))
                .font(Tema.piccolo.weight(.bold))
                .foregroundStyle(Tema.testoSecondario)
            Text(verbatim: valore)
                .font(Tema.corpo)
                .foregroundStyle(Tema.testo)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Lettura di content/a-secco.json

private struct EsercizioASecco: Decodable, Identifiable {
    let id: String
    let nome: String
    let gruppo: String
    let scopo: String
    let esecuzione: String
    let ripetizioni: String?
    let attenzione: String?
    let stato: String
}

private struct FileASecco: Decodable {
    let esercizi: [EsercizioASecco]
}

private enum CaricatoreASecco {
    /// Come le zone di ritmo: dal Bundle, cartella `content/`. Se il file manca o non è leggibile, nessun esercizio.
    /// Gli utenti vedono solo gli esercizi approvati (CLAUDE.md); nelle build di debug anche le bozze.
    static func carica() -> [EsercizioASecco] {
        let url = Bundle.main.url(forResource: "a-secco", withExtension: "json", subdirectory: "content")
            ?? Bundle.main.resourceURL?.appendingPathComponent("content/a-secco.json")
        guard let url,
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(FileASecco.self, from: data) else { return [] }
        #if DEBUG
        return file.esercizi
        #else
        return file.esercizi.filter { $0.stato == "approvato" }
        #endif
    }
}
