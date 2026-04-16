# GrindCheck

A native Apple study tracker built for people who are serious about learning. I vibe coded this entire app — from the data models to the AI integration — as a personal project to actually track and improve how I study.

No fluff, no social features, no streaks that lie to you. Just raw progress tracking, spaced repetition, AI-powered study guides, and brutal honest feedback about whether you're actually learning or just going through the motions.

---

## Screenshots

> Coming soon

---

## Features

### Feed
- Scrollable card feed — each session surfaces the most relevant content
- **FlashCards** — spaced repetition cards with FSRS scheduling
- **Quiz Cards** — inline MCQ, true/false, short answer, explain-this, code output
- **Due Review Banner** — surfaces cards scheduled for today
- **Weekly Debrief** — XP delta, study time, quiz count every Monday
- **Fail → Study Guide** — get a wrong answer? Tap "Read the concept →" to jump straight to the study guide

### Subjects & Topics
- Grid of subjects, each with topics and per-topic proficiency scores
- **Weak Spot Heatmap** — grid of topics × question types colored by accuracy
- **Interview Readiness Score** — weighted formula: proficiency + coverage + accuracy + recency
- **Pace Projection** — "~X days to 80% proficiency" based on your last 7 days of study
- Long-press a subject card → **Export as JSON** or **Delete**

### Quiz
- 4 modes: Quick Fire, Deep Dive, Mixed Bag, Weak Spots
- Timed questions with haptic feedback
- FSRS-based spaced repetition scheduling on every answer
- Session Intelligence — post-quiz analysis of what to focus on next

### Knowledge Base (Study Guide)
- AI-generated study guides per topic (summary, concepts, explanation, code, mistakes, reference)
- **Teach It Back** — write your own explanation, AI grades it 1–5 and tells you what you missed
- Verify / flag / edit each section manually
- Upload your own JSON study guide

### AI Coach
- Gemini-powered chat coach
- Roadmap generator — describe your goal, get a structured learning plan imported directly into your subjects
- Weekly gap report — AI identifies your weakest clusters
- Code analysis — paste code, AI infers which topics you've mastered
- Job description import — paste a JD, get a gap analysis against your current topics

### Import / Export
- **Import subject from JSON** — download template, fill it in (or give it to an AI), upload everything at once: subject + topics + questions + study guide
- **Export subject to JSON** — long-press any subject → Export as JSON → share
- The template is self-documenting with inline hints so any AI can fill it in correctly
- Bulk upload questions (CSV) or study guide (JSON) per topic

### Profile & Settings
- Edit name, daily goal, difficulty preference
- Haptics + sound toggles
- **Reset Everything** — requires a 3-second hold + typing "RESET" — two gates to prevent accidents

---

## Tech Stack

| Layer | Tech |
|---|---|
| UI | SwiftUI |
| Data | SwiftData |
| AI | Google Gemini API (REST) |
| Spaced Repetition | FSRS algorithm |
| Platform | iOS 17+ / macOS 14+ |
| Language | Swift 5.9 |

---

## Project Structure

```
GrindCheck/
├── GrindCheckApp.swift          # App entry point, ModelContainer setup
│
├── Models/                      # SwiftData @Model classes
│   ├── UserProfile.swift        # XP, level, streak, goals, freeze tokens
│   ├── Subject.swift            # Top-level subject (Python, ML, etc.)
│   ├── Topic.swift              # Chapter/concept within a subject
│   ├── Question.swift           # Individual question with FSRS state
│   ├── TopicArticle.swift       # Study guide container per topic
│   ├── ArticleSection.swift     # Individual study guide section
│   ├── QuizAttempt.swift        # Quiz session result
│   ├── StudySession.swift       # Timed study session
│   ├── DailyLog.swift           # Per-day study summary
│   ├── Achievement.swift        # Achievement definitions + progress
│   ├── ChatMessage.swift        # AI coach conversation history
│   ├── StudyMaterial.swift      # Uploaded study material
│   ├── AIRoadmap.swift          # AI-generated learning roadmap
│   ├── AppState.swift           # Global observable app state
│   └── Enums.swift              # Shared enums (QuestionType, DifficultyLevel, etc.)
│
├── ViewModels/
│   ├── QuizViewModel.swift      # Quiz session state machine
│   ├── FeedViewModel.swift      # Feed card generation logic
│   ├── AICoachViewModel.swift   # Gemini chat + tools orchestration
│   └── StudySessionViewModel.swift
│
├── Services/
│   ├── GeminiService.swift      # All Gemini API calls (questions, articles, grading, roadmap)
│   ├── FSRSService.swift        # FSRS spaced repetition scheduling
│   ├── ProficiencyEngine.swift  # Quiz question selection + difficulty scaling
│   ├── GamificationEngine.swift # XP awards, level-up, achievements
│   └── WidgetDataService.swift  # Widget data provider
│
├── Views/
│   ├── Feed/                    # Scrollable card feed
│   │   ├── ScrollFeedView.swift
│   │   ├── FeedCard.swift       # Card type enum
│   │   ├── FeedCardDispatcher.swift
│   │   └── Cards/               # FlashCard, QuizCard, DueReviewCard, WeeklyDebriefCard, ...
│   │
│   ├── Dashboard/               # Stats, heatmap, XP, streak
│   │   ├── DashboardView.swift
│   │   ├── ProfileSettingsView.swift  # Edit profile + Reset Everything
│   │   ├── StudyHeatmapView.swift
│   │   └── ...
│   │
│   ├── Subjects/                # Subject grid, topic list, import/export
│   │   ├── SubjectsGridView.swift
│   │   ├── SubjectDetailView.swift    # Heatmap, readiness, pace projection
│   │   ├── TopicDetailView.swift      # Questions + study guide tabs
│   │   ├── SubjectImportView.swift    # Full subject JSON import
│   │   ├── BulkUploadView.swift       # CSV questions / JSON guide upload
│   │   └── WeakSpotHeatmapView.swift
│   │
│   ├── KnowledgeBase/
│   │   └── TopicArticleView.swift     # Study guide viewer + Teach It Back
│   │
│   ├── Quiz/                    # Quiz mode selector + active quiz
│   │   ├── QuizModeSelector.swift
│   │   ├── QuizActiveView.swift
│   │   └── QuizResultsView.swift
│   │
│   ├── AICoach/                 # Chat, roadmap, tools
│   │   ├── AICoachView.swift
│   │   ├── ChatView.swift
│   │   ├── RoadmapView.swift
│   │   └── AIToolsView.swift
│   │
│   ├── StudySession/            # Timer, session summary
│   └── Shared/                  # Tab bar, root view, empty states
│
├── Resources/
│   ├── SeedDataManager.swift    # First-launch seed: subjects, topics, questions, articles
│   ├── AchievementDefinitions.swift
│   └── BrutalMessages.swift     # Honest feedback copy
│
└── Utilities/
    ├── Extensions.swift         # Color(hex:), Date helpers, View helpers
    ├── Constants.swift          # AppColors, GeminiConfig
    ├── HapticManager.swift
    ├── KeychainHelper.swift     # Secure API key storage
    ├── CSVParser.swift          # Bulk question CSV parser
    └── StudyGuideParser.swift   # Study guide JSON parser
```

---

## Getting Started

### Prerequisites
- Xcode 15+
- iOS 17+ device or simulator / macOS 14+
- A [Google Gemini API key](https://aistudio.google.com/app/apikey) (free tier works)

### Setup
1. Clone the repo
   ```bash
   git clone https://github.com/varadkodgire/GrindCheck.git
   ```
2. Open `GrindCheck/GrindCheck.xcodeproj` in Xcode
3. Set your Team in Signing & Capabilities
4. Build and run
5. On first launch, tap the key icon in AI Coach tab → paste your Gemini API key

### Adding Your Own Content
**Option A — Import from JSON (recommended)**
- Subjects tab → `+` → Import from JSON
- Download the template — it has full inline instructions
- Give the template to ChatGPT/Claude: *"Fill this GrindCheck template for [your subject]"*
- Upload the filled JSON — everything is created in one shot

**Option B — Manual**
- Subjects tab → `+` → Create Subject → add topics one by one
- Inside each topic → add questions manually or bulk-upload CSV

---

## Subject JSON Format

The import/export format is fully documented inside the template itself. Short version:

```json
{
  "subject": { "name": "...", "icon": "book.fill", "colorHex": "#6C63FF" },
  "topics": [
    {
      "name": "Topic Name",
      "questions": [
        {
          "questionText": "...",
          "questionType": "mcq | trueFalse | shortAnswer | explainThis | codeOutput",
          "options": ["A", "B", "C", "D"],
          "correctAnswer": "A",
          "explanation": "...",
          "difficulty": 1,
          "tags": ["tag"]
        }
      ],
      "studyGuide": [
        {
          "type": "summary | concepts | explanation | code | mistakes | reference",
          "title": "...",
          "content": "Markdown supported",
          "confidence": "high | medium | low"
        }
      ]
    }
  ]
}
```

---

## License

MIT
