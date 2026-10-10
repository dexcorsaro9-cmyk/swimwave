import SwiftUI
import SwimwaveCore

/// Profilo: tutte le risposte della lavagnetta si possono cambiare qui (docs/ONBOARDING.md).
struct ProfiloView: View {
    @Environment(StatoApp.self) private var stato
    @State private var confermaCancellazione = false
    @State private var mostraPermessoSalute = false
    @State private var mostraPermessoNotifiche = false
    /// Stessa chiave di RootView: dopo aver spiegato le notifiche qui, il primo avvio non le rispiega.
    @AppStorage("swimwave.permessoNotificheMostrato") private var notificheMostrate = false

    var body: some View {
        @Bindable var stato = stato
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    IntestazioneOnda {
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

                        #if DEBUG
                        VStack(alignment: .leading, spacing: 4) {
                            Text(verbatim: "Solo debug: bozze incluse = \(stato.contenuti.includeBozze)")
                            Text(verbatim: "Tappe \(stato.contenuti.tappe.count), drill \(stato.contenuti.drill.count), riserve \(stato.contenuti.voci.count)")
                            ForEach(stato.contenuti.problemi, id: \.self) { Text(verbatim: $0) }
                        }
                        .font(Tema.piccolo)
                        .foregroundStyle(Tema.testoSecondario)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        #endif
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
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStringKey(titolo))
                .font(Tema.piccolo.weight(.bold))
                .foregroundStyle(Tema.testoSecondario)
            contenuto()
        }
        .carta()
    }
}
