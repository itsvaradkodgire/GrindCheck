import SwiftUI
import SwiftData

@main
struct GrindCheckApp: App {

    let container: ModelContainer
    @State private var appState     = AppState()
    @State private var geminiService = GeminiService()

    init() {
        let schema = Schema([
            UserProfile.self,
            Subject.self,
            Topic.self,
            Question.self,
            QuizAttempt.self,
            StudySession.self,
            DailyLog.self,
            Achievement.self,
            ChatMessage.self,
            StudyMaterial.self,
            AIRoadmap.self,
            RoadmapPhase.self,
            TopicArticle.self,
            ArticleSection.self,
        ])

        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        // Try to open the existing store. If the schema has changed and
        // SwiftData can't migrate automatically, wipe the store and start fresh.
        // This is safe during development — production would use a migration plan.
        if let c = try? ModelContainer(for: schema, configurations: [config]) {
            container = c
        } else {
            // Schema mismatch — delete the old store file and recreate.
            Self.deleteSwiftDataStore()
            do {
                container = try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("GrindCheck: ModelContainer failed even after store reset — \(error)")
            }
        }
    }

    private static func deleteSwiftDataStore() {
        let fm = FileManager.default

        // SwiftData stores the default database in Application Support,
        // sometimes nested under the bundle identifier on macOS.
        var searchDirs = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)

        if let bundleID = Bundle.main.bundleIdentifier {
            let nested = searchDirs.map { $0.appendingPathComponent(bundleID) }
            searchDirs.append(contentsOf: nested)
        }

        let storeNames = ["default.store", "default.store-shm", "default.store-wal"]
        for dir in searchDirs {
            for name in storeNames {
                try? fm.removeItem(at: dir.appendingPathComponent(name))
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(container)
                .preferredColorScheme(.dark)
                .environment(appState)
                .environment(geminiService)
        }
        #if os(macOS)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .defaultSize(width: 1200, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) { }   // disable Cmd+N default
        }
        #endif
    }
}
