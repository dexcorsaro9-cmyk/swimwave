import SwiftUI
import SwimwaveCore

/// Primo avvio (docs/ONBOARDING.md): scelta del coach, lavagnetta con 5 domande al massimo, scheda finale.
/// Le richieste di permesso (Apple Salute, notifiche) non sono qui: vanno spiegate dal coach nel momento giusto (da fare).
struct OnboardingView: View {
    @Environment(StatoApp.self) private var stato

    private enum Fase { case sceltaCoach, lavagnetta, scheda }

    @State private var fase: Fase = .sceltaCoach
    @State private var profilo = Profilo()
    @State private var passoIniziale = 0

    var body: some View {
        Group {
            switch fase {
            case .sceltaCoach:
                SceltaCoachView(scelto: $profilo.coach) {
                    fase = .lavagnetta
                }
            case .lavagnetta:
                LavagnettaView(profilo: $profilo, passoIniziale: passoIniziale,
                               indietro: { fase = .sceltaCoach },
                               fine: { fase = .scheda })
            case .scheda:
                SchedaFinaleView(profilo: profilo,
                                 modifica: { passoIniziale = 0; fase = .lavagnetta },
                                 inizia: { stato.completaOnboarding(con: profilo) })
            }
        }
        .sfondoApp()
        .animation(.easeInOut(duration: 0.25), value: fase)
    }
}

// MARK: - Scelta del coach

struct SceltaCoachView: View {
    @Binding var scelto: CoachID?
    let continua: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            IntestazioneOnda {
                VStack(alignment: .leading, spacing: 6) {
                    Text("scelta.titolo").font(Tema.titolo2)
                    Text("scelta.sottotitolo").font(Tema.corpo).opacity(0.9)
                }
            }
            ScrollView {
                VStack(spacing: 20) {
                    HStack(alignment: .top, spacing: 14) {
                        ForEach(CoachID.allCases, id: \.self) { coach in
                            SchedaCoach(coach: coach, selezionato: scelto == coach) { scelto = coach }
                        }
                    }
                    // Una sola riga piccola: i coach sono personaggi virtuali (docs/POPUP_COACH.md).
                    Text("scelta.nota")
                        .font(Tema.piccolo)
                        .foregroundStyle(Tema.testoSecondario)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            Button(action: continua) { Text("comune.continua") }
                .buttonStyle(.primario)
                .disabled(scelto == nil)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
        }
    }
}

private struct SchedaCoach: View {
    let coach: CoachID
    let selezionato: Bool
    let tocco: () -> Void

    var body: some View {
        Button(action: tocco) {
            VStack(spacing: 10) {
                AvatarCoach(coach: coach, espressione: .benvenuto, dimensione: 110)
                Text(verbatim: coach.nome)
                    .font(Tema.titolo2)
                    .foregroundStyle(Tema.testo)
                Text(verbatim: coach.presentazione)
                    .font(Tema.piccolo)
                    .foregroundStyle(Tema.testoSecondario)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: Tema.raggio, style: .continuous)
                    .fill(Tema.carta)
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Tema.raggio, style: .continuous)
                    .stroke(selezionato ? Tema.corallo : Color.clear, lineWidth: 3)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selezionato ? [.isSelected] : [])
    }
}

// MARK: - Lavagnetta

/// Le cinque domande. La frequenza non è una domanda a parte: compare nel passo del ritmo.
enum PassoLavagnetta: Int, CaseIterable {
    case nome, livello, obiettivo, vasca, ritmo

    var domanda: String {
        switch self {
        case .nome: return testo("lavagnetta.domanda.nome")
        case .livello: return testo("lavagnetta.domanda.livello")
        case .obiettivo: return testo("lavagnetta.domanda.obiettivo")
        case .vasca: return testo("lavagnetta.domanda.vasca")
        case .ritmo: return testo("lavagnetta.domanda.ritmo")
        }
    }

    /// Solo l'obiettivo si può saltare (vale "tecnica").
    var facoltativo: Bool { self == .obiettivo }

    /// Il passo è compilato in modo valido?
    func valido(_ p: Profilo) -> Bool {
        switch self {
        case .nome:
            let n = p.nomePulito
            return !n.isEmpty && n.count <= Profilo.lunghezzaMassimaNome
        case .livello: return p.livello != nil
        case .obiettivo: return true
        case .vasca: return p.vasca != nil
        case .ritmo: return p.ritmo != nil && !p.campiMancanti.contains(.frequenza)
        }
    }
}

struct LavagnettaView: View {
    @Binding var profilo: Profilo
    let passoIniziale: Int
    let indietro: () -> Void
    let fine: () -> Void

    @State private var passo: PassoLavagnetta = .nome
    @FocusState private var nomeInFocus: Bool

    var body: some View {
        VStack(spacing: 0) {
            if let coach = profilo.coach {
                IntestazioneOnda {
                    HStack(spacing: 12) {
                        AvatarCoach(coach: coach, espressione: .benvenuto, dimensione: 52)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(verbatim: coach.nome).font(Tema.sottotitolo)
                            Text(verbatim: testo("lavagnetta.progresso", passo.rawValue + 1, PassoLavagnetta.allCases.count))
                                .font(Tema.piccolo)
                                .opacity(0.85)
                        }
                    }
                }
            }
            ScrollView {
                VStack(spacing: 16) {
                    LavagnettaRiepilogo(profilo: profilo, fino: passo.rawValue)
                    domandaCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            piede
        }
        .onAppear {
            passo = PassoLavagnetta(rawValue: passoIniziale) ?? .nome
        }
    }

    private var domandaCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(verbatim: passo.domanda)
                .font(Tema.sottotitolo)
                .foregroundStyle(Tema.testo)
                .fixedSize(horizontal: false, vertical: true)
            campo
        }
        .carta(padding: 18)
    }

    @ViewBuilder
    private var campo: some View {
        switch passo {
        case .nome:
            TextField("lavagnetta.nome.segnaposto", text: $profilo.nome)
                .textContentType(.givenName)
                .autocorrectionDisabled()
                .submitLabel(.next)
                .focused($nomeInFocus)
                .onAppear { nomeInFocus = true }
                .font(Tema.corpo)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Tema.turchese, lineWidth: 2))
                .onChange(of: profilo.nome) { _, nuovo in
                    if nuovo.count > Profilo.lunghezzaMassimaNome {
                        profilo.nome = String(nuovo.prefix(Profilo.lunghezzaMassimaNome))
                    }
                }
                .onSubmit { if passo.valido(profilo) { avanti() } }
        case .livello:
            MenuScelta(titolo: passo.domanda, opzioni: Livello.allCases,
                       etichetta: { $0.etichetta }, selezione: $profilo.livello)
        case .obiettivo:
            MenuScelta(titolo: passo.domanda, opzioni: Obiettivo.allCases,
                       etichetta: { $0.etichetta }, selezione: $profilo.obiettivo)
        case .vasca:
            MenuScelta(titolo: passo.domanda, opzioni: Vasca.allCases,
                       etichetta: { $0.etichetta }, selezione: $profilo.vasca)
        case .ritmo:
            VStack(alignment: .leading, spacing: 12) {
                MenuScelta(titolo: passo.domanda, opzioni: Ritmo.allCases,
                           etichetta: { $0.etichetta }, selezione: $profilo.ritmo)
                if let ritmo = profilo.ritmo {
                    Text(verbatim: ritmo.descrizione)
                        .font(Tema.piccolo)
                        .foregroundStyle(Tema.testoSecondario)
                    if ritmo.richiedeFrequenza {
                        // La frequenza compare nello stesso passo, solo per Regolare e Spronami.
                        Text("lavagnetta.domanda.frequenza")
                            .font(Tema.sottotitolo)
                            .foregroundStyle(Tema.testo)
                            .padding(.top, 4)
                        MenuScelta(titolo: testo("lavagnetta.domanda.frequenza"),
                                   opzioni: Array(Profilo.frequenzaMinima...Profilo.frequenzaMassima),
                                   etichetta: { testo("lavagnetta.frequenza.valore", $0) },
                                   selezione: $profilo.frequenzaSettimanale)
                    }
                }
            }
        }
    }

    private var piede: some View {
        VStack(spacing: 10) {
            Button(action: avanti) {
                Text(LocalizedStringKey(passo == .ritmo ? "comune.fatto" : "comune.avanti"))
            }
            .buttonStyle(.primario)
            .disabled(!passo.valido(profilo))

            HStack {
                Button(action: indietroUnPasso) { Text("comune.indietro") }
                    .font(Tema.sottotitolo)
                    .foregroundStyle(Tema.testoSecondario)
                Spacer()
                if passo.facoltativo {
                    Button(action: salta) { Text("comune.salta") }
                        .font(Tema.sottotitolo)
                        .foregroundStyle(Tema.testo)
                }
            }
            .padding(.horizontal, 8)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private func avanti() {
        guard passo.valido(profilo) else { return }
        // Se il ritmo è Libero, la frequenza di un'eventuale scelta precedente non conta: la azzeriamo per pulizia.
        if passo == .ritmo, profilo.ritmo == .libero { profilo.frequenzaSettimanale = nil }
        if let prossimo = PassoLavagnetta(rawValue: passo.rawValue + 1) {
            passo = prossimo
        } else {
            fine()
        }
    }

    private func indietroUnPasso() {
        if let precedente = PassoLavagnetta(rawValue: passo.rawValue - 1) {
            passo = precedente
        } else {
            indietro()
        }
    }

    private func salta() {
        profilo.obiettivo = nil   // vale "tecnica"
        avanti()
    }
}

/// La lavagnetta vera e propria: una riga per risposta, che si riempie passo dopo passo.
struct LavagnettaRiepilogo: View {
    let profilo: Profilo
    /// Indice del passo in corso; le righe da questo in poi sono ancora vuote.
    var fino: Int? = nil

    private func valore(_ passo: PassoLavagnetta) -> String? {
        if let fino, passo.rawValue >= fino { return nil }
        switch passo {
        case .nome:
            return profilo.nomePulito.isEmpty ? nil : profilo.nomePulito
        case .livello: return profilo.livello?.etichetta
        case .obiettivo: return profilo.obiettivoEffettivo.etichetta
        case .vasca: return profilo.vasca?.etichetta
        case .ritmo:
            guard let ritmo = profilo.ritmo else { return nil }
            if let f = profilo.obiettivoSettimanale {
                return "\(ritmo.etichetta) · " + testo("lavagnetta.frequenza.settimana", f)
            }
            return ritmo.etichetta
        }
    }

    private func titolo(_ passo: PassoLavagnetta) -> String {
        switch passo {
        case .nome: return testo("lavagnetta.riga.nome")
        case .livello: return testo("lavagnetta.riga.livello")
        case .obiettivo: return testo("lavagnetta.riga.obiettivo")
        case .vasca: return testo("lavagnetta.riga.vasca")
        case .ritmo: return testo("lavagnetta.riga.ritmo")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(PassoLavagnetta.allCases, id: \.self) { passo in
                HStack(alignment: .firstTextBaseline) {
                    Text(verbatim: titolo(passo))
                        .font(Tema.piccolo)
                        .foregroundStyle(Tema.turcheseChiaro)
                        .frame(width: 84, alignment: .leading)
                    Text(verbatim: valore(passo) ?? "…")
                        .font(Tema.sottotitolo)
                        .foregroundStyle(Color.white.opacity(valore(passo) == nil ? 0.35 : 1))
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Tema.raggio, style: .continuous).fill(Tema.navy))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Scheda finale

struct SchedaFinaleView: View {
    let profilo: Profilo
    let modifica: () -> Void
    let inizia: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            IntestazioneOnda {
                HStack(spacing: 12) {
                    if let coach = profilo.coach {
                        AvatarCoach(coach: coach, espressione: .benvenuto, dimensione: 56)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("scheda.titolo").font(Tema.titolo2)
                        Text(verbatim: testo("scheda.messaggio", profilo.nomePulito))
                            .font(Tema.corpo)
                            .opacity(0.9)
                    }
                }
            }
            ScrollView {
                VStack(spacing: 16) {
                    LavagnettaRiepilogo(profilo: profilo)
                    Text("scheda.nota")
                        .font(Tema.piccolo)
                        .foregroundStyle(Tema.testoSecondario)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            VStack(spacing: 10) {
                Button(action: inizia) { Text("scheda.inizia") }
                    .buttonStyle(.primario)
                Button(action: modifica) { Text("scheda.modifica") }
                    .font(Tema.sottotitolo)
                    .foregroundStyle(Tema.testoSecondario)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }
}
