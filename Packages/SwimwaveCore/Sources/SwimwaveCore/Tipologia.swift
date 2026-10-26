import Foundation

/// Tipologia di allenamento (zone di intensità), indicata dall'istruttore: A1 recupero e tecnica, A2 fondo aerobico,
/// B1 soglia, B2 alta intensità aerobica, C1 tolleranza al ritmo forte. C2, C3 e D (agonisti) non sono nella versione 1.
/// Il valore grezzo è il campo `tipologia` di content/allenamenti/indice.json.
public enum Tipologia: String, Codable, Sendable, CaseIterable, Identifiable {
    case a1, a2, b1, b2, c1

    public var id: String { rawValue }

    /// A1 e A2 sono per tutti. B1, B2 e C1 (soglia e ritmo forte) solo dal livello intermedio: il principiante non fa mai lavoro "forte".
    public func ammessa(a categoria: CategoriaLivello) -> Bool {
        switch self {
        case .a1, .a2: return true
        case .b1, .b2, .c1: return categoria == .intermedio
        }
    }

    public static func ammesse(per categoria: CategoriaLivello) -> [Tipologia] {
        allCases.filter { $0.ammessa(a: categoria) }
    }
}

/// Perché si consiglia una tipologia oggi.
public enum MotivoConsiglio: String, Sendable {
    /// L'ultima nuotata era "dura": si va leggeri.
    case dura
    /// Pausa lunga: si riparte piano.
    case pausa
    /// Alternanza normale delle tipologie per livello e obiettivo.
    case alternanza
}

public struct Consiglio: Equatable, Sendable {
    public var tipologia: Tipologia
    public var motivo: MotivoConsiglio
}

extension Tipologia {
    /// Giorni senza nuotare dopo i quali si riparte con un allenamento leggero.
    public static let giorniDiPausa = 14

    /// La tipologia consigliata per oggi, secondo le esigenze dell'atleta.
    /// - dopo una nuotata "dura" o dopo una pausa lunga: A1;
    /// - altrimenti si alternano le tipologie adatte a livello e obiettivo, un passo al giorno.
    /// PROVVISORIO: le sequenze sono una scelta nostra, da riguardare con l'esperienza degli utenti.
    public static func consigliata(categoria: CategoriaLivello, obiettivo: Obiettivo,
                                   ultimaSensazione: Sensazione?, giorniDallUltima: Int?, giorno: Int) -> Consiglio {
        if ultimaSensazione == .dura { return Consiglio(tipologia: .a1, motivo: .dura) }
        if let g = giorniDallUltima, g >= giorniDiPausa { return Consiglio(tipologia: .a1, motivo: .pausa) }
        let ciclo: [Tipologia]
        switch (categoria, obiettivo) {
        case (.principiante, .tecnica), (.principiante, .stareBene): ciclo = [.a1, .a1, .a2]
        case (.principiante, .resistenza), (.principiante, .dimagrimento): ciclo = [.a2, .a1, .a2]
        case (.intermedio, .tecnica): ciclo = [.a1, .a2, .b1, .a1]
        case (.intermedio, .stareBene): ciclo = [.a1, .a2]
        case (.intermedio, .resistenza): ciclo = [.a2, .b1, .a1, .b2, .a2, .c1]
        case (.intermedio, .dimagrimento): ciclo = [.a2, .a1, .b1, .a2]
        }
        let i = ((giorno % ciclo.count) + ciclo.count) % ciclo.count
        return Consiglio(tipologia: ciclo[i], motivo: .alternanza)
    }
}
