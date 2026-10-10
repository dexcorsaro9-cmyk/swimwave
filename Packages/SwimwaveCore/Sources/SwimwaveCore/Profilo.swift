import Foundation

/// Coach scelto. Antonio e Pamela hanno stessa competenza e stesso tono (docs/COACH_PERSONAS.md).
/// Gli id coincidono con quelli di content/coach.json.
public enum CoachID: String, Codable, Sendable, CaseIterable {
    case uomo, donna

    public var nome: String {
        switch self {
        case .uomo: return "Antonio"
        case .donna: return "Pamela"
        }
    }

    /// Prefisso dei file immagine in assets/coach (es. "antonio" per "antonio-benvenuto.jpg").
    public var prefissoImmagini: String { nome.lowercased() }
}

public enum CategoriaLivello: String, Codable, Sendable {
    case principiante, intermedio
}

/// Risposta alla domanda "Quanto riesci a nuotare di fila a stile libero?" (docs/ONBOARDING.md).
public enum Livello: String, Codable, Sendable, CaseIterable {
    case menoDi25
    case menoDi100
    case cento
    case piuDiCento

    /// Principiante / intermedio. Intermedio = 100 m continui (content/REVISIONE.md, sezione 2).
    public var categoria: CategoriaLivello {
        switch self {
        case .menoDi25, .menoDi100: return .principiante
        case .cento, .piuDiCento: return .intermedio
        }
    }

    /// Tappa di partenza del percorso (content/percorso.json).
    /// PROVVISORIO, da confermare con l'istruttore: i test delle tappe 5, 7 sono 25 m e 100 m di stile libero;
    /// chi arriva a 100 m ha già il test della tappa 7, quindi parte dalla 8.
    public var tappaDiPartenza: Int {
        switch self {
        case .menoDi25: return 1
        case .menoDi100: return 5
        case .cento, .piuDiCento: return 8
        }
    }
}

/// Se manca la risposta vale `.tecnica` (docs/ONBOARDING.md).
public enum Obiettivo: String, Codable, Sendable, CaseIterable {
    case tecnica, resistenza, dimagrimento, stareBene

    /// Valore usato nei file di content/allenamenti/indice.json ("tecnica", "resistenza", "dimagrimento").
    /// "Stare bene" non ha una voce propria nell'indice: usa le riserve di tecnica.
    public var chiaveIndice: String {
        switch self {
        case .stareBene: return Obiettivo.tecnica.rawValue
        default: return rawValue
        }
    }
}

public enum Vasca: String, Codable, Sendable, CaseIterable {
    case metri16, metri20, metri25, metri33, metri50, altra, nonLoSo

    /// Limiti della misura libera: gli stessi del contratto del workout (docs/schema/workout.schema.json).
    public static let misuraLiberaMinima = 10
    public static let misuraLiberaMassima = 100
    public static let misuraLiberaPredefinita = 25

    /// "Non lo so ancora" vale 25 m (valore prudente di docs/ONBOARDING.md).
    /// "Altra misura" vale 25 m finché non è scritta; la misura scelta è in `Profilo.vascaPersonalizzata`.
    public var metri: Int {
        switch self {
        case .metri16: return 16
        case .metri20: return 20
        case .metri33: return 33
        case .metri50: return 50
        case .metri25, .altra, .nonLoSo: return 25
        }
    }

    /// Opzioni del menu del primo avvio: la misura libera si imposta dal Profilo, per non allungare la lavagnetta.
    public static var opzioniLavagnetta: [Vasca] { allCases.filter { $0 != .altra } }
}

public enum Ritmo: String, Codable, Sendable, CaseIterable {
    case libero, regolare, spronami

    /// Solo Regolare e Spronami hanno un obiettivo settimanale.
    public var richiedeFrequenza: Bool { self != .libero }
}

public enum CampoProfilo: String, Sendable, CaseIterable {
    case coach, nome, livello, vasca, ritmo, frequenza
}

/// Profilo dell'utente, compilato nella "lavagnetta" del primo avvio.
/// Obbligatori: coach, nome, livello, vasca, ritmo; frequenza solo se il ritmo è Regolare o Spronami.
public struct Profilo: Codable, Equatable, Sendable {
    public static let lunghezzaMassimaNome = 30
    public static let frequenzaMinima = 1
    public static let frequenzaMassima = 5
    /// Frequenza proposta quando si passa a Regolare/Spronami senza averne scelta una. Valore prudente, da confermare.
    public static let frequenzaPredefinita = 2

    public var coach: CoachID?
    public var nome: String
    public var livello: Livello?
    public var obiettivo: Obiettivo?
    public var vasca: Vasca? {
        didSet { if vasca == .altra && vascaPersonalizzata == nil { vascaPersonalizzata = Vasca.misuraLiberaPredefinita } }
    }
    /// Misura scelta con "Altra misura", in metri.
    public var vascaPersonalizzata: Int?
    public var ritmo: Ritmo?
    public var frequenzaSettimanale: Int?

    /// Profilo vuoto con i valori di partenza di vasca (25 m) e ritmo (Libero) previsti da docs/ONBOARDING.md.
    public init(
        coach: CoachID? = nil,
        nome: String = "",
        livello: Livello? = nil,
        obiettivo: Obiettivo? = nil,
        vasca: Vasca? = .metri25,
        vascaPersonalizzata: Int? = nil,
        ritmo: Ritmo? = .libero,
        frequenzaSettimanale: Int? = nil
    ) {
        self.coach = coach
        self.nome = nome
        self.livello = livello
        self.obiettivo = obiettivo
        self.vasca = vasca
        self.vascaPersonalizzata = vascaPersonalizzata
        self.ritmo = ritmo
        self.frequenzaSettimanale = frequenzaSettimanale
    }

    /// Nome senza spazi iniziali e finali.
    public var nomePulito: String {
        nome.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public var obiettivoEffettivo: Obiettivo { obiettivo ?? .tecnica }
    public var vascaMetri: Int {
        if vasca == .altra, let m = vascaPersonalizzata,
           (Vasca.misuraLiberaMinima...Vasca.misuraLiberaMassima).contains(m) { return m }
        return (vasca ?? .metri25).metri
    }
    public var categoriaLivello: CategoriaLivello { livello?.categoria ?? .principiante }

    /// Obiettivo settimanale: solo con ritmo Regolare o Spronami e frequenza valida, altrimenti nil.
    public var obiettivoSettimanale: Int? {
        guard let ritmo, ritmo.richiedeFrequenza, let f = frequenzaSettimanale,
              (Profilo.frequenzaMinima...Profilo.frequenzaMassima).contains(f) else { return nil }
        return f
    }

    /// Campi obbligatori mancanti o non validi, nell'ordine in cui si chiedono.
    public var campiMancanti: [CampoProfilo] {
        var mancanti: [CampoProfilo] = []
        if coach == nil { mancanti.append(.coach) }
        let n = nomePulito
        if n.isEmpty || n.count > Profilo.lunghezzaMassimaNome { mancanti.append(.nome) }
        if livello == nil { mancanti.append(.livello) }
        if vasca == nil {
            mancanti.append(.vasca)
        } else if vasca == .altra,
                  !(Vasca.misuraLiberaMinima...Vasca.misuraLiberaMassima).contains(vascaPersonalizzata ?? 0) {
            mancanti.append(.vasca)
        }
        if ritmo == nil {
            mancanti.append(.ritmo)
        } else if let ritmo, ritmo.richiedeFrequenza {
            if let f = frequenzaSettimanale {
                if !(Profilo.frequenzaMinima...Profilo.frequenzaMassima).contains(f) { mancanti.append(.frequenza) }
            } else {
                mancanti.append(.frequenza)
            }
        }
        return mancanti
    }

    public var isCompleto: Bool { campiMancanti.isEmpty }

    /// Cambia il ritmo. Se il nuovo ritmo richiede la frequenza e non c'è, propone quella predefinita.
    public mutating func scegli(ritmo nuovo: Ritmo) {
        ritmo = nuovo
        if nuovo.richiedeFrequenza && frequenzaSettimanale == nil {
            frequenzaSettimanale = Profilo.frequenzaPredefinita
        }
    }
}
