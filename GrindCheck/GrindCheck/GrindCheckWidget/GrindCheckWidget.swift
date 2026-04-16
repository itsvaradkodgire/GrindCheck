import WidgetKit
import SwiftUI
import SwiftData

// MARK: - At-Risk Topic Model (passed via App Group shared store)

struct AtRiskEntry: TimelineEntry {
    let date: Date
    let topics: [AtRiskTopic]
    let streak: Int
    let freezeTokens: Int
}

struct AtRiskTopic: Identifiable, Codable {
    let id: UUID
    let name: String
    let subjectName: String
    let subjectColor: String
    let proficiency: Int
    let daysOverdue: Int     // negative = overdue by N days
    let reason: AtRiskReason

    enum AtRiskReason: String, Codable {
        case fsrsOverdue   = "Due for review"
        case decaying      = "Knowledge decaying"
        case nemesis       = "Nemesis question"
        case neverStudied  = "Never studied"
    }
}

// MARK: - Provider

struct AtRiskProvider: TimelineProvider {

    func placeholder(in context: Context) -> AtRiskEntry {
        AtRiskEntry(
            date: Date(),
            topics: [
                AtRiskTopic(id: UUID(), name: "Backpropagation", subjectName: "Deep Learning",
                            subjectColor: "#A855F7", proficiency: 42, daysOverdue: -3, reason: .fsrsOverdue),
                AtRiskTopic(id: UUID(), name: "SQL Window Functions", subjectName: "SQL",
                            subjectColor: "#FF9F43", proficiency: 28, daysOverdue: 0, reason: .nemesis),
                AtRiskTopic(id: UUID(), name: "Hypothesis Testing", subjectName: "Statistics",
                            subjectColor: "#00E5FF", proficiency: 55, daysOverdue: -7, reason: .decaying),
            ],
            streak: 7,
            freezeTokens: 2
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (AtRiskEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AtRiskEntry>) -> Void) {
        let entry = loadEntry()
        // Refresh every 3 hours
        let next = Calendar.current.date(byAdding: .hour, value: 3, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func loadEntry() -> AtRiskEntry {
        // Read from shared App Group UserDefaults
        let defaults = UserDefaults(suiteName: "group.com.grindcheck.app")
        let streak   = defaults?.integer(forKey: "currentStreak") ?? 0
        let freezes  = defaults?.integer(forKey: "freezeTokens")  ?? 0

        var topics: [AtRiskTopic] = []
        if let data = defaults?.data(forKey: "atRiskTopics"),
           let decoded = try? JSONDecoder().decode([AtRiskTopic].self, from: data) {
            topics = decoded
        }

        return AtRiskEntry(date: Date(), topics: topics, streak: streak, freezeTokens: freezes)
    }
}

// MARK: - Widget View

struct GrindCheckWidgetEntryView: View {

    var entry: AtRiskEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:  smallView
        case .systemMedium: mediumView
        default:            mediumView
        }
    }

    // MARK: Small (streak + top 1 at-risk topic)

    private var smallView: some View {
        ZStack {
            Color(hex: "0A0A14")
            VStack(alignment: .leading, spacing: 8) {
                // Streak
                HStack(spacing: 4) {
                    Text("\(entry.streak)")
                        .font(.system(size: 22, weight: .black, design: .monospaced))
                        .foregroundStyle(entry.streak > 0 ? Color(hex: "FF9F43") : Color(hex: "666680"))
                    Image(systemName: "flame.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(entry.streak > 0 ? Color(hex: "FF9F43") : Color(hex: "666680"))
                    Spacer()
                    HStack(spacing: 2) {
                        ForEach(0..<min(entry.freezeTokens, 3), id: \.self) { _ in
                            Image(systemName: "snowflake")
                                .font(.system(size: 9))
                                .foregroundStyle(Color(hex: "64D8F0"))
                        }
                    }
                }

                if let top = entry.topics.first {
                    Divider().background(Color(hex: "2A2A40"))
                    VStack(alignment: .leading, spacing: 3) {
                        Text("AT RISK")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(Color(hex: "FF6B6B"))
                            .tracking(1.5)
                        Text(top.name)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                        Text(top.reason.rawValue)
                            .font(.system(size: 10))
                            .foregroundStyle(Color(hex: "888899"))
                    }
                } else {
                    Text("All caught up!")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color(hex: "00E5A0"))
                }
            }
            .padding(12)
        }
    }

    // MARK: Medium (streak + top 3 at-risk topics)

    private var mediumView: some View {
        ZStack {
            Color(hex: "0A0A14")
            HStack(spacing: 12) {
                // Left: streak
                VStack(spacing: 4) {
                    Text("\(entry.streak)")
                        .font(.system(size: 36, weight: .black, design: .monospaced))
                        .foregroundStyle(entry.streak > 0 ? Color(hex: "FF9F43") : Color(hex: "444455"))
                    Image(systemName: "flame.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(entry.streak > 0 ? Color(hex: "FF9F43") : Color(hex: "444455"))
                    Text("streak")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: "666680"))
                    HStack(spacing: 3) {
                        ForEach(0..<5, id: \.self) { i in
                            Image(systemName: "snowflake")
                                .font(.system(size: 9))
                                .foregroundStyle(i < entry.freezeTokens ? Color(hex: "64D8F0") : Color(hex: "333344"))
                        }
                    }
                }
                .frame(width: 70)

                Divider().background(Color(hex: "2A2A40"))

                // Right: at-risk topics
                VStack(alignment: .leading, spacing: 6) {
                    Text("REVIEW NOW")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(Color(hex: "FF6B6B"))
                        .tracking(1.5)

                    if entry.topics.isEmpty {
                        Spacer()
                        Text("All caught up! 🎉")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color(hex: "00E5A0"))
                        Spacer()
                    } else {
                        ForEach(entry.topics.prefix(3)) { topic in
                            HStack(spacing: 6) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color(hex: topic.subjectColor))
                                    .frame(width: 3, height: 28)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(topic.name)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                    Text(topic.reason.rawValue)
                                        .font(.system(size: 9))
                                        .foregroundStyle(Color(hex: "888899"))
                                }
                                Spacer()
                                Text("\(topic.proficiency)%")
                                    .font(.system(size: 10, design: .monospaced, weight: .bold))
                                    .foregroundStyle(proficiencyColor(topic.proficiency))
                            }
                        }
                    }
                }
            }
            .padding(14)
        }
    }

    private func proficiencyColor(_ p: Int) -> Color {
        p >= 70 ? Color(hex: "00E5A0") : p >= 40 ? Color(hex: "FF9F43") : Color(hex: "FF6B6B")
    }
}

// MARK: - Widget Configuration

struct GrindCheckWidget: Widget {
    let kind: String = "GrindCheckWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AtRiskProvider()) { entry in
            GrindCheckWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("GrindCheck")
        .description("See which topics need review today and protect your streak.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Color helper (WidgetKit can't use UIColor/AppColors directly)

private extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: .init(charactersIn: "#"))
        let v = UInt32(h, radix: 16) ?? 0
        self.init(
            red:   Double((v >> 16) & 0xFF) / 255,
            green: Double((v >> 8)  & 0xFF) / 255,
            blue:  Double( v        & 0xFF) / 255
        )
    }
}
