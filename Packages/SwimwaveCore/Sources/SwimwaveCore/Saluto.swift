import Foundation

public enum FasciaOraria: String, Sendable, CaseIterable {
    case mattina, pomeriggio, sera

    /// Mattina 5-12, pomeriggio 13-17, sera dalle 18 alle 4.
    /// Le soglie sono una scelta nostra, facili da cambiare qui.
    public init(ora: Int) {
        switch ora {
        case 5..<13: self = .mattina
        case 13..<18: self = .pomeriggio
        default: self = .sera
        }
    }

    public init(data: Date, calendar: Calendar = .current) {
        self.init(ora: calendar.component(.hour, from: data))
    }
}

/// Saluto per fascia oraria con il nome ("Buongiorno, Luca"). Testi neutri rispetto al genere.
/// Il testo mostrato all'utente viene dalle stringhe localizzate dell'app; `testoItaliano` serve a test e log.
public struct Saluto: Equatable, Sendable {
    public let fascia: FasciaOraria
    public let nome: String

    public init(fascia: FasciaOraria, nome: String) {
        self.fascia = fascia
        self.nome = nome.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public init(nome: String, data: Date = Date(), calendar: Calendar = .current) {
        self.init(fascia: FasciaOraria(data: data, calendar: calendar), nome: nome)
    }

    public var formula: String {
        switch fascia {
        case .mattina: return "Buongiorno"
        case .pomeriggio: return "Buon pomeriggio"
        case .sera: return "Buonasera"
        }
    }

    public var testoItaliano: String {
        nome.isEmpty ? formula : "\(formula), \(nome)"
    }
}
