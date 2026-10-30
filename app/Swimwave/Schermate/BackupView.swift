import SwiftUI
import UniformTypeIdentifiers

/// File del backup: solo dati JSON, salvato dove sceglie l'utente (File, iCloud Drive, AirDrop…).
struct DocumentoBackup: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var dati: Data

    init(dati: Data) { self.dati = dati }

    init(configuration: ReadConfiguration) throws {
        guard let d = configuration.file.regularFileContents else { throw CocoaError(.fileReadCorruptFile) }
        dati = d
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: dati)
    }
}

/// Impostazioni > Backup: tutto resta sul telefono, quindi qui si può salvare una copia e rimetterla dopo un cambio telefono.
struct BackupView: View {
    @Environment(StatoApp.self) private var stato
    @AppStorage("swimwave.ultimoBackup") private var ultimoBackup: Double = 0

    @State private var documento: DocumentoBackup?
    @State private var mostraEsporta = false
    @State private var mostraImporta = false
    @State private var datiDaRipristinare: Data?
    @State private var confermaRipristino = false
    @State private var esito: Esito?

    private enum Esito: Identifiable {
        case salvato, ripristinato, errore(String)
        var id: String {
            switch self {
            case .salvato: return "salvato"
            case .ripristinato: return "ripristinato"
            case .errore(let m): return m
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("backup.spiegazione")
                        .font(Tema.corpo)
                        .foregroundStyle(Tema.testo)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("backup.contenuto")
                        .font(Tema.piccolo)
                        .foregroundStyle(Tema.testoSecondario)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .carta()

                Group {
                    if ultimoBackup > 0 {
                        Text(verbatim: testo("backup.ultimo", Date(timeIntervalSince1970: ultimoBackup).formatted(date: .long, time: .shortened)))
                    } else {
                        Text("backup.mai")
                    }
                }
                .font(Tema.piccolo)
                .foregroundStyle(Tema.testoSecondario)

                Button { preparaBackup() } label: {
                    Label("backup.crea", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.primario)

                Button { mostraImporta = true } label: {
                    Label("backup.ripristina", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.secondario)

                Text("backup.avviso")
                    .font(Tema.piccolo)
                    .foregroundStyle(Tema.testoSecondario)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .sfondoApp()
        .navigationTitle(Text("backup.titolo"))
        .navigationBarTitleDisplayMode(.inline)
        .fileExporter(isPresented: $mostraEsporta, document: documento, contentType: .json,
                      defaultFilename: StatoApp.nomeFileBackup()) { risultato in
            switch risultato {
            case .success:
                ultimoBackup = Date().timeIntervalSince1970
                esito = .salvato
            case .failure(let errore):
                esito = .errore(errore.localizedDescription)
            }
            documento = nil
        }
        .fileImporter(isPresented: $mostraImporta, allowedContentTypes: [.json]) { risultato in
            leggi(risultato)
        }
        .confirmationDialog("backup.ripristina.conferma", isPresented: $confermaRipristino, titleVisibility: .visible) {
            Button("backup.ripristina.azione", role: .destructive) { ripristina() }
            Button("comune.annulla", role: .cancel) { datiDaRipristinare = nil }
        } message: {
            Text("backup.ripristina.messaggio")
        }
        .alert(item: $esito) { e in
            switch e {
            case .salvato:
                return Alert(title: Text("backup.esito.salvato"), dismissButton: .default(Text("comune.chiudi")))
            case .ripristinato:
                return Alert(title: Text("backup.esito.ripristinato"), dismissButton: .default(Text("comune.chiudi")))
            case .errore(let messaggio):
                return Alert(title: Text("backup.esito.errore"), message: Text(verbatim: messaggio),
                             dismissButton: .default(Text("comune.chiudi")))
            }
        }
    }

    private func preparaBackup() {
        do {
            documento = DocumentoBackup(dati: try stato.creaBackup())
            mostraEsporta = true
        } catch {
            esito = .errore(error.localizedDescription)
        }
    }

    private func leggi(_ risultato: Result<URL, Error>) {
        switch risultato {
        case .failure(let errore):
            esito = .errore(errore.localizedDescription)
        case .success(let url):
            // I file scelti da File sono fuori dall'app: serve il permesso temporaneo di lettura.
            let accesso = url.startAccessingSecurityScopedResource()
            defer { if accesso { url.stopAccessingSecurityScopedResource() } }
            do {
                datiDaRipristinare = try Data(contentsOf: url)
                confermaRipristino = true
            } catch {
                esito = .errore(error.localizedDescription)
            }
        }
    }

    private func ripristina() {
        guard let dati = datiDaRipristinare else { return }
        datiDaRipristinare = nil
        Task {
            do {
                try await stato.ripristina(da: dati)
                esito = .ripristinato
            } catch StatoApp.ErroreBackup.versioneFutura {
                esito = .errore(testo("backup.errore.versione"))
            } catch {
                esito = .errore(testo("backup.errore.nonvalido"))
            }
        }
    }
}
