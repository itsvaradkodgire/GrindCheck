import SwiftUI
import SwiftData

// MARK: - Mood Check-In (shown before starting a quiz session)

struct MoodCheckInView: View {

    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    let onContinue: (StudyMood) -> Void
    let onSkip: () -> Void

    @State private var selected: StudyMood? = nil

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        VStack(spacing: 0) {
            Color(hex: AppColors.background).ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                // Header
                VStack(spacing: 8) {
                    Text("How are you feeling?")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                    Text("I'll adjust the session difficulty to match.")
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: AppColors.neutral))
                        .multilineTextAlignment(.center)
                }

                // Mood options
                VStack(spacing: 10) {
                    ForEach(StudyMood.allCases) { mood in
                        MoodOptionRow(mood: mood, isSelected: selected == mood) {
                            withAnimation(.spring(duration: 0.2)) { selected = mood }
                        }
                    }
                }

                // Session description
                if let mood = selected {
                    Text(mood.sessionDescription)
                        .font(.caption)
                        .foregroundStyle(Color(hex: AppColors.neutral))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer()

                // Actions
                VStack(spacing: 10) {
                    Button {
                        let mood = selected ?? .ok
                        saveMood(mood)
                        onContinue(mood)
                    } label: {
                        Text(selected == nil ? "Skip & Start" : "Let's Go")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background {
                                if selected == nil {
                                    RoundedRectangle(cornerRadius: 16).fill(Color(hex: AppColors.surfacePrimary))
                                } else {
                                    RoundedRectangle(cornerRadius: 16).fill(
                                        LinearGradient(colors: [Color(hex: AppColors.primary), Color(hex: AppColors.secondary)],
                                                       startPoint: .leading, endPoint: .trailing))
                                }
                            }
                    }
                    .buttonStyle(.plain)

                    Button("Not now", action: onSkip)
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: AppColors.muted))
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 24)
        }
        .background(Color(hex: AppColors.background))
        .preferredColorScheme(.dark)
    }

    private func saveMood(_ mood: StudyMood) {
        if let p = profile {
            p.lastMoodRating = mood.rawValue
            p.lastMoodDate   = Date()
            try? modelContext.save()
        }
    }
}

// MARK: - Mood Option Row

private struct MoodOptionRow: View {
    let mood: StudyMood
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Text(mood.emoji)
                    .font(.system(size: 28))

                VStack(alignment: .leading, spacing: 2) {
                    Text(mood.label)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(mood.subtitle)
                        .font(.caption)
                        .foregroundStyle(Color(hex: AppColors.muted))
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(isSelected
                                     ? Color(hex: AppColors.primary)
                                     : Color(hex: AppColors.surfaceTertiary))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected
                          ? Color(hex: AppColors.primary).opacity(0.12)
                          : Color(hex: AppColors.surfacePrimary))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(isSelected
                                          ? Color(hex: AppColors.primary).opacity(0.4)
                                          : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - StudyMood Enum

enum StudyMood: Int, CaseIterable, Identifiable {
    case energized = 5
    case focused   = 4
    case ok        = 3
    case tired     = 2
    case stressed  = 1

    var id: Int { rawValue }

    var emoji: String {
        switch self {
        case .energized: return "⚡️"
        case .focused:   return "🎯"
        case .ok:        return "😐"
        case .tired:     return "😴"
        case .stressed:  return "😤"
        }
    }

    var label: String {
        switch self {
        case .energized: return "Energized"
        case .focused:   return "Focused"
        case .ok:        return "OK"
        case .tired:     return "Tired"
        case .stressed:  return "Stressed"
        }
    }

    var subtitle: String {
        switch self {
        case .energized: return "Bring on the hard ones"
        case .focused:   return "Ready to grind"
        case .ok:        return "Normal session"
        case .tired:     return "Keep it light"
        case .stressed:  return "Short and easy"
        }
    }

    var sessionDescription: String {
        switch self {
        case .energized: return "Full session · Hard questions · No time limit extensions"
        case .focused:   return "Full session · Mixed difficulty · Standard timing"
        case .ok:        return "Standard session · Your usual mix"
        case .tired:     return "Shorter session · Easy + medium questions · Extra time"
        case .stressed:  return "10-minute session · Easy questions only · No pressure"
        }
    }

    /// Difficulty cap based on mood (1-5)
    var maxDifficulty: Int {
        switch self {
        case .energized: return 5
        case .focused:   return 5
        case .ok:        return 4
        case .tired:     return 3
        case .stressed:  return 2
        }
    }

    /// Session question count multiplier
    var countMultiplier: Double {
        switch self {
        case .energized: return 1.25
        case .focused:   return 1.0
        case .ok:        return 1.0
        case .tired:     return 0.75
        case .stressed:  return 0.5
        }
    }
}
