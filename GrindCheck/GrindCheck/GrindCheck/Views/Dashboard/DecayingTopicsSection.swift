import SwiftUI

struct DecayingTopicsSection: View {
    let topics: [Topic]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(
                icon: "arrow.down.heart.fill",
                iconColor: AppColors.danger,
                title: "Decaying Topics",
                subtitle: "Not studied in 14+ days"
            )

            ForEach(topics) { topic in
                DecayTopicRow(topic: topic)
            }
        }
    }
}

// MARK: - Decay Topic Row

private struct DecayTopicRow: View {
    let topic: Topic

    private var decayColor: String {
        switch topic.daysSinceLastStudy {
        case 14..<21: return AppColors.warning
        case 21..<30: return AppColors.proficiencyOrange
        default:      return AppColors.danger
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Decay indicator
            Circle()
                .fill(Color(hex: decayColor))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(topic.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)

                if let subject = topic.subject {
                    Text(subject.name)
                        .font(.caption)
                        .foregroundStyle(Color(hex: AppColors.muted))
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(topic.daysSinceLastStudy)d ago")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Color(hex: decayColor))

                Text("\(topic.proficiencyScore)%")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Color(hex: AppColors.muted))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .cardStyle()
    }
}

// MARK: - Subjects Overview Section

struct SubjectsOverviewSection: View {
    let subjects: [Subject]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(
                icon: "books.vertical.fill",
                iconColor: AppColors.primary,
                title: "Subjects",
                subtitle: "\(subjects.count) subjects"
            )

            ForEach(subjects) { subject in
                SubjectOverviewRow(subject: subject)
            }
        }
    }
}

// MARK: - Subject Overview Row (Dashboard version)

private struct SubjectOverviewRow: View {
    let subject: Subject

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color(hex: subject.colorHex).opacity(0.15))
                    .frame(width: 38, height: 38)
                Image(systemName: subject.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: subject.colorHex))
            }

            // Name + topic count
            VStack(alignment: .leading, spacing: 2) {
                Text(subject.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text("\(subject.totalTopics) topics · \(subject.masteredTopics) mastered")
                    .font(.caption)
                    .foregroundStyle(Color(hex: AppColors.muted))
            }

            Spacer()

            // Avg proficiency
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(subject.avgProficiency))%")
                    .font(.system(.subheadline, design: .monospaced, weight: .bold))
                    .foregroundStyle(Color(hex: proficiencyColor(subject.avgProficiency)))

                // Mini proficiency bar
                GeometryReader { _ in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: AppColors.surfaceTertiary))
                            .frame(width: 60, height: 4)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: proficiencyColor(subject.avgProficiency)))
                            .frame(width: 60 * subject.avgProficiency / 100, height: 4)
                    }
                }
                .frame(width: 60, height: 4)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .cardStyle()
    }

    private func proficiencyColor(_ score: Double) -> String {
        ConfidenceLevel.from(proficiency: Int(score)).colorHex
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let icon: String
    let iconColor: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: iconColor))
            Text(title)
                .font(.system(.subheadline, weight: .bold))
                .foregroundStyle(.white)
            Text("·")
                .foregroundStyle(Color(hex: AppColors.muted))
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(Color(hex: AppColors.muted))
            Spacer()
        }
    }
}
