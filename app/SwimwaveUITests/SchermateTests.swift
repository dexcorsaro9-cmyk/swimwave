import XCTest

/// Giro delle schermate dell'app in modalità demo, con uno screenshot per ogni schermata.
/// Non verifica nulla: serve a vedere l'interfaccia nelle tre lingue e con il testo grande senza aprire l'app a mano.
/// Lingua, dimensione del testo e cartella di destinazione arrivano dalle variabili d'ambiente
/// SCREENSHOT_LINGUA (it, en, es), SCREENSHOT_TESTO (una categoria di dimensione, per esempio UICTContentSizeCategoryXXXL)
/// e SCREENSHOT_DIR (cartella in cui salvare i PNG). Vedi .github/workflows/screenshot.yml.
final class SchermateTests: XCTestCase {
    private var lingua: String { ProcessInfo.processInfo.environment["SCREENSHOT_LINGUA"] ?? "it" }
    private var testo: String { ProcessInfo.processInfo.environment["SCREENSHOT_TESTO"] ?? "UICTContentSizeCategoryL" }
    private var cartella: URL {
        URL(fileURLWithPath: ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] ?? NSTemporaryDirectory(), isDirectory: true)
    }

    override func setUp() {
        continueAfterFailure = true
    }

    // MARK: Aiuti

    private func avvia(splash: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        let regione = ["it": "IT", "en": "GB", "es": "ES"][lingua] ?? "IT"
        app.launchArguments = ["-SwimwaveDemo",
                               "-AppleLanguages", "(\(lingua))",
                               "-AppleLocale", "\(lingua)_\(regione)",
                               "-UIPreferredContentSizeCategoryName", testo]
        if splash { app.launchArguments.append("-SwimwaveSplash") }
        app.launch()
        return app
    }

    private func scatta(_ nome: String) {
        let immagine = XCUIScreen.main.screenshot()
        let file = cartella.appendingPathComponent("\(nome).png")
        try? FileManager.default.createDirectory(at: cartella, withIntermediateDirectories: true)
        try? immagine.pngRepresentation.write(to: file)
        let allegato = XCTAttachment(screenshot: immagine)
        allegato.name = nome
        allegato.lifetime = .keepAlways
        add(allegato)
    }

    private func elemento(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    /// Tocca l'elemento con questo identificatore, se compare entro pochi secondi. Torna falso se non c'è:
    /// lo screenshot successivo mostra comunque cosa c'era a schermo.
    @discardableResult
    private func tocca(_ app: XCUIApplication, _ id: String, attesa: TimeInterval = 6) -> Bool {
        let e = elemento(app, id)
        guard e.waitForExistence(timeout: attesa) else {
            XCTFail("manca l'elemento \(id)")
            return false
        }
        e.tap()
        return true
    }

    private func pausa(_ secondi: TimeInterval = 1.0) {
        Thread.sleep(forTimeInterval: secondi)
    }

    private func tab(_ app: XCUIApplication, _ indice: Int) {
        let barra = app.tabBars.firstMatch
        if barra.waitForExistence(timeout: 10) {
            barra.buttons.element(boundBy: indice).tap()
        }
        pausa()
    }

    private func indietro(_ app: XCUIApplication) {
        let b = app.navigationBars.buttons.element(boundBy: 0)
        if b.exists { b.tap() }
        pausa(0.6)
    }

    // MARK: Giro

    func testSplash() {
        _ = avvia(splash: true)
        pausa(1.4)
        scatta("00-splash")
    }

    func testOggi() {
        let app = avvia()
        pausa(1.5)
        scatta("01-oggi-alto")
        app.swipeUp(); pausa(0.6)
        scatta("02-oggi-meta")
        app.swipeUp(); pausa(0.6)
        scatta("03-oggi-basso")
    }

    func testSuMisuraDaOggi() {
        let app = avvia()
        pausa(1.0)
        if tocca(app, "oggi.sumisura") {
            pausa(1.2)
            scatta("04-sumisura")
            app.swipeUp(); pausa(0.6)
            scatta("05-sumisura-proposta")
        } else {
            scatta("04-sumisura-non-trovata")
        }
    }

    func testLibreria() {
        let app = avvia()
        pausa(1.0)
        if tocca(app, "oggi.cambia") {
            pausa(1.0)
            scatta("06-cambia-allenamento")
            if tocca(app, "cambia.libreria") {
                pausa(1.2)
                scatta("07-libreria")
                app.swipeUp(); pausa(0.6)
                scatta("08-libreria-sotto")
                app.swipeDown(); app.swipeDown(); pausa(0.6)
                if tocca(app, "libreria.guida", attesa: 3) {
                    pausa(1.0)
                    scatta("09-guida-tipologie")
                }
            }
        }
    }

    func testPercorso() {
        let app = avvia()
        tab(app, 1)
        scatta("10-percorso")
        app.swipeUp(); pausa(0.6)
        scatta("11-percorso-sotto")
    }

    func testStorico() {
        let app = avvia()
        tab(app, 2)
        scatta("12-storico")
        app.swipeUp(); pausa(0.6)
        scatta("13-storico-sotto")
        app.swipeDown(); app.swipeDown(); pausa(0.5)
        for (id, nome) in [("storico.riepilogo", "14-riepilogo"), ("storico.record", "15-record"),
                           ("storico.traguardi", "16-traguardi"), ("storico.anno", "17-anno")] {
            if tocca(app, id, attesa: 4) {
                pausa(1.2)
                scatta(nome)
                indietro(app)
            }
        }
        if tocca(app, "storico.riga", attesa: 4) {
            pausa(1.2)
            scatta("18-dettaglio-nuotata")
            app.swipeUp(); pausa(0.6)
            scatta("19-dettaglio-nuotata-sotto")
        }
    }

    func testProfilo() {
        let app = avvia()
        tab(app, 3)
        scatta("20-profilo")
        app.swipeUp(); pausa(0.6)
        scatta("21-profilo-meta")
        app.swipeUp(); pausa(0.6)
        scatta("22-profilo-basso")
        if tocca(app, "profilo.backup", attesa: 4) {
            pausa(1.0)
            scatta("23-backup")
            indietro(app)
        }
        if tocca(app, "profilo.informazioni", attesa: 4) {
            pausa(1.0)
            scatta("24-informazioni")
        }
    }
}
