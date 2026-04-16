import SwiftUI
import SwiftData

struct WeeklyGapReportCard: View {

    let geminiService: GeminiService
    let subjects: [Subject]
    let logs: [DailyLog]

    @AppStorage("weeklyReportText")    private var reportText: String = ""
    @AppStorage("weeklyReportDate")    private var reportDateInterval: Double = 0
    @State private var isLoading = false
    @State private var error: String? = nil
    @State private var isExpanded = false

    private var reportDate: Date? {
        reportDateInterval > 0 ? Date(timeIntervalSince1970: reportDateInterval) : nil
    }

    private var isStale: Bool {
        guard let d = reportDate else { return true }
        return Calendar.current.dateComponents([.day], from: d, to: Date()).day ?? 99 >= 7
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Weekly Report", systemImage: "chart.bar.doc.horizontal.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(hex: AppColors.secondary))
                Spacer()
                if let d = reportDate {
                    Text(d, style: .relative)
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: AppColors.muted))
                }
                Button {
                    Task { await generateReport() }
                } label: {
                    if isLoading {
                        ProgressView().scaleEffect(0.75).tint(Color(hex: AppColors.secondary))
                    } else {
                        Image(systemName: isStale ? "arrow.clockwise.circle.fill" : "arrow.clockwise")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: isStale ? AppColors.secondary : AppColors.muted))
                    }
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
            }

            if reportText.isEmpty {
                if subjects.isEmpty {
                    Text("Add subjects and take some quizzes to generate your first weekly report.")
                        .font(.caption)
                        .foregroundStyle(Color(hex: AppColors.muted))
                } else {
                    Button {
                        Task { await generateReport() }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                            Text("Generate This Week's Report")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(Color(hex: AppColors.background))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: AppColors.secondary))
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading)
                }
            } else {
                Text(LocalizedStringKey(isExpanded ? reportText : String(reportText.prefix(200)) + (reportText.count > 200 ? "…" : "")))
                    .font(.caption)
                    .foregroundStyle(Color(hex: AppColors.neutral))
                    .fixedSize(horizontal: false, vertical: true)

                if reportText.count > 200 {
                    Button(isExpanded ? "Show less" : "Read more") {
                        withAnimation { isExpanded.toggle() }
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(hex: AppColors.secondary))
                }
            }

            if let error {
                Text(error).font(.system(size: 10)).foregroundStyle(Color(hex: AppColors.danger))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: AppColors.surfacePrimary))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color(hex: AppColors.secondary).opacity(0.2), lineWidth: 1)
                )
        )
    }

    private func generateReport() async {
        guard geminiService.hasAPIKey else {
            error = "Add your Gemini API key in AI Coach first."
            return
        }
        isLoading = true; error = nil
        do {
            let report = try await geminiService.generateWeeklyGapReport(
                subjects: subjects,
                recentLogs: Array(logs.prefix(7))
            )
            reportText         = report
            reportDateInterval = Date().timeIntervalSince1970
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
