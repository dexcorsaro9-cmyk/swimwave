import SwiftUI
import SwimwaveCore

/// Le sei espressioni del coach (assets/coach, docs/POPUP_COACH.md).
enum EspressioneCoach: CaseIterable {
    case benvenuto, incoraggiamento, traguardo, dopoAllenamentoDuro, ripartenza, dolore

    /// Parte finale del nome dell'immagine: "antonio-benvenuto", "pamela-dopo-allenamento-duro", ...
    var nomeFile: String {
        switch self {
        case .benvenuto: return "benvenuto"
        case .incoraggiamento: return "incoraggiamento"
        case .traguardo: return "traguardo"
        case .dopoAllenamentoDuro: return "dopo-allenamento-duro"
        case .ripartenza: return "ripartenza"
        case .dolore: return "dolore"
        }
    }

    /// Anello dell'avatar: turchese di benvenuto, corallo nei traguardi (docs/GRAFICA.md).
    var anello: Color {
        self == .traguardo ? Tema.corallo : Tema.turchese
    }

    /// Descrizione per VoiceOver, es. "Antonio, sorridente". Il messaggio non dipende dall'immagine.
    func descrizioneAccessibile(coach: CoachID) -> String {
        switch self {
        case .benvenuto: return testo("avatar.benvenuto", coach.nome)
        case .incoraggiamento: return testo("avatar.incoraggiamento", coach.nome)
        case .traguardo: return testo("avatar.traguardo", coach.nome)
        case .dopoAllenamentoDuro: return testo("avatar.dopoAllenamentoDuro", coach.nome)
        case .ripartenza: return testo("avatar.ripartenza", coach.nome)
        case .dolore: return testo("avatar.dolore", coach.nome)
        }
    }
}

/// Avatar tondo del coach con anello colorato.
struct AvatarCoach: View {
    let coach: CoachID
    var espressione: EspressioneCoach = .benvenuto
    var dimensione: CGFloat = 64

    var body: some View {
        Image("\(coach.prefissoImmagini)-\(espressione.nomeFile)")
            .resizable()
            .scaledToFill()
            .frame(width: dimensione, height: dimensione)
            .clipShape(Circle())
            .overlay(Circle().stroke(espressione.anello, lineWidth: max(3, dimensione / 16)))
            .accessibilityLabel(Text(verbatim: espressione.descrizioneAccessibile(coach: coach)))
    }
}

struct PulsantePopup: Identifiable {
    let id = UUID()
    let titolo: String
    var principale: Bool = false
    let azione: () -> Void
}

/// Popup del coach: avatar tondo, nome, messaggio breve (al massimo due frasi), al massimo due pulsanti.
/// Non blocca mai l'uso dell'app: si chiude con un tocco fuori (vedi `coachPopup`).
struct CoachPopup: View {
    let coach: CoachID
    let espressione: EspressioneCoach
    let messaggio: String
    var pulsanti: [PulsantePopup] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                AvatarCoach(coach: coach, espressione: espressione, dimensione: 64)
                VStack(alignment: .leading, spacing: 6) {
                    Text(verbatim: coach.nome)
                        .font(Tema.sottotitolo)
                        .foregroundStyle(Tema.testo)
                    Text(verbatim: messaggio)
                        .font(Tema.corpo)
                        .foregroundStyle(Tema.testo)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            if !pulsanti.isEmpty {
                HStack(spacing: 12) {
                    ForEach(pulsanti.prefix(2)) { p in
                        if p.principale {
                            Button(action: p.azione) { Text(verbatim: p.titolo) }
                                .buttonStyle(.primario)
                        } else {
                            Button(action: p.azione) { Text(verbatim: p.titolo) }
                                .buttonStyle(.secondario)
                        }
                    }
                }
            }
        }
        .carta(padding: 18)
        .accessibilityElement(children: .contain)
    }
}

/// Un popup da mostrare: il contenuto e il tipo di momento (per ricordare di averlo già mostrato).
struct PopupCoach: Identifiable, Equatable {
    enum Momento: Equatable {
        case benvenutoGiornata, obiettivoRaggiunto, ripartenza
        /// Traguardo di settimane di fila con l'obiettivo raggiunto (2, 4, 8, 12, 26, 52).
        case serieSettimane(Int)
        /// Subito dopo un allenamento dichiarato "duro". Non conta come il popup del giorno (lo mostra la schermata di fine allenamento).
        case dopoAllenamentoDuro
        /// Subito dopo che l'utente segna il test di una tappa come superato (risposta a un suo gesto, non il popup del giorno).
        case tappaSuperata
    }

    let id = UUID()
    let momento: Momento
    let espressione: EspressioneCoach
    let messaggio: String

    static func == (a: PopupCoach, b: PopupCoach) -> Bool { a.id == b.id }
}

extension View {
    /// Mostra il popup del coach sopra la schermata. Un tocco fuori lo chiude.
    func coachPopup(_ popup: Binding<PopupCoach?>, coach: CoachID?, pulsanti: @escaping (PopupCoach) -> [PulsantePopup]) -> some View {
        self.overlay {
            if let p = popup.wrappedValue, let coach {
                ZStack {
                    Tema.navy.opacity(0.45)
                        .ignoresSafeArea()
                        .onTapGesture { popup.wrappedValue = nil }
                    CoachPopup(coach: coach, espressione: p.espressione, messaggio: p.messaggio, pulsanti: pulsanti(p))
                        .padding(.horizontal, 20)
                        .transition(.scale(scale: 0.95).combined(with: .opacity))
                }
            }
        }
        .animation(.easeOut(duration: 0.2), value: popup.wrappedValue)
    }
}

#Preview("Popup") {
    ZStack {
        Tema.sfondo.ignoresSafeArea()
        CoachPopup(
            coach: .donna,
            espressione: .traguardo,
            messaggio: "Obiettivo della settimana raggiunto. Bel lavoro!",
            pulsanti: [PulsantePopup(titolo: "Grazie", principale: true, azione: {})]
        )
        .padding()
    }
}
