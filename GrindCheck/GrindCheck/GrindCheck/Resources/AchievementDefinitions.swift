import Foundation

// MARK: - Achievement Definition (used by GamificationEngine to seed the Achievement table)

struct AchievementDef {
    let id: String
    let name: String
    let description: String
    let icon: String
    let rarity: AchievementRarity
    let targetValue: Double
}

enum AchievementDefinitions {

    // MARK: - All Definitions

    static let all: [AchievementDef] = common + rare + epic + legendary

    // MARK: - Common

    static let common: [AchievementDef] = [
        .init(id: "first_blood",
              name: "First Blood",
              description: "Complete your first quiz.",
              icon: "drop.fill",
              rarity: .common, targetValue: 1),

        .init(id: "note_taker",
              name: "Note Taker",
              description: "Add your first custom question.",
              icon: "pencil.circle.fill",
              rarity: .common, targetValue: 1),

        .init(id: "clock_in",
              name: "Clock In",
              description: "Complete your first study session.",
              icon: "timer",
              rarity: .common, targetValue: 1),

        .init(id: "daily_dose",
              name: "Daily Dose",
              description: "Study on 3 consecutive days.",
              icon: "pill.fill",
              rarity: .common, targetValue: 3),

        .init(id: "ten_down",
              name: "Ten Down",
              description: "Answer 10 questions correctly in the feed.",
              icon: "10.circle.fill",
              rarity: .common, targetValue: 10),

        .init(id: "subject_builder",
              name: "Subject Builder",
              description: "Create your first subject.",
              icon: "folder.fill.badge.plus",
              rarity: .common, targetValue: 1),

        .init(id: "topic_creator",
              name: "Topic Creator",
              description: "Add 5 topics across your subjects.",
              icon: "tag.fill",
              rarity: .common, targetValue: 5),

        .init(id: "first_perfect",
              name: "First Perfect",
              description: "Score 100% on any quiz.",
              icon: "star.circle.fill",
              rarity: .common, targetValue: 1),

        .init(id: "xp_starter",
              name: "XP Starter",
              description: "Earn your first 100 XP.",
              icon: "bolt.circle.fill",
              rarity: .common, targetValue: 100),

        .init(id: "reality_accepted",
              name: "Reality Accepted",
              description: "Read 5 brutal feedback messages and come back.",
              icon: "eye.fill",
              rarity: .common, targetValue: 5),

        .init(id: "feed_starter",
              name: "Feed Starter",
              description: "Answer 25 questions in the feed.",
              icon: "play.rectangle.fill",
              rarity: .common, targetValue: 25),

        .init(id: "pomodoro_first",
              name: "First Pomodoro",
              description: "Complete your first 25-minute Pomodoro block.",
              icon: "timer.circle.fill",
              rarity: .common, targetValue: 1),

        .init(id: "first_hour",
              name: "First Hour",
              description: "Study for 60 minutes total.",
              icon: "clock.fill",
              rarity: .common, targetValue: 60),
    ]

    // MARK: - Rare

    static let rare: [AchievementDef] = [
        .init(id: "no_days_off",
              name: "No Days Off",
              description: "Maintain a 7-day study streak.",
              icon: "flame",
              rarity: .rare, targetValue: 7),

        .init(id: "question_machine",
              name: "Question Machine",
              description: "Add 50 custom questions to your bank.",
              icon: "questionmark.bubble.fill",
              rarity: .rare, targetValue: 50),

        .init(id: "night_owl",
              name: "Night Owl",
              description: "Study after midnight 10 times.",
              icon: "moon.stars.fill",
              rarity: .rare, targetValue: 10),

        .init(id: "speed_demon",
              name: "Speed Demon",
              description: "Answer 5 questions correctly in under 10 seconds each.",
              icon: "bolt.fill",
              rarity: .rare, targetValue: 5),

        .init(id: "comeback_kid",
              name: "Comeback Kid",
              description: "Improve a quiz score by 30%+ on retry.",
              icon: "arrow.counterclockwise.circle.fill",
              rarity: .rare, targetValue: 1),

        .init(id: "hundred_hours",
              name: "Hundred Hours",
              description: "Log 100 total study hours.",
              icon: "100.circle.fill",
              rarity: .rare, targetValue: 6000),  // minutes

        .init(id: "triple_subject",
              name: "Triple Threat",
              description: "Study 3 different subjects in one day.",
              icon: "3.circle.fill",
              rarity: .rare, targetValue: 1),

        .init(id: "quiz_veteran",
              name: "Quiz Veteran",
              description: "Complete 25 quizzes.",
              icon: "checkmark.seal.fill",
              rarity: .rare, targetValue: 25),

        .init(id: "early_bird",
              name: "Early Bird",
              description: "Study before 7am five times.",
              icon: "sunrise.fill",
              rarity: .rare, targetValue: 5),

        .init(id: "nemesis_slayer",
              name: "Nemesis Slayer",
              description: "Answer a nemesis question correctly 3 times in a row.",
              icon: "shield.fill",
              rarity: .rare, targetValue: 1),

        .init(id: "bookmarked",
              name: "Bookmarked",
              description: "Bookmark 20 feed cards for review.",
              icon: "bookmark.fill",
              rarity: .rare, targetValue: 20),

        .init(id: "xp_thousand",
              name: "Four Figures",
              description: "Earn 1,000 total XP.",
              icon: "1.circle.fill",
              rarity: .rare, targetValue: 1000),

        .init(id: "deep_diver",
              name: "Deep Diver",
              description: "Complete 5 Deep Dive quiz sessions.",
              icon: "arrow.down.to.line.circle.fill",
              rarity: .rare, targetValue: 5),
    ]

    // MARK: - Epic

    static let epic: [AchievementDef] = [
        .init(id: "streak_lord",
              name: "Streak Lord",
              description: "Maintain a 30-day study streak.",
              icon: "flame.fill",
              rarity: .epic, targetValue: 30),

        .init(id: "weak_spot_warrior",
              name: "Weak Spot Warrior",
              description: "Raise a topic from red (< 20%) to cyan (> 80%) proficiency.",
              icon: "arrow.up.heart.fill",
              rarity: .epic, targetValue: 1),

        .init(id: "boss_slayer",
              name: "Boss Slayer",
              description: "Score 80%+ on a Boss Fight.",
              icon: "crown.fill",
              rarity: .epic, targetValue: 1),

        .init(id: "all_rounder",
              name: "All-Rounder",
              description: "Study every subject you have in one day.",
              icon: "circle.grid.3x3.fill",
              rarity: .epic, targetValue: 1),

        .init(id: "feed_fiend",
              name: "Feed Fiend",
              description: "Answer 100 feed questions in a single day.",
              icon: "play.rectangle.on.rectangle.fill",
              rarity: .epic, targetValue: 100),

        .init(id: "perfect_week",
              name: "Perfect Week",
              description: "Hit your daily study goal every day for 7 days.",
              icon: "calendar.badge.checkmark",
              rarity: .epic, targetValue: 7),

        .init(id: "knowledge_architect",
              name: "Knowledge Architect",
              description: "Create 200 questions across your subjects.",
              icon: "building.columns.fill",
              rarity: .epic, targetValue: 200),

        .init(id: "combo_master",
              name: "Combo Master",
              description: "Hit a 20-answer correct streak in the feed.",
              icon: "multiply.circle.fill",
              rarity: .epic, targetValue: 20),

        .init(id: "subject_master",
              name: "Subject Master",
              description: "Reach 80%+ average proficiency across an entire subject.",
              icon: "graduationcap.fill",
              rarity: .epic, targetValue: 1),

        .init(id: "five_hundred_hours",
              name: "Five Hundred",
              description: "Log 500 total study hours.",
              icon: "clock.badge.checkmark.fill",
              rarity: .epic, targetValue: 30000),  // minutes

        .init(id: "quiz_champion",
              name: "Quiz Champion",
              description: "Score 90%+ on 10 different quizzes.",
              icon: "trophy.fill",
              rarity: .epic, targetValue: 10),

        .init(id: "xp_ten_thousand",
              name: "XP Machine",
              description: "Earn 10,000 total XP.",
              icon: "star.fill",
              rarity: .epic, targetValue: 10000),

        .init(id: "pomodoro_century",
              name: "Pomodoro Century",
              description: "Complete 100 Pomodoro blocks.",
              icon: "timer.square",
              rarity: .epic, targetValue: 100),
    ]

    // MARK: - Legendary

    static let legendary: [AchievementDef] = [
        .init(id: "perfect_storm",
              name: "Perfect Storm",
              description: "Score 100% on a Boss Fight.",
              icon: "cloud.bolt.fill",
              rarity: .legendary, targetValue: 1),

        .init(id: "iron_will",
              name: "Iron Will",
              description: "Maintain a 100-day study streak.",
              icon: "shield.lefthalf.filled",
              rarity: .legendary, targetValue: 100),

        .init(id: "reality_check_survivor",
              name: "Reality Check Survivor",
              description: "Receive brutal feedback 50 times and keep coming back.",
              icon: "figure.stand.line.dotted.figure.stand",
              rarity: .legendary, targetValue: 50),

        .init(id: "centurion",
              name: "Centurion",
              description: "Reach Level 100.",
              icon: "person.bust.fill",
              rarity: .legendary, targetValue: 100),

        .init(id: "the_grind",
              name: "The Grind",
              description: "Log 500 total study hours.",
              icon: "hammer.fill",
              rarity: .legendary, targetValue: 30000),

        .init(id: "zero_comfort_zone",
              name: "Zero Comfort Zone",
              description: "Study only weak topics (< 40%) for 30 days straight.",
              icon: "arrow.up.forward.circle.fill",
              rarity: .legendary, targetValue: 30),

        .init(id: "full_mastery",
              name: "Full Mastery",
              description: "Reach mastered status on every topic in a subject.",
              icon: "medal.fill",
              rarity: .legendary, targetValue: 1),

        .init(id: "omniscient",
              name: "Omniscient",
              description: "Answer 5,000 questions correctly total.",
              icon: "brain.head.profile",
              rarity: .legendary, targetValue: 5000),

        .init(id: "xp_hundred_thousand",
              name: "Grind God",
              description: "Earn 100,000 total XP.",
              icon: "bolt.heart.fill",
              rarity: .legendary, targetValue: 100000),
    ]
}
