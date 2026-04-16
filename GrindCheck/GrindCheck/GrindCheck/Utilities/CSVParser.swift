import Foundation

// MARK: - CSV Parser
// Handles quoted fields, commas inside quotes, escaped quotes ("")

enum CSVParser {

    static func parse(_ csv: String) -> [[String]] {
        var rows: [[String]] = []
        var currentRow: [String] = []
        var currentField = ""
        var inQuotes = false
        let chars = Array(csv)
        var i = 0

        while i < chars.count {
            let c = chars[i]

            if inQuotes {
                if c == "\"" {
                    // Escaped quote ("")?
                    if i + 1 < chars.count && chars[i + 1] == "\"" {
                        currentField.append("\"")
                        i += 2
                        continue
                    } else {
                        inQuotes = false
                    }
                } else {
                    currentField.append(c)
                }
            } else {
                switch c {
                case "\"":
                    inQuotes = true
                case ",":
                    currentRow.append(currentField.trimmingCharacters(in: .whitespaces))
                    currentField = ""
                case "\n", "\r\n", "\r":
                    currentRow.append(currentField.trimmingCharacters(in: .whitespaces))
                    currentField = ""
                    if !currentRow.allSatisfy({ $0.isEmpty }) {
                        rows.append(currentRow)
                    }
                    currentRow = []
                    // skip \r\n as one
                    if c == "\r" && i + 1 < chars.count && chars[i + 1] == "\n" {
                        i += 1
                    }
                default:
                    currentField.append(c)
                }
            }
            i += 1
        }

        // Last field/row
        currentRow.append(currentField.trimmingCharacters(in: .whitespaces))
        if !currentRow.allSatisfy({ $0.isEmpty }) {
            rows.append(currentRow)
        }

        return rows
    }

    // MARK: - Parse Questions from CSV

    struct ParsedQuestion {
        let questionText: String
        let questionType: QuestionType
        let options: [String]
        let correctAnswer: String
        let explanation: String
        let difficulty: Int
        let tags: [String]
        var parseWarning: String?
    }

    /// Expected columns (row 0 is header, skipped):
    /// questionText, questionType, option1, option2, option3, option4,
    /// correctAnswer, explanation, difficulty, tags
    static func parseQuestions(from csv: String) -> (questions: [ParsedQuestion], errors: [String]) {
        let rows = parse(csv)
        guard rows.count > 1 else {
            return ([], ["File appears empty or has only a header row."])
        }

        var questions: [ParsedQuestion] = []
        var errors: [String] = []

        // Skip header row (index 0)
        for (idx, row) in rows.dropFirst().enumerated() {
            let lineNum = idx + 2  // 1-based, accounting for header

            // Pad row to 10 columns
            var cols = row
            while cols.count < 10 { cols.append("") }

            let text    = cols[0]
            let typeStr = cols[1].lowercased()
            let opt1    = cols[2]
            let opt2    = cols[3]
            let opt3    = cols[4]
            let opt4    = cols[5]
            let answer  = cols[6]
            let expl    = cols[7]
            let diffStr = cols[8]
            let tagsStr = cols[9]

            guard !text.isEmpty else {
                errors.append("Row \(lineNum): questionText is empty — skipped")
                continue
            }
            guard !answer.isEmpty else {
                errors.append("Row \(lineNum): correctAnswer is empty — skipped")
                continue
            }

            let qType: QuestionType
            switch typeStr {
            case "mcq", "multiple choice", "multiplechoice": qType = .mcq
            case "truefalse", "true/false", "true_false", "tf": qType = .trueFalse
            case "shortanswer", "short answer", "short_answer": qType = .shortAnswer
            case "explainthis", "explain this", "explain_this": qType = .explainThis
            case "codeoutput", "code output", "code_output":   qType = .codeOutput
            default:
                qType = .mcq
                errors.append("Row \(lineNum): unknown questionType '\(cols[1])' — defaulted to mcq")
            }

            // Build options
            var options: [String] = []
            if qType == .mcq {
                options = [opt1, opt2, opt3, opt4].filter { !$0.isEmpty }
                if options.count < 2 {
                    errors.append("Row \(lineNum): MCQ needs at least 2 options — skipped")
                    continue
                }
                if !options.contains(answer) {
                    errors.append("Row \(lineNum): correctAnswer '\(answer)' not in options — skipped")
                    continue
                }
            } else if qType == .trueFalse {
                options = ["True", "False"]
            }

            let diff = max(1, min(5, Int(diffStr) ?? 3))
            let tags = tagsStr.isEmpty ? [] : tagsStr.split(separator: ";").map { String($0).trimmingCharacters(in: .whitespaces) }

            var warning: String?
            if diff == 3 && diffStr.isEmpty { warning = "difficulty missing — defaulted to 3" }

            questions.append(ParsedQuestion(
                questionText:  text,
                questionType:  qType,
                options:       options,
                correctAnswer: answer,
                explanation:   expl,
                difficulty:    diff,
                tags:          tags,
                parseWarning:  warning
            ))
        }

        return (questions, errors)
    }

    // MARK: - Template CSV String

    static func questionsTemplate(topicName: String) -> String {
        let header = "questionText,questionType,option1,option2,option3,option4,correctAnswer,explanation,difficulty,tags"
        let eg1 = """
        "What does the 'self' keyword refer to in Python?",mcq,"The current instance","The parent class","The module itself","A built-in function","The current instance","In Python, 'self' refers to the instance of the class being worked with.",3,"python;oop"
        """
        let eg2 = """
        "Python lists are mutable",trueFalse,"True","False","","",True,"Python lists can be modified after creation.",1,"python;data-structures"
        """
        let eg3 = """
        "Explain what a decorator does in Python",shortAnswer,"","","","","A function that wraps another function to extend its behavior","Decorators add functionality to existing functions using @syntax.",4,"python;decorators"
        """
        let note = "# INSTRUCTIONS: Fill rows below. Delete these example rows. questionType: mcq/trueFalse/shortAnswer/explainThis/codeOutput. difficulty: 1-5. tags: semicolon-separated. For mcq: options must be in option1-option4 and correctAnswer must exactly match one option."
        let blankRow = "\"\",mcq,\"\",\"\",\"\",\"\",\"\",\"\",3,\"\""

        return [note, header, eg1, eg2, eg3, blankRow].joined(separator: "\n")
    }
}
