import SwiftUI
import SwimwaveCore

/// Le tappe di content/percorso.json. Guidano ma non bloccano: si può saltare avanti o tornare indietro.
struct PercorsoView: View {
    @Environment(StatoApp.self) private var stato
    @State private var foglio: FoglioPercorso?
    @State private var popup: PopupCoach?

    enum FoglioPercorso: Identifiable {
        case tappa(Tappa)
        case testRitmo
        case rifaiTestRitmo
        case aSecco

        var id: String {
            switch self {
            case .tappa(let t): return "tappa-\(t.id)"
            case .testRitmo: return "test-ritmo"
            case .rifaiTestRitmo: return "rifai-test-ritmo"
            case .aSecco: return "a-secco"
            }
        }
    }

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
                            Button { foglio = .tappa(tappa) } label: {
                                RigaTappa(tappa: tappa, attuale: tappa.id == stato.tappaAttuale,
                                          completata: stato.tappaSuperata(tappa.id))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    // Il test del ritmo è solo sui 200 m (il 400 m non si propone agli adulti). Compare quando le zone sono approvate.
                    if Funzioni.testRitmoAgliAdulti, !stato.contenuti.zone.isEmpty {
                        Button { foglio = .testRitmo } label: {
                            cartaTestRitmo
                        }
                        .buttonStyle(.plain)
                        invitoTestRitmo
                    }
                    Button { foglio = .aSecco } label: {
                        cartaASecco
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .sfondoApp()
        .sheet(item: $foglio) { f in
            switch f {
            case .tappa(let tappa):
                DettaglioTappaView(tappa: tappa) {
                    foglio = nil
                    festeggiaTappa()
                }
                .environment(stato)
            case .testRitmo:
                TestRitmoView()
                    .environment(stato)
            case .rifaiTestRitmo:
                TestRitmoView(rifacendo: true)
                    .environment(stato)
            case .aSecco:
                ASeccoView()
                    .environment(stato)
            }
        }
        .coachPopup($popup, coach: stato.profilo.coach) { _ in
            [PulsantePopup(titolo: testo("popup.bottone.grazie"), principale: true) { popup = nil }]
        }
    }

    private var cartaTestRitmo: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Tema.turchese.opacity(0.18))
                Image(systemName: "timer")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(Tema.testo)
            }
            .frame(width: 44, height: 44)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text("percorso.ritmo.titolo")
                    .font(Tema.sottotitolo)
                    .foregroundStyle(Tema.testo)
                Text(verbatim: sottotitoloTestRitmo)
                    .font(Tema.piccolo)
                    .foregroundStyle(Tema.testoSecondario)
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .foregroundStyle(Tema.testoSecondario)
        }
        .carta(padding: 14)
        .accessibilityElement(children: .combine)
    }

    /// Sotto la carta del test: se è stato fatto, dice dove si vedono i tempi obiettivo; dopo qualche settimana, un invito gentile a rifarlo.
    @ViewBuilder
    private var invitoTestRitmo: some View {
        if let t = stato.testRitmo, t.ritmoRiferimentoPer100 != nil {
            VStack(alignment: .leading, spacing: 10) {
                Text("retest.nota")
                    .font(Tema.piccolo)
                    .foregroundStyle(Tema.testoSecondario)
                    .fixedSize(horizontal: false, vertical: true)
                if let settimane = stato.settimaneDalTestRitmo, settimane >= StatoApp.settimanePerRifareTest {
                    Text(verbatim: testo("retest.messaggio", settimane))
                        .font(Tema.corpo)
                        .foregroundStyle(Tema.testo)
                        .fixedSize(horizontal: false, vertical: true)
                    Button {
                        foglio = .rifaiTestRitmo
                    } label: {
                        Text("retest.pulsante")
                    }
                    .buttonStyle(.secondario)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private var cartaASecco: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Tema.turchese.opacity(0.18))
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(Tema.testo)
            }
            .frame(width: 44, height: 44)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text("asecco.titolo")
                    .font(Tema.sottotitolo)
                    .foregroundStyle(Tema.testo)
                Text("asecco.sottotitolo")
                    .font(Tema.piccolo)
                    .foregroundStyle(Tema.testoSecondario)
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .foregroundStyle(Tema.testoSecondario)
        }
        .carta(padding: 14)
        .accessibilityElement(children: .combine)
    }

    private var sottotitoloTestRitmo: String {
        if let t = stato.testRitmo, let rc = t.ritmoRiferimentoPer100 {
            return testo("percorso.ritmo.salvato", FormatoRitmo.minutiSecondi(rc))
        }
        return testo("percorso.ritmo.sottotitolo")
    }

    /// Risposta calda a un gesto dell'utente (ha segnato il test come superato): non è il popup del giorno.
    private func festeggiaTappa() {
        guard popup == nil else { return }
        // Un attimo di attesa, perché il foglio della tappa finisca di chiudersi.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard popup == nil else { return }
            popup = PopupCoach(
                momento: .tappaSuperata,
                espressione: .traguardo,
                messaggio: testo("percorso.superata.messaggio", stato.profilo.nomePulito)
            )
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
        .overlay(
            // La tappa attuale è evidenziata dal bordo corallo.
            RoundedRectangle(cornerRadius: Tema.raggio, style: .continuous)
                .stroke(Tema.corallo, lineWidth: attuale ? 3 : 0)
        )
        .accessibilityElement(children: .combine)
        .accessibilityValue(Text(verbatim: completata ? testo("tappa.superata") : ""))
    }
}

struct DettaglioTappaView: View {
    let tappa: Tappa
    /// Chiamata dopo che l'utente ha confermato di aver superato il test.
    let onSuperata: (() -> Void)?
    @Environment(StatoApp.self) private var stato
    @Environment(\.dismiss) private var dismiss
    @State private var chiediConferma = false

    init(tappa: Tappa, onSuperata: (() -> Void)? = nil) {
        self.tappa = tappa
        self.onSuperata = onSuperata
    }

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
                    esitoTest

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
            .confirmationDialog(Text("tappa.conferma.titolo"), isPresented: $chiediConferma, titleVisibility: .visible) {
                Button("tappa.conferma.si") { supera() }
                Button("comune.annulla", role: .cancel) {}
            }
        }
    }

    /// Il test non si controlla: lo dichiara l'utente. Una tappa superata resta consultabile e le altre non sono mai bloccate.
    @ViewBuilder
    private var esitoTest: some View {
        if stato.tappaSuperata(tappa.id) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(.title2, design: .rounded))
                    .foregroundStyle(Tema.turchese)
                    .accessibilityHidden(true)
                Text("tappa.superata")
                    .font(Tema.sottotitolo)
                    .foregroundStyle(Tema.testo)
                Spacer(minLength: 0)
            }
            .carta()
            .accessibilityElement(children: .combine)
        } else {
            Button {
                chiediConferma = true
            } label: {
                Text("tappa.haiSuperato")
            }
            .buttonStyle(.primario)
        }
    }

    private func supera() {
        let prima = stato.tappaAttuale
        stato.superaTappa(tappa.id)
        // Segnare una tappa già alle spalle non deve riportare indietro la tappa attuale.
        if prima > tappa.id {
            stato.vai(allaTappa: prima)
        }
        if let onSuperata {
            onSuperata()
        } else {
            dismiss()
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
