import SwiftUI
import SwimwaveCore

/// Le tappe di content/percorso.json. Guidano ma non bloccano: si può saltare avanti o tornare indietro.
struct PercorsoView: View {
    @Environment(StatoApp.self) private var stato
    @State private var tappaAperta: Tappa?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                IntestazioneOnda {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("percorso.titolo").font(Tema.titolo2)
                        Text("percorso.sottotitolo").font(Tema.corpo).opacity(0.9)
                    }
                }
                LazyVStack(spacing: 12) {
                    if stato.contenuti.tappe.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("percorso.vuoto.titolo")
                                .font(Tema.sottotitolo)
                                .foregroundStyle(Tema.testo)
                            Text("percorso.vuoto.testo")
                                .font(Tema.corpo)
                                .foregroundStyle(Tema.testoSecondario)
                        }
                        .carta()
                    } else {
                        ForEach(stato.contenuti.tappe) { tappa in
                            Button { tappaAperta = tappa } label: {
                                RigaTappa(tappa: tappa, attuale: tappa.id == stato.tappaAttuale,
                                          completata: tappa.id < stato.tappaAttuale)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .sfondoApp()
        .sheet(item: $tappaAperta) { tappa in
            DettaglioTappaView(tappa: tappa)
        }
    }
}

private struct RigaTappa: View {
    let tappa: Tappa
    let attuale: Bool
    let completata: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(completata ? Tema.turchese : (attuale ? Tema.corallo : Tema.carta))
                Circle().stroke(completata ? Tema.turchese : (attuale ? Tema.coralloOmbra : Tema.turchese), lineWidth: 2)
                if completata {
                    Image(systemName: "checkmark")
                        .font(.system(.headline, design: .rounded).weight(.heavy))
                        .foregroundStyle(Tema.navy)
                } else {
                    Text(verbatim: "\(tappa.id)")
                        .font(Tema.sottotitolo)
                        .foregroundStyle(attuale ? Tema.navy : Tema.testo)
                }
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 3) {
                // Testi da content/percorso.json (italiano, non ancora localizzati).
                Text(verbatim: tappa.nome)
                    .font(Tema.sottotitolo)
                    .foregroundStyle(Tema.testo)
                    .multilineTextAlignment(.leading)
                Text(verbatim: tappa.obiettivo)
                    .font(Tema.piccolo)
                    .foregroundStyle(Tema.testoSecondario)
                    .multilineTextAlignment(.leading)
                if attuale {
                    Text("percorso.tappaAttuale")
                        .font(Tema.piccolo.weight(.bold))
                        .foregroundStyle(Tema.coralloOmbra)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .foregroundStyle(Tema.testoSecondario)
        }
        .carta(padding: 14)
        .accessibilityElement(children: .combine)
    }
}

struct DettaglioTappaView: View {
    let tappa: Tappa
    @Environment(StatoApp.self) private var stato
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if tappa.stato == .bozza {
                        // Le bozze si vedono solo nelle build di debug.
                        Etichetta(contenuto: "BOZZA (solo debug)")
                    }
                    sezione("tappa.obiettivo", tappa.obiettivo)
                    sezione("tappa.test", tappa.test)

                    let drill = tappa.drill.compactMap { stato.contenuti.drill(id: $0) }
                    if !drill.isEmpty {
                        Text("tappa.drill").font(Tema.sottotitolo).foregroundStyle(Tema.testo)
                        ForEach(drill) { d in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(verbatim: d.nome).font(Tema.sottotitolo).foregroundStyle(Tema.testo)
                                Text(verbatim: d.scopo).font(Tema.corpo).foregroundStyle(Tema.testoSecondario)
                                Text(verbatim: d.esecuzione).font(Tema.corpo).foregroundStyle(Tema.testo)
                                Text(verbatim: testo("tappa.daEvitare", d.erroreDaEvitare))
                                    .font(Tema.piccolo).foregroundStyle(Tema.testoSecondario)
                            }
                            .carta()
                        }
                    }

                    let errori = tappa.errori.compactMap { stato.contenuti.errore(id: $0) }
                    if !errori.isEmpty {
                        Text("tappa.errori").font(Tema.sottotitolo).foregroundStyle(Tema.testo)
                        ForEach(errori) { e in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(verbatim: e.nome).font(Tema.sottotitolo).foregroundStyle(Tema.testo)
                                Text(verbatim: e.comeSiRiconosce).font(Tema.corpo).foregroundStyle(Tema.testoSecondario)
                                Text(verbatim: e.correzione).font(Tema.corpo).foregroundStyle(Tema.testo)
                            }
                            .carta()
                        }
                    }

                    if tappa.id != stato.tappaAttuale {
                        Button {
                            stato.vai(allaTappa: tappa.id)
                            dismiss()
                        } label: {
                            Text("tappa.vaiQui")
                        }
                        .buttonStyle(.primario)
                        .padding(.top, 8)
                    }
                }
                .padding(16)
            }
            .sfondoApp()
            .navigationTitle(Text(verbatim: tappa.nome))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("comune.chiudi") { dismiss() }
                }
            }
        }
    }

    private func sezione(_ titolo: String, _ contenuto: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(LocalizedStringKey(titolo)).font(Tema.sottotitolo).foregroundStyle(Tema.testo)
            Text(verbatim: contenuto).font(Tema.corpo).foregroundStyle(Tema.testoSecondario)
        }
        .carta()
    }
}
