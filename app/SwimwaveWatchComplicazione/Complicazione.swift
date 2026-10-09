import SwiftUI
import WidgetKit

/// Complicazione del quadrante: un tocco apre Swimwave sull'orologio, da dove parte l'allenamento di oggi.
/// Non mostra dati: l'immagine è sempre la stessa, quindi la cronologia ha una sola voce e non si aggiorna.
struct VoceComplicazione: TimelineEntry {
    let date: Date
}

struct FornitoreComplicazione: TimelineProvider {
    func placeholder(in context: Context) -> VoceComplicazione {
        VoceComplicazione(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (VoceComplicazione) -> Void) {
        completion(VoceComplicazione(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VoceComplicazione>) -> Void) {
        completion(Timeline(entries: [VoceComplicazione(date: Date())], policy: .never))
    }
}

struct VistaComplicazione: View {
    @Environment(\.widgetFamily) private var famiglia
    let voce: VoceComplicazione

    var body: some View {
        switch famiglia {
        case .accessoryInline:
            Label("Swimwave", systemImage: "figure.pool.swim")
        case .accessoryRectangular:
            HStack(spacing: 6) {
                Image(systemName: "figure.pool.swim")
                Text("Swimwave")
                    .font(.headline)
            }
        default:
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "figure.pool.swim")
                    .font(.title3)
            }
        }
    }
}

struct ComplicazioneSwimwave: Widget {
    let kind = "SwimwaveComplicazione"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FornitoreComplicazione()) { voce in
            VistaComplicazione(voce: voce)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Swimwave")
        .description("Apri Swimwave dal quadrante.")
        .supportedFamilies([.accessoryCircular, .accessoryCorner, .accessoryInline, .accessoryRectangular])
    }
}

@main
struct PacchettoComplicazioni: WidgetBundle {
    var body: some Widget {
        ComplicazioneSwimwave()
    }
}
