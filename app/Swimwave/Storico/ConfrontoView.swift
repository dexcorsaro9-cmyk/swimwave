import SwiftUI
import SwimwaveCore

/// Due nuotate affiancate (A a sinistra, B a destra) con la differenza in mezzo.
/// Niente giudizi: la differenza è solo un numero con una freccia su o giù, sempre negli stessi colori neutri.
/// Una riga compare solo se il dato c'è in tutte e due le nuotate.
struct ConfrontoView: View {
    @Environment(StatoApp.self) private var stato
    let a: NuotataCompletata
    let b: NuotataCompletata

    init(a: NuotataCompletata, b: NuotataCompletata) {
        self.a = a
        self.b = b
    }

    /// Le versioni aggiornate (se una nuotata cambia, il confronto la rilegge).
    private var nuotataA: NuotataCompletata { stato.nuotate.first(where: { $0.id == a.id }) ?? a }
    private var nuotataB: NuotataCompletata { stato.nuotate.first(where: { $0.id == b.id }) ?? b }

    private struct Riga: Identifiable {
        let id: String
        let titolo: String
        let valoreA: String
        let valoreB: String
        /// Testo della differenza e verso (1 su, -1 giù, 0 uguale).
        let differenza: String
        let verso: Int
    }

    var body: some View {
        let na = nuotataA
        let nb = nuotataB
        let righe = costruisciRighe(na, nb)
        ScrollView {
            VStack(spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    testata(lettera: "A", nuotata: na)
                    testata(lettera: "B", nuotata: nb)
                }
                VStack(spacing: 0) {
                    ForEach(Array(righe.enumerated()), id: \.element.id) { indice, riga in
                        if indice > 0 {
                            Divider().overlay(Tema.bordo)
                        }
                        rigaConfronto(riga)
                    }
                }
                .carta()
                Text("confronto.nota")
                    .font(Tema.piccolo)
                    .foregroundStyle(Tema.testoSecondario)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
        }
        .sfondoApp()
        .navigationTitle("confronto.titolo")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }

    // MARK: Testata

    private func testata(lettera: String, nuotata: NuotataCompletata) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                Circle().fill(Tema.turchese)
                Text(verbatim: lettera)
                    .font(Tema.sottotitolo)
                    .foregroundStyle(Tema.navy)
            }
            .frame(width: 32, height: 32)
            .accessibilityHidden(true)
            Text(verbatim: FormatiUI.dataEOra(nuotata.data))
                .font(Tema.sottotitolo)
                .foregroundStyle(Tema.testo)
            if !nuotata.titolo.isEmpty {
                Text(verbatim: nuotata.titolo)
                    .font(Tema.piccolo)
                    .foregroundStyle(Tema.testoSecondario)
                    .lineLimit(2)
            }
        }
        .carta(padding: 14)
        .accessibilityElement(children: .combine)
    }

    // MARK: Righe

    private func rigaConfronto(_ riga: Riga) -> some View {
        VStack(spacing: 6) {
            Text(verbatim: riga.titolo)
                .font(Tema.piccolo.weight(.bold))
                .foregroundStyle(Tema.testoSecondario)
                .frame(maxWidth: .infinity)
            HStack(alignment: .center, spacing: 8) {
                Text(verbatim: riga.valoreA)
                    .font(Tema.sottotitolo)
                    .foregroundStyle(Tema.testo)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
                differenza(riga)
                    .frame(maxWidth: .infinity)
                Text(verbatim: riga.valoreB)
                    .font(Tema.sottotitolo)
                    .foregroundStyle(Tema.testo)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: etichettaVoiceOver(riga)))
    }

    private func differenza(_ riga: Riga) -> some View {
        HStack(spacing: 4) {
            if riga.verso != 0 {
                Image(systemName: riga.verso > 0 ? "arrow.up" : "arrow.down")
                    .font(.system(.caption, design: .rounded).weight(.bold))
            }
            Text(verbatim: riga.differenza)
                .font(Tema.piccolo.weight(.bold))
                .minimumScaleFactor(0.7)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(Tema.testo)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Capsule().fill(Tema.turchese.opacity(0.18)))
    }

    private func etichettaVoiceOver(_ riga: Riga) -> String {
        testo("confronto.voiceover", riga.titolo, riga.valoreA, riga.valoreB, riga.differenza)
    }

    // MARK: Calcolo delle righe

    private func costruisciRighe(_ na: NuotataCompletata, _ nb: NuotataCompletata) -> [Riga] {
        let confronto = ConfrontoNuotate(a: na, b: nb)
        var righe: [Riga] = []

        // Metri
        let dMetri = confronto.differenzaMetri
        righe.append(Riga(
            id: "metri",
            titolo: testo("confronto.riga.metri"),
            valoreA: FormatiStorico.metri(na.metri),
            valoreB: FormatiStorico.metri(nb.metri),
            differenza: dMetri == 0 ? testo("confronto.uguale")
                : testo("confronto.diff.metri", FormatiStorico.segno(dMetri), FormatiUI.numero(abs(dMetri))),
            verso: dMetri.signum()
        ))

        // Tempo
        let dTempo = confronto.differenzaDurataSecondi
        righe.append(Riga(
            id: "tempo",
            titolo: testo("confronto.riga.tempo"),
            valoreA: FormatoTempo.mmss(na.durataSecondi),
            valoreB: FormatoTempo.mmss(nb.durataSecondi),
            differenza: dTempo == 0 ? testo("confronto.uguale")
                : FormatiStorico.segno(dTempo) + FormatoRitmo.minutiSecondi(Double(abs(dTempo))),
            verso: dTempo.signum()
        ))

        // Ritmo ogni 100 m
        if let ra = na.ritmoPer100Secondi, let rb = nb.ritmoPer100Secondi, let dRitmo = confronto.differenzaRitmoPer100 {
            let arrotondata = Int(dRitmo.rounded())
            righe.append(Riga(
                id: "ritmo",
                titolo: testo("confronto.riga.ritmo"),
                valoreA: FormatoRitmo.minutiSecondi(ra),
                valoreB: FormatoRitmo.minutiSecondi(rb),
                differenza: arrotondata == 0 ? testo("confronto.uguale")
                    : testo("confronto.diff.ritmo", FormatiStorico.segno(arrotondata),
                            FormatoRitmo.minutiSecondi(Double(abs(arrotondata)))),
                verso: arrotondata.signum()
            ))
        }

        // Calorie
        if let ca = na.calorie, let cb = nb.calorie {
            let d = cb - ca
            righe.append(Riga(
                id: "calorie",
                titolo: testo("confronto.riga.calorie"),
                valoreA: testo("dettaglio.valore.kcal", FormatiUI.numero(ca)),
                valoreB: testo("dettaglio.valore.kcal", FormatiUI.numero(cb)),
                differenza: d == 0 ? testo("confronto.uguale")
                    : testo("confronto.diff.kcal", FormatiStorico.segno(d), FormatiUI.numero(abs(d))),
                verso: d.signum()
            ))
        }

        // Frequenza cardiaca media
        if let fa = na.frequenzaCardiacaMedia, let fb = nb.frequenzaCardiacaMedia {
            let d = fb - fa
            righe.append(Riga(
                id: "frequenza",
                titolo: testo("confronto.riga.frequenza"),
                valoreA: testo("dettaglio.valore.bpm", fa),
                valoreB: testo("dettaglio.valore.bpm", fb),
                differenza: d == 0 ? testo("confronto.uguale")
                    : testo("confronto.diff.bpm", FormatiStorico.segno(d), abs(d)),
                verso: d.signum()
            ))
        }

        // Bracciate per vasca
        if let ba = na.bracciatePerVasca, let bb = nb.bracciatePerVasca {
            let d = bb - ba
            let decimi = Int((d * 10).rounded())
            righe.append(Riga(
                id: "bracciate",
                titolo: testo("confronto.riga.bracciate"),
                valoreA: FormatiStorico.decimale(ba),
                valoreB: FormatiStorico.decimale(bb),
                differenza: decimi == 0 ? testo("confronto.uguale")
                    : FormatiStorico.segno(decimi) + FormatiStorico.decimale(abs(d)),
                verso: decimi.signum()
            ))
        }
        return righe
    }
}
