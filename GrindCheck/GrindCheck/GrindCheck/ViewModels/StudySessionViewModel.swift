import Foundation
import Observation
import SwiftData
#if os(iOS)
import UserNotifications
#endif

@Observable
final class StudySessionViewModel {

    // MARK: - Phases & Status

    enum TimerPhase { case work, shortBreak, longBreak }
    enum Status     { case idle, active, paused, complete }

    // MARK: - Configuration

    var selectedTopic: Topic?          = nil
    var selectedSubject: Subject?      = nil
    var sessionType: SessionType       = .study
    var isPomodoro: Bool               = true
    var workMinutes: Int               = AppConfig.pomodoroWorkMinutes     // 25
    var shortBreakMinutes: Int         = AppConfig.pomodoroBreakMinutes    // 5
    var longBreakMinutes: Int          = 15

    // MARK: - Timer State

    var status: Status                 = .idle
    var phase: TimerPhase              = .work
    var pomodoroCount: Int             = 0
    var targetEndDate: Date?           = nil
    var pausedTimeRemaining: Double    = 0
    var elapsedWorkSeconds: Int        = 0
    var sessionStartDate: Date?        = nil

    // MARK: - Post-Session

    var showSummary: Bool              = false
    var focusRating: Int               = 3
    var notes: String                  = ""

    // MARK: - Computed

    var timeRemaining: Double {
        guard let target = targetEndDate else {
            return isPomodoro ? Double(workMinutes * 60) : Double(workMinutes * 60)
        }
        return max(0, target.timeIntervalSinceNow)
    }

    var phaseDuration: Double {
        switch phase {
        case .work:       return Double(workMinutes * 60)
        case .shortBreak: return Double(shortBreakMinutes * 60)
        case .longBreak:  return Double(longBreakMinutes * 60)
        }
    }

    var progressFraction: Double {
        let remaining = timeRemaining
        let total     = phaseDuration
        guard total > 0 else { return 0 }
        return 1.0 - (remaining / total)
    }

    var elapsedMinutes: Int { elapsedWorkSeconds / 60 }

    var timeDisplay: String {
        let secs = Int(timeRemaining)
        return String(format: "%d:%02d", secs / 60, secs % 60)
    }

    var phaseLabel: String {
        switch phase {
        case .work:       return isPomodoro ? "Focus" : "Studying"
        case .shortBreak: return "Short Break"
        case .longBreak:  return "Long Break"
        }
    }

    var isWorking: Bool { phase == .work }

    var completedPomodoros: Int { pomodoroCount }

    var currentTopicName: String {
        selectedTopic?.name ?? selectedSubject?.name ?? "General Study"
    }

    // MARK: - Timer Control

    func start() {
        guard status == .idle else { return }
        status           = .active
        phase            = .work
        sessionStartDate = Date()
        setTargetDate(for: phase)
        scheduleNotification()
    }

    func pause() {
        guard status == .active else { return }
        pausedTimeRemaining = timeRemaining
        targetEndDate       = nil
        status              = .paused
        cancelNotification()
    }

    func resume() {
        guard status == .paused else { return }
        status        = .active
        targetEndDate = Date().addingTimeInterval(pausedTimeRemaining)
        scheduleNotification()
    }

    func stop(context: ModelContext) {
        guard status != .idle else { return }
        finalizeSession(context: context)
        status        = .idle
        showSummary   = true
    }

    /// Called every tick from the view. Returns true if a phase just ended.
    @discardableResult
    func tick() -> Bool {
        guard status == .active, let target = targetEndDate else { return false }
        if Date() >= target {
            handlePhaseEnd()
            return true
        }
        // Accumulate elapsed work seconds
        if phase == .work { elapsedWorkSeconds += 1 }
        return false
    }

    // MARK: - Phase Transitions

    private func handlePhaseEnd() {
        HapticManager.shared.comboMilestone()

        if phase == .work {
            pomodoroCount += 1
            // Every 4 pomodoros → long break
            phase = (pomodoroCount % 4 == 0) ? .longBreak : .shortBreak
        } else {
            phase = .work
        }

        if !isPomodoro {
            // In non-Pomodoro mode, just mark complete
            status = .complete
            return
        }

        setTargetDate(for: phase)
        scheduleNotification()
    }

    private func setTargetDate(for phase: TimerPhase) {
        let seconds: Double
        switch phase {
        case .work:       seconds = Double(workMinutes * 60)
        case .shortBreak: seconds = Double(shortBreakMinutes * 60)
        case .longBreak:  seconds = Double(longBreakMinutes * 60)
        }
        targetEndDate = Date().addingTimeInterval(seconds)
    }

    // MARK: - Session Persistence

    private func finalizeSession(context: ModelContext) {
        let duration = max(0, elapsedWorkSeconds / 60)
        guard duration >= AppConfig.minSessionMinutesForCredit else { return }

        let session = StudySession(
            topic:       selectedTopic,
            subject:     selectedSubject ?? selectedTopic?.subject,
            sessionType: sessionType,
            wasPomodoro: isPomodoro
        )
        session.startTime      = sessionStartDate ?? Date()
        session.endTime        = Date()
        session.durationMinutes = duration
        session.focusRating    = focusRating
        session.notes          = notes
        session.pomodoroCount  = pomodoroCount
        session.brutalSummary  = BrutalMessages.dailyCheck(
            studyMinutes: duration,
            goalMinutes: 60,
            streak: 0
        )

        context.insert(session)

        // Update topic/subject stats
        selectedTopic?.addStudyTime(minutes: duration)

        // Award XP
        let engine = GamificationEngine(context: context)
        engine.recordStudySession(durationMinutes: duration, topicId: selectedTopic?.id)

        try? context.save()
    }

    // MARK: - Notifications

    private func scheduleNotification() {
        #if os(iOS)
        cancelNotification()
        guard let target = targetEndDate else { return }
        let delay = target.timeIntervalSinceNow
        guard delay > 0 else { return }

        let content      = UNMutableNotificationContent()
        content.title    = phase == .work ? "Pomodoro Complete 🔥" : "Break Over"
        content.body     = phase == .work
            ? "\(workMinutes) min on \(currentTopicName). Time to breathe."
            : "Break done. Back to \(currentTopicName)."
        content.sound    = .default

        let trigger      = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request      = UNNotificationRequest(identifier: "grindcheck-timer", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
        #endif
    }

    private func cancelNotification() {
        #if os(iOS)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["grindcheck-timer"])
        #endif
    }

    // MARK: - Reset

    func resetForNewSession() {
        status              = .idle
        phase               = .work
        pomodoroCount       = 0
        targetEndDate       = nil
        pausedTimeRemaining = 0
        elapsedWorkSeconds  = 0
        sessionStartDate    = nil
        showSummary         = false
        focusRating         = 3
        notes               = ""
    }
}
