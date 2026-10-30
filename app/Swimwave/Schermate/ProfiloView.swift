import SwiftUI
import SwimwaveCore

/// Profilo: tutte le risposte della lavagnetta si possono cambiare qui (docs/ONBOARDING.md).
struct ProfiloView: View {
    @Environment(StatoApp.self) private var stato
    @State private var confermaCancellazione = false
    @State private var mostraPermessoSalute = false
    @State private var mostraPermessoNotifiche = false
    @State private var linguaScelta: Lingua? = Lingua.scelta
    @State private var avvisoRiavvio = false
    /// Stessa chiave di RootView: dopo aver spiegato le notifiche qui, il primo avvio non le rispiega.
    @AppStorage("swimwave.permessoNotificheMostrato") private var notificheMostrate = false

    var body: some View {
        @Bindable var stato = stato
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    IntestazioneOnda(colori: SezioneColore.profilo.gradiente) {
                        HStack(spacing: 14) {
                            Text("profilo.titolo").font(Tema.titolo2)
                            Spacer(minLength: 0)
                            if let coach = stato.profilo.coach {
                                AvatarCoach(coach: coach, espressione: .benvenuto, dimensione: 52)
                            }
                        }
                    }
                    VStack(spacing: 16) {
                        riga("profilo.coach") {
                            MenuScelta(titolo: testo("profilo.coach"), opzioni: CoachID.allCases,
                                       etichetta: { $0.nome }, selezione: $stato.profilo.coach)
                        }
                        riga("profilo.nome") {
                            TextField("lavagnetta.nome.segnaposto", text: $stato.profilo.nome)
                                .textContentType(.givenName)
                                .autocorrectionDisabled()
                                .font(Tema.corpo)
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Tema.turchese, lineWidth: 2))
                                .onChange(of: stato.profilo.nome) { _, nuovo in
                                    if nuovo.count > Profilo.lunghezzaMassimaNome {
                                        stato.profilo.nome = String(nuovo.prefix(Profilo.lunghezzaMassimaNome))
                                    }
                                }
                        }
                        riga("profilo.livello") {
                            MenuScelta(titolo: testo("profilo.livello"), opzioni: Livello.allCases,
                                       etichetta: { $0.etichetta }, selezione: $stato.profilo.livello)
                        }
                        riga("profilo.obiettivo") {
                            MenuScelta(titolo: testo("profilo.obiettivo"), opzioni: Obiettivo.allCases,
                                       etichetta: { $0.etichetta }, selezione: $stato.profilo.obiettivo)
                        }
                        riga("profilo.vasca") {
                            VStack(alignment: .leading, spacing: 10) {
                                MenuScelta(titolo: testo("profilo.vasca"), opzioni: Vasca.allCases,
                                           etichetta: { $0.etichetta }, selezione: $stato.profilo.vasca)
                                if stato.profilo.vasca == .altra {
                                    Text("profilo.vasca.altra.domanda")
                                        .font(Tema.piccolo.weight(.bold))
                                        .foregroundStyle(Tema.testo)
                                    MenuScelta(titolo: testo("profilo.vasca.altra.domanda"),
                                               opzioni: Array(Vasca.misuraLiberaMinima...Vasca.misuraLiberaMassima),
                                               etichetta: { testo("profilo.vasca.altra.valore", $0) },
                                               selezione: $stato.profilo.vascaPersonalizzata)
                                }
                            }
                        }
                        riga("profilo.ritmo") {
                            VStack(alignment: .leading, spacing: 10) {
                                MenuScelta(titolo: testo("profilo.ritmo"), opzioni: Ritmo.allCases,
                                           etichetta: { $0.etichetta },
                                           selezione: Binding(
                                            get: { stato.profilo.ritmo },
                                            set: { nuovo in
                                                // scegli(ritmo:) propone la frequenza predefinita se serve.
                                                if let nuovo { stato.profilo.scegli(ritmo: nuovo) } else { stato.profilo.ritmo = nil }
                                            }))
                                if let ritmo = stato.profilo.ritmo {
                                    Text(verbatim: ritmo.descrizione)
                                        .font(Tema.piccolo)
                                        .foregroundStyle(Tema.testoSecondario)
                                    if ritmo.richiedeFrequenza {
                                        Text("lavagnetta.domanda.frequenza")
                                            .font(Tema.piccolo.weight(.bold))
                                            .foregroundStyle(Tema.testo)
                                        MenuScelta(titolo: testo("lavagnetta.domanda.frequenza"),
                                                   opzioni: Array(Profilo.frequenzaMinima...Profilo.frequenzaMassima),
                                                   etichetta: { testo("lavagnetta.frequenza.valore", $0) },
                                                   selezione: $stato.profilo.frequenzaSettimanale)
                                    }
                                }
                            }
                        }

                        rigaLingua

                        rigaIA

                        if !stato.permessoSaluteChiesto {
                            Button { mostraPermessoSalute = true } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "heart.fill")
                                        .foregroundStyle(Tema.corallo)
                                        .accessibilityHidden(true)
                                    Text("profilo.salute.leggi")
                                        .font(Tema.sottotitolo)
                                        .foregroundStyle(Tema.testo)
                                        .multilineTextAlignment(.leading)
                                    Spacer()
                                    Image(systemName: "chevron.right").foregroundStyle(Tema.testoSecondario)
                                        .accessibilityHidden(true)
                                }
                                .carta()
                            }
                            .buttonStyle(.plain)
                        }

                        NavigationLink {
                            BackupView()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "externaldrive.fill.badge.icloud")
                                    .foregroundStyle(SezioneColore.profilo.accento)
                                    .accessibilityHidden(true)
                                Text("profilo.backup")
                                    .font(Tema.sottotitolo)
                                    .foregroundStyle(Tema.testo)
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(Tema.testoSecondario)
                                    .accessibilityHidden(true)
                            }
                            .carta()
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            InformazioniView()
                        } label: {
                            HStack {
                                Text("profilo.informazioni")
                                    .font(Tema.sottotitolo)
                                    .foregroundStyle(Tema.testo)
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(Tema.testoSecondario)
                            }
                            .carta()
                        }
                        .buttonStyle(.plain)

                        Button { confermaCancellazione = true } label: {
                            Text("profilo.cancella")
                        }
                        .buttonStyle(.secondario)
                        .confirmationDialog("profilo.cancella.conferma", isPresented: $confermaCancellazione, titleVisibility: .visible) {
                            Button("profilo.cancella.azione", role: .destructive) { stato.cancellaTutto() }
                            Button("comune.annulla", role: .cancel) {}
                        } message: {
                            Text("profilo.cancella.messaggio")
                        }

                        // Riga di controllo visibile anche in Release: serve ai tester per capire se i contenuti sono arrivati nell'app.
                        VStack(alignment: .leading, spacing: 4) {
                            #if DEBUG
                            Text(verbatim: "Solo debug: bozze incluse = \(stato.contenuti.includeBozze)")
                            #endif
                            Text(verbatim: "Contenuti: \(stato.contenuti.tappe.count) tappe, \(stato.contenuti.drill.count) drill, \(stato.contenuti.voci.count) allenamenti")
                            ForEach(stato.contenuti.problemi, id: \.self) { Text(verbatim: $0) }
                        }
                        .font(Tema.piccolo)
                        .foregroundStyle(Tema.testoSecondario)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
            .sfondoApp()
            .toolbar(.hidden, for: .navigationBar)
            // Il ritmo e la frequenza cambiano già il profilo (RootView salva): qui si aggiornano i promemoria.
            .onChange(of: stato.profilo.ritmo) { _, nuovo in
                if nuovo == .spronami {
                    // Il coach spiega i promemoria; alla fine del foglio si riprogrammano.
                    mostraPermessoNotifiche = true
                } else {
                    // Con un altro ritmo riprogrammaPromemoria() cancella i promemoria.
                    Task { await stato.riprogrammaPromemoria() }
                }
            }
            .onChange(of: stato.profilo.frequenzaSettimanale) { _, _ in
                Task { await stato.riprogrammaPromemoria() }
            }
            .sheet(isPresented: $mostraPermessoSalute) {
                PermessoSaluteView { mostraPermessoSalute = false }
            }
            .sheet(isPresented: $mostraPermessoNotifiche, onDismiss: {
                // Anche se il foglio si chiude con un gesto: spiegato una volta, promemoria riprogrammati.
                notificheMostrate = true
                Task { await stato.riprogrammaPromemoria() }
            }) {
                PermessoNotificheView { mostraPermessoNotifiche = false }
            }
        }
    }

    /// Lingua dell'app: Automatica (quella dell'iPhone) o una a scelta. Si applica alla riapertura dell'app.
    private var rigaLingua: some View {
        riga("profilo.lingua") {
            VStack(alignment: .leading, spacing: 8) {
                Menu {
                    Button { cambia(lingua: nil) } label: {
                        if linguaScelta == nil { Label("profilo.lingua.automatica", systemImage: "checkmark") }
                        else { Text("profilo.lingua.automatica") }
                    }
                    ForEach(Lingua.allCases) { l in
                        Button { cambia(lingua: l) } label: {
                            if linguaScelta == l { Label(l.nome, systemImage: "checkmark") }
                            else { Text(verbatim: l.nome) }
                        }
                    }
                } label: {
                    HStack {
                        if let l = linguaScelta { Text(verbatim: l.nome) } else { Text("profilo.lingua.automatica") }
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down").foregroundStyle(Tema.testoSecondario)
                            .accessibilityHidden(true)
                    }
                    .font(Tema.corpo)
                    .foregroundStyle(Tema.testo)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Tema.turchese, lineWidth: 2))
                }
                Text("profilo.lingua.descrizione")
                    .font(Tema.piccolo)
                    .foregroundStyle(Tema.testoSecondario)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .alert("profilo.lingua.riavvio.titolo", isPresented: $avvisoRiavvio) {
            Button("comune.chiudi", role: .cancel) {}
        } message: {
            Text("profilo.lingua.riavvio.messaggio")
        }
    }

    private func cambia(lingua: Lingua?) {
        guard lingua != linguaScelta else { return }
        linguaScelta = lingua
        Lingua.scelta = lingua
        avvisoRiavvio = true
    }

    /// Interruttore del consenso all'IA: acceso = allenamenti preparati con l'intelligenza artificiale.
    private var rigaIA: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: Binding(
                get: { stato.consensoIA == true },
                set: { stato.imposta(consensoIA: $0) }
            )) {
                Text("profilo.ia.titolo")
                    .font(Tema.sottotitolo)
                    .foregroundStyle(Tema.testo)
            }
            .tint(Tema.turchese)
            Text("profilo.ia.descrizione")
                .font(Tema.piccolo)
                .foregroundStyle(Tema.testoSecondario)
                .fixedSize(horizontal: false, vertical: true)
        }
        .carta()
    }

    private func riga<Contenuto: View>(_ titolo: String, @ViewBuilder contenuto: () -> Contenuto) -> some View {
        let colore = PalettePagine.colore(per: titolo)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Circle().fill(colore).frame(width: 9, height: 9).accessibilityHidden(true)
                Text(LocalizedStringKey(titolo))
                    .font(Tema.piccolo.weight(.bold))
                    .foregroundStyle(Tema.testoSecondario)
            }
            contenuto()
        }
        .carta()
        .overlay(alignment: .leading) {
            Capsule().fill(colore).frame(width: 5).padding(.vertical, 14)
        }
    }
}
