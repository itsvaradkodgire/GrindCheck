import Foundation

// MARK: - Brutal Messages
// Genuine honesty, not meanness. The app tells you what a good mentor would.

enum BrutalMessages {

    // MARK: - By Proficiency Tier

    static func message(forProficiency score: Int, topic: String = "this topic") -> String {
        let pool = messages(forProficiency: score, topic: topic)
        return pool.randomElement() ?? "Keep going."
    }

    private static func messages(forProficiency score: Int, topic: String) -> [String] {
        switch score {
        case 0..<20:
            return tier0Messages(topic: topic)
        case 20..<40:
            return tier1Messages(topic: topic)
        case 40..<60:
            return tier2Messages(topic: topic)
        case 60..<80:
            return tier3Messages(topic: topic)
        case 80..<90:
            return tier4Messages(topic: topic)
        default:
            return tier5Messages(topic: topic)
        }
    }

    // MARK: - Tier 0 (0–19%): You Don't Know This

    private static func tier0Messages(topic: String) -> [String] {
        [
            "You don't know \(topic). Not 'a little.' Not enough. Start from scratch.",
            "0–19% is not 'beginner.' It's 'hasn't started yet.' Be honest about where you are.",
            "Reading about \(topic) once doesn't count as knowing it. You're at square one.",
            "Right now, \(topic) would destroy you in any real interview or exam. Fix that.",
            "This is the part where most people lie to themselves. Don't. You don't know \(topic).",
            "You could not explain \(topic) to a 10-year-old right now. That's your baseline.",
            "If \(topic) came up in an interview tomorrow, you'd be making things up. You know it.",
            "Zero foundation. Not a judgment — just the truth. Now do something about it.",
            "The gap between 'vaguely familiar' and 'actually knows it' is exactly where you are.",
            "You've seen the words. You don't know the concepts. Those are different things.",
        ]
    }

    // MARK: - Tier 1 (20–39%): You've Seen the Words

    private static func tier1Messages(topic: String) -> [String] {
        [
            "You've seen \(topic) before. That's not the same as understanding it.",
            "20–39% means you know the vocabulary. You don't know the material.",
            "You could recognize \(topic) in a sentence. You couldn't use it in one.",
            "This is dangerous territory. You think you know it. You don't. That's worse than knowing nothing.",
            "Dunning-Kruger check: you're at the peak of 'I've heard of this.' Climb down and study.",
            "Surface knowledge. You'd fail any follow-up question. Go deeper.",
            "You know just enough about \(topic) to be confidently wrong.",
            "Recognition is not recall. Recall is not understanding. Understanding is not mastery. You're at recognition.",
            "If someone asked you to implement \(topic) right now, you'd be silent within 60 seconds.",
            "You've scratched the surface and stopped. The surface isn't where the knowledge lives.",
            "A quick look doesn't make you qualified. Come back when you've put in the hours.",
            "You're fooling yourself if you think 20% means 'I've got the basics.' The basics start at 60%.",
        ]
    }

    // MARK: - Tier 2 (40–59%): Halfway and Stalled

    private static func tier2Messages(topic: String) -> [String] {
        [
            "You know enough about \(topic) to be dangerous — and wrong.",
            "Half-knowledge is where most errors come from. You're in that zone.",
            "40–59% means you'll get the easy questions right and the important ones wrong.",
            "You understand the concept. You don't understand when NOT to use it. That's a problem.",
            "You'd pass a multiple-choice test. You'd fail to use \(topic) correctly under pressure.",
            "This is where people plateau. Comfortable enough to stop learning. Not good enough to succeed.",
            "Halfway doesn't get you hired. It doesn't get you through the exam. Keep going.",
            "You have the theory. You need the reps. Stop reading and start doing.",
            "The gap between 50% and 80% is practice. Uncomfortable, real practice.",
            "You know \(topic) like you know a city you visited once. You couldn't navigate it without a map.",
            "Medium proficiency, medium results. If that's acceptable to you, then stop here.",
            "You're in the 'learned it once, half-remember it now' zone. Review or forget.",
        ]
    }

    // MARK: - Tier 3 (60–79%): Decent But Dangerous

    private static func tier3Messages(topic: String) -> [String] {
        [
            "Decent foundation. But decent doesn't pass interviews at the companies you want.",
            "You know \(topic). You don't own it yet. There's a difference.",
            "60–79%: reliable on the expected. Unreliable on the unexpected. Real problems are unexpected.",
            "You could explain \(topic) to someone. You couldn't teach it to someone. Aim for teacher-level.",
            "Good enough to use it. Not good enough to trust it. Get to trust.",
            "You're solid on the standard case. What about the edge cases? Those are what trips people up.",
            "This is respectable. It's not enough. You said you wanted to be good, not respectable.",
            "You can talk about \(topic). Now prove you can apply it without Googling.",
            "The last 20% is the hardest to earn and the most valuable to have. Don't stop here.",
            "Senior engineers think in edge cases and failure modes. You're thinking in happy paths.",
            "Strong understanding, weak mastery. The difference shows up under time pressure.",
        ]
    }

    // MARK: - Tier 4 (80–89%): Solid — Now Go Harder

    private static func tier4Messages(topic: String) -> [String] {
        [
            "Solid. Now test yourself with real problems, not flashcards. Flashcards are training wheels.",
            "80%+ is real knowledge. The missing 20% is where interviews live.",
            "You know \(topic) well. Do you know why it works the way it does? Dig into that.",
            "This is good. Stop celebrating and find what you don't know yet.",
            "Strong. Can you explain the internals? The tradeoffs? The failure modes? Work on those.",
            "80% means you'll ace the easy questions and maybe stumble on the hard ones. Close the gap.",
            "You've put in the work. Now put in more. The difference between 80 and 95 is depth.",
            "You're in the top half. You want to be in the top 10%. That requires going deeper.",
            "Impressive progress. Don't let it become a reason to coast. Mastery is at 90%+.",
            "You understand \(topic). Now use it in a project under real constraints. That's the final test.",
        ]
    }

    // MARK: - Tier 5 (90–100%): Think You've Mastered It?

    private static func tier5Messages(topic: String) -> [String] {
        [
            "You think you've mastered \(topic)? Teach it to someone. If you can't explain every 'why,' you haven't.",
            "90%+ is impressive. It's also exactly when people stop learning. Don't.",
            "High proficiency. Can you debug it when it breaks in production at 2am? That's mastery.",
            "You know \(topic). Now go find the part you don't know. It exists.",
            "Top of the scale. The questions at this level aren't in textbooks. They're in production systems.",
            "Excellent. What are the known limitations? What would you change about how \(topic) is designed?",
            "Strong mastery. Stay curious. The moment you think you know everything is when you stop growing.",
            "This is where you start teaching others. If you can't, you have gaps you haven't found yet.",
            "You've reached the score. Now reach the depth. Scores don't tell the whole story.",
            "100% on the quiz means you know what you've been asked. The real world asks different questions.",
        ]
    }

    // MARK: - Quiz Score Feedback

    static func quizFeedback(percentage: Double, topic: String, previousScore: Int? = nil) -> String {
        let pct = Int(percentage)

        if let prev = previousScore {
            let delta = pct - prev
            switch delta {
            case ...(-20):
                return "You dropped \(abs(delta))% on \(topic). Not a bad day — a bad habit. Figure out what changed."
            case (-19)...(-10):
                return "Down \(abs(delta))% from last time. You're going backwards on \(topic). Review it tonight."
            case (-9)...(-1):
                return "Slightly worse than last time. Probably not studying \(topic) consistently enough."
            case 0:
                return "Exact same score as last time. You're studying the same way and getting the same results. Change something."
            case 1...10:
                return "Small improvement on \(topic). Progress exists. It's just slow. Keep the reps coming."
            case 11...20:
                return "Decent improvement. \(topic) is clicking. Don't stop reviewing it."
            default:
                return "Big jump on \(topic). That's what consistent studying looks like. Don't lose the momentum."
            }
        }

        switch pct {
        case 0..<30:
            return "Under 30% on \(topic). You're not ready for this quiz yet. Study first, quiz second."
        case 30..<50:
            return "\(pct)% — you guessed your way through half of it. That's not studying, that's gambling."
        case 50..<60:
            return "\(pct)% — barely passing. You know some of it. You don't know most of it."
        case 60..<70:
            return "\(pct)% — passing grade, failing understanding. The 40% you missed will come back to haunt you."
        case 70..<80:
            return "\(pct)% — decent attempt. The gaps are still there. Find them before they find you."
        case 80..<90:
            return "\(pct)% on \(topic). Solid. Now find which questions you got wrong and learn them cold."
        case 90..<100:
            return "\(pct)% — strong. One wrong answer away from perfect. Hunt it down."
        case 100:
            return "100% on \(topic). Either it was too easy or you genuinely know it. Try a harder mode."
        default:
            return "Score logged. Keep going."
        }
    }

    // MARK: - Streak Messages

    static func streakMessage(days: Int) -> String {
        switch days {
        case 0:
            return "Streak broken. The clock resets. But you already knew you should've studied yesterday."
        case 1:
            return "Day 1. Anyone can do Day 1. Let's see Day 7."
        case 3:
            return "3 days in. Not a streak yet. This is just 'not quitting immediately.'"
        case 7:
            return "One week. This is where most people stop. You haven't. Keep that momentum."
        case 14:
            return "Two weeks straight. It's becoming a habit. Habits are hard to break — use that."
        case 30:
            return "30 days. You've made it further than 95% of people who start these apps. Don't waste it."
        case 60:
            return "60 days. This is no longer a streak. This is a lifestyle. Own it."
        case 100:
            return "100 days. You're not the same person who started this. Respect."
        default:
            if days % 10 == 0 {
                return "\(days) days. Every day you show up is a day most people didn't."
            }
            return "\(days) day streak. Don't break it over something that doesn't matter."
        }
    }

    // MARK: - Stagnation Messages

    static func stagnationMessage(topic: String, daysSince: Int) -> String {
        switch daysSince {
        case 14..<21:
            return "You haven't touched \(topic) in \(daysSince) days. It's starting to decay."
        case 21..<30:
            return "\(topic) has been sitting untouched for 3 weeks. What you learned is fading."
        case 30..<45:
            return "A month without \(topic). Your proficiency score doesn't reflect what you actually remember anymore."
        case 45..<60:
            return "\(topic) is rotting. 6 weeks of neglect means you're close to starting over."
        case 60...:
            return "Two months without \(topic). Be honest: you've forgotten most of it. Start the review."
        default:
            return "\(topic) needs attention. Don't wait longer."
        }
    }

    // MARK: - Daily Reality Check

    static func dailyCheck(studyMinutes: Int, goalMinutes: Int, streak: Int) -> String {
        let goalPercent = goalMinutes > 0 ? Double(studyMinutes) / Double(goalMinutes) : 0

        if studyMinutes == 0 {
            return "Zero minutes today. Not a rest day if you didn't plan it as one. Show up tomorrow."
        }

        if studyMinutes < 5 {
            return "Under 5 minutes doesn't count. You know that."
        }

        if goalPercent >= 1.0 {
            let messages = [
                "Goal hit. Good. Tomorrow it gets harder.",
                "Daily goal: done. Consistency over intensity. Come back tomorrow.",
                "You showed up and hit the goal. That's all you need to do. Every day.",
                "Target reached. Don't coast on it — reset for tomorrow.",
            ]
            return messages.randomElement()!
        }

        if goalPercent >= 0.7 {
            return "\(Int(goalPercent * 100))% of today's goal. Close. You know what to do with the remaining \(goalMinutes - studyMinutes) minutes."
        }

        if goalPercent >= 0.5 {
            return "Halfway there. The second half is always harder to find motivation for. Find it anyway."
        }

        return "\(studyMinutes) minutes. Your goal is \(goalMinutes). You're not done yet."
    }

    // MARK: - Session Too Short

    static let tooShortMessages: [String] = [
        "That wasn't studying. That was opening a book and putting it down.",
        "Under 5 minutes. You didn't study today. You visited the idea of studying.",
        "That session doesn't count and you know it.",
        "Opening the app isn't studying. Sitting down for 3 minutes isn't studying.",
        "Less than 5 minutes. Come back when you're actually ready to commit.",
        "You sat down, got distracted, and left. That's not a study session.",
        "Participation trophy mode activated. You showed up but you didn't do the work.",
    ]

    // MARK: - Weekly Report Openers

    static let weeklyReportOpeners: [String] = [
        "Here's what your week actually looked like:",
        "Let's talk about what you did — and what you avoided — this week:",
        "Your weekly reality check. No filters:",
        "Week in review. Honest edition:",
        "This week by the numbers — and what they actually mean:",
    ]

    // MARK: - Welcome Back

    static func welcomeBack(name: String, daysMissed: Int) -> String {
        switch daysMissed {
        case 1:
            return "You missed yesterday, \(name). Don't let one day become two."
        case 2...3:
            return "Welcome back, \(name). \(daysMissed) days off. Your knowledge doesn't take days off."
        case 4...7:
            return "It's been \(daysMissed) days, \(name). A lot can decay in a week. Let's check the damage."
        case 8...14:
            return "Two weeks, \(name). Some of what you learned is gone. Time to find out how much."
        default:
            return "\(daysMissed) days away, \(name). Starting over isn't failure. Staying away is."
        }
    }
}
