import Foundation
import SwiftData

// MARK: - Seed Data Manager
// Populates the database on first launch with realistic, high-quality test data.

@MainActor
final class SeedDataManager {

    private let context: ModelContext

    init(modelContext: ModelContext) {
        self.context = modelContext
    }

    // MARK: - Entry Point

    func seedAll() {
        _ = seedUserProfile()
        let subjects = seedSubjects()
        seedQuestionsFor(subjects: subjects)
        seedAchievements()
        seedArticles(subjects: subjects)
    }

    /// Safe to call on existing installs — only adds articles for topics that have none.
    func seedArticlesIfMissing(subjects: [Subject]) {
        seedArticles(subjects: subjects)
    }

    // MARK: - User Profile

    private func seedUserProfile() -> UserProfile {
        let profile = UserProfile(name: "Grinder", dailyGoalMinutes: 60, difficultyPreference: .normal)
        context.insert(profile)
        return profile
    }

    // MARK: - Subjects & Topics

    private func seedSubjects() -> [Subject] {
        var subjects: [Subject] = []

        // 1. Python
        let python = Subject(name: "Python", icon: "p.circle.fill", colorHex: "#3776AB")
        python.sortOrder = 0
        context.insert(python)
        addTopics(to: python, topics: [
            "Variables, Types & Operators",
            "Functions & Lambda",
            "Lists, Dicts & Comprehensions",
            "Classes & OOP",
            "Decorators & Generators",
            "File I/O & Exceptions",
            "Type Hints & Dataclasses",
            "Virtual Envs & Packaging",
        ])
        subjects.append(python)

        // 2. Machine Learning
        let ml = Subject(name: "Machine Learning", icon: "brain.head.profile", colorHex: "#FF6B6B")
        ml.sortOrder = 1
        context.insert(ml)
        addTopics(to: ml, topics: [
            "Supervised vs Unsupervised",
            "Linear & Logistic Regression",
            "Decision Trees & Random Forests",
            "Bias-Variance Tradeoff",
            "Cross-Validation & Metrics",
            "Feature Engineering",
            "SVM & KNN",
            "Gradient Boosting & XGBoost",
            "Clustering (K-Means, DBSCAN)",
        ])
        subjects.append(ml)

        // 3. Deep Learning
        let dl = Subject(name: "Deep Learning", icon: "cpu", colorHex: "#A855F7")
        dl.sortOrder = 2
        context.insert(dl)
        addTopics(to: dl, topics: [
            "Neural Network Fundamentals",
            "Backpropagation & Gradients",
            "CNNs",
            "RNNs & LSTMs",
            "Transformers & Attention",
            "PyTorch Basics",
            "Regularization (Dropout, BN)",
            "Transfer Learning",
        ])
        subjects.append(dl)

        // 4. Data Analysis
        let da = Subject(name: "Data Analysis", icon: "chart.bar.xaxis", colorHex: "#F7B731")
        da.sortOrder = 3
        context.insert(da)
        addTopics(to: da, topics: [
            "NumPy Arrays & Operations",
            "Pandas DataFrames",
            "Exploratory Data Analysis",
            "Data Cleaning & Wrangling",
            "Matplotlib & Seaborn",
            "Feature Selection",
        ])
        subjects.append(da)

        // 5. Statistics & Math
        let stats = Subject(name: "Statistics & Math", icon: "sum", colorHex: "#00E5FF")
        stats.sortOrder = 4
        context.insert(stats)
        addTopics(to: stats, topics: [
            "Probability Basics",
            "Distributions",
            "Hypothesis Testing",
            "Bayesian Statistics",
            "Linear Algebra",
            "Calculus & Optimization",
        ])
        subjects.append(stats)

        // 6. MLOps & Deployment
        let mlops = Subject(name: "MLOps", icon: "server.rack", colorHex: "#68A063")
        mlops.sortOrder = 5
        context.insert(mlops)
        addTopics(to: mlops, topics: [
            "Docker & Containers",
            "REST APIs with FastAPI",
            "Model Versioning (MLflow)",
            "CI/CD for ML",
            "Cloud Platforms (AWS/GCP/Azure)",
        ])
        subjects.append(mlops)

        // 7. SQL & Databases
        let sql = Subject(name: "SQL", icon: "cylinder.fill", colorHex: "#FF9F43")
        sql.sortOrder = 6
        context.insert(sql)
        addTopics(to: sql, topics: [
            "SELECT & Filtering",
            "JOINs",
            "Aggregations & GROUP BY",
            "Window Functions",
            "CTEs & Subqueries",
            "Query Optimization & Indexes",
        ])
        subjects.append(sql)

        // 8. DSA (for ML/DS interviews)
        let dsa = Subject(name: "DSA", icon: "chart.xyaxis.line", colorHex: "#FF6B6B")
        dsa.sortOrder = 7
        context.insert(dsa)
        addTopics(to: dsa, topics: [
            "Big-O Analysis",
            "Arrays & Hashing",
            "Binary Search",
            "Trees & BST",
            "Graphs & BFS/DFS",
            "Dynamic Programming",
            "Heaps & Priority Queues",
        ])
        subjects.append(dsa)

        return subjects
    }

    private func addTopics(to subject: Subject, topics: [String]) {
        for name in topics {
            let topic = Topic(name: name, subject: subject)
            context.insert(topic)
            subject.topics.append(topic)
        }
    }

    // MARK: - Questions

    private func seedQuestionsFor(subjects: [Subject]) {
        for subject in subjects {
            switch subject.name {
            case "Python":            addPythonQuestions(to: subject)
            case "Machine Learning":  addMLQuestions(to: subject)
            case "Deep Learning":     addDLQuestions(to: subject)
            case "Data Analysis":     addDataAnalysisQuestions(to: subject)
            case "Statistics & Math": addStatsQuestions(to: subject)
            case "MLOps":             addMLOpsQuestions(to: subject)
            case "SQL":               addSQLQuestions(to: subject)
            case "DSA":               addDSAQuestions(to: subject)
            default:                  break
            }
        }
    }

    // MARK: - Python Questions

    private func addPythonQuestions(to subject: Subject) {
        let functions    = subject.topics.first { $0.name == "Functions & Lambda" }
        let classes      = subject.topics.first { $0.name == "Classes & OOP" }
        let decorators   = subject.topics.first { $0.name == "Decorators & Generators" }
        let comprehensions = subject.topics.first { $0.name == "Lists, Dicts & Comprehensions" }

        let questions: [(Topic?, String, QuestionType, [String], String, String, Int)] = [
            (functions,
             "What will this print?\n\ndef f(x, lst=[]):\n    lst.append(x)\n    return lst\n\nprint(f(1))\nprint(f(2))",
             .codeOutput, [], "[1]\n[1, 2]",
             "Default mutable arguments in Python are created ONCE when the function is defined, not on each call. The list `lst` is shared across all calls. This is a classic Python gotcha. Fix: use `lst=None` and set `lst = []` inside the function if it's None.",
             4),

            (functions,
             "What is the difference between *args and **kwargs?",
             .mcq,
             ["*args collects extra positional arguments as a tuple; **kwargs collects extra keyword arguments as a dict",
              "*args collects keyword arguments; **kwargs collects positional arguments",
              "Both collect positional arguments, **kwargs just names them",
              "*args is for integers only; **kwargs is for strings"],
             "*args collects extra positional arguments as a tuple; **kwargs collects extra keyword arguments as a dict",
             "*args lets a function accept any number of positional arguments, packaged as a tuple. **kwargs accepts any number of keyword arguments, packaged as a dict. They're typically used together as `def f(*args, **kwargs)` to create wrapper or pass-through functions.",
             2),

            (decorators,
             "What does a Python decorator do?",
             .explainThis, [],
             "A decorator wraps a function to add behavior before/after it runs, without modifying the original function's code.",
             "Decorators are higher-order functions: they take a function as input and return a modified function. `@my_decorator` above `def f()` is syntactic sugar for `f = my_decorator(f)`. Common uses: logging, timing, authentication checks, caching (`@functools.lru_cache`).",
             2),

            (decorators,
             "What will this generator function yield?\n\ndef countdown(n):\n    while n > 0:\n        yield n\n        n -= 1\n\nlist(countdown(3))",
             .codeOutput, [], "[3, 2, 1]",
             "A generator uses `yield` to produce values lazily — it pauses after each yield and resumes when next() is called. `list()` exhausts the generator. Generators are memory-efficient for large sequences since they don't build the full list in memory.",
             2),

            (comprehensions,
             "What is the output?\n\nresult = [x**2 for x in range(5) if x % 2 == 0]\nprint(result)",
             .codeOutput, [], "[0, 4, 16]",
             "List comprehension with filter: range(5) = [0,1,2,3,4]. Filter keeps even numbers: [0,2,4]. Square each: [0,4,16]. List comprehensions are more readable and often faster than equivalent for-loop + append patterns.",
             2),

            (classes,
             "What is the difference between @classmethod and @staticmethod in Python?",
             .mcq,
             ["They are identical",
              "@classmethod receives the class as first arg (cls); @staticmethod receives no implicit first arg",
              "@staticmethod receives the class; @classmethod receives nothing",
              "@classmethod only works with inheritance; @staticmethod works anywhere"],
             "@classmethod receives the class as first arg (cls); @staticmethod receives no implicit first arg",
             "@classmethod is bound to the class. `cls` lets you access/modify class state and is useful for alternative constructors. @staticmethod is just a regular function namespaced in the class — no `self` or `cls`. Use @staticmethod when the logic doesn't need class or instance data.",
             3),

            (classes,
             "True or False: In Python, `__init__` is the constructor that creates the object.",
             .trueFalse, ["True", "False"], "False",
             "False. `__new__` is the actual constructor — it creates and returns the new instance. `__init__` is the initializer — it receives the already-created instance and sets up its attributes. In 99% of cases you only need `__init__`, but the distinction matters when subclassing immutable types like `int` or `str`.",
             3),
        ]

        insertQuestions(questions, into: subject)
    }

    // MARK: - Machine Learning Questions

    private func addMLQuestions(to subject: Subject) {
        let biasVariance = subject.topics.first { $0.name == "Bias-Variance Tradeoff" }
        let metrics      = subject.topics.first { $0.name == "Cross-Validation & Metrics" }
        let regression   = subject.topics.first { $0.name == "Linear & Logistic Regression" }
        let trees        = subject.topics.first { $0.name == "Decision Trees & Random Forests" }

        let questions: [(Topic?, String, QuestionType, [String], String, String, Int)] = [
            (biasVariance,
             "A model performs perfectly on training data but poorly on test data. What is this called and what causes it?",
             .explainThis, [],
             "Overfitting. The model memorized training data including noise, so it fails to generalize. Caused by excessive model complexity relative to the dataset size.",
             "High variance = overfitting. The model learned the training distribution too well, including noise. Fixes: more training data, regularization (L1/L2), cross-validation, simpler model, dropout (for NNs), early stopping. The bias-variance tradeoff means reducing one often increases the other.",
             2),

            (biasVariance,
             "Which of these is a symptom of HIGH BIAS (underfitting)?",
             .mcq,
             ["High training accuracy, low test accuracy",
              "Low training accuracy AND low test accuracy",
              "The model has too many parameters",
              "The training loss keeps decreasing but validation loss increases"],
             "Low training accuracy AND low test accuracy",
             "High bias means the model is too simple to capture the underlying pattern. It performs poorly on BOTH train and test data. High variance (overfitting) shows high train accuracy but low test accuracy. The training/validation gap is your diagnostic: large gap = overfitting, both low = underfitting.",
             3),

            (metrics,
             "When would you prefer F1 score over accuracy as an evaluation metric?",
             .mcq,
             ["When the dataset is perfectly balanced",
              "When you have imbalanced classes (e.g., 95% negative, 5% positive)",
              "When you only care about true positives",
              "When the cost of false positives equals the cost of false negatives"],
             "When you have imbalanced classes (e.g., 95% negative, 5% positive)",
             "Accuracy is misleading on imbalanced datasets. A model predicting 'negative' every time gets 95% accuracy but is useless. F1 = 2*(Precision*Recall)/(Precision+Recall) balances both. Use F1 for imbalanced data, fraud detection, medical diagnosis. For asymmetric costs, consider precision or recall alone.",
             3),

            (metrics,
             "What does a ROC-AUC of 0.5 mean?",
             .mcq,
             ["The model is 50% accurate",
              "The model performs no better than random chance",
              "The model has 50% precision",
              "The model has equal false positive and true positive rates"],
             "The model performs no better than random chance",
             "ROC-AUC measures discrimination ability across all thresholds. AUC=1.0 = perfect. AUC=0.5 = random coin flip — the model has zero discriminative power. AUC<0.5 means the model is actually inverting labels (which you can fix by flipping predictions). Use ROC-AUC for binary classifiers with imbalanced data.",
             3),

            (regression,
             "What is the role of the sigmoid function in logistic regression?",
             .explainThis, [],
             "It maps the linear combination of features to a probability between 0 and 1. Output > 0.5 classifies as positive.",
             "Logistic regression outputs a linear score, then applies σ(z) = 1/(1+e^-z) to squash it to [0,1]. This gives a probability interpretation. The decision boundary is where σ(z) = 0.5 (i.e., z = 0). Unlike linear regression, this prevents predicting probabilities outside [0,1].",
             2),

            (trees,
             "True or False: Random Forest reduces overfitting compared to a single Decision Tree by using bagging and feature randomness.",
             .trueFalse, ["True", "False"], "True",
             "True. Bagging (Bootstrap Aggregating) trains each tree on a random sample of data with replacement. Feature randomness means each split considers only a random subset of features. These two techniques decorrelate the trees. The ensemble average/vote is more stable and generalizes better than any single deep tree.",
             2),

            (trees,
             "What is the key difference between Random Forest and Gradient Boosting?",
             .mcq,
             ["Random Forest uses regression trees; Gradient Boosting uses classification trees",
              "Random Forest builds trees in parallel and averages them; Gradient Boosting builds trees sequentially, each correcting the previous",
              "Gradient Boosting is always faster to train",
              "Random Forest requires more hyperparameter tuning"],
             "Random Forest builds trees in parallel and averages them; Gradient Boosting builds trees sequentially, each correcting the previous",
             "RF = parallel ensemble (bagging) — trees are independent, easy to parallelize, less prone to overfitting. GBM = sequential ensemble (boosting) — each new tree fits the residual errors of the previous. GBM (XGBoost, LightGBM) usually achieves higher accuracy but is slower and needs more tuning.",
             3),
        ]

        insertQuestions(questions, into: subject)
    }

    // MARK: - Deep Learning Questions

    private func addDLQuestions(to subject: Subject) {
        let fundamentals = subject.topics.first { $0.name == "Neural Network Fundamentals" }
        let backprop     = subject.topics.first { $0.name == "Backpropagation & Gradients" }
        let transformers = subject.topics.first { $0.name == "Transformers & Attention" }
        let regularize   = subject.topics.first { $0.name == "Regularization (Dropout, BN)" }

        let questions: [(Topic?, String, QuestionType, [String], String, String, Int)] = [
            (fundamentals,
             "Why do neural networks need activation functions?",
             .mcq,
             ["To normalize the input data",
              "To introduce non-linearity so the network can learn complex patterns",
              "To speed up training convergence",
              "To prevent gradient explosion"],
             "To introduce non-linearity so the network can learn complex patterns",
             "Without activation functions, stacking linear layers is equivalent to a single linear transformation — no matter how deep the network. Activation functions like ReLU, sigmoid, tanh introduce non-linearity, enabling the network to approximate any function (universal approximation theorem).",
             2),

            (backprop,
             "What is the vanishing gradient problem?",
             .explainThis, [],
             "Gradients shrink exponentially as they propagate backward through many layers, making early layers train very slowly or not at all.",
             "In deep networks, gradients are multiplied through each layer via the chain rule. Sigmoid/tanh saturate at extremes, producing near-zero gradients. After 10+ layers, the gradient reaching early layers approaches 0. Solutions: ReLU activation, batch normalization, residual connections (skip connections in ResNet), better weight initialization (He/Xavier).",
             3),

            (backprop,
             "True or False: A learning rate that is too high can cause the loss to diverge (increase instead of decrease).",
             .trueFalse, ["True", "False"], "True",
             "True. Gradient descent takes steps proportional to the learning rate. Too large a step overshoots the minimum, potentially making the loss worse. The loss oscillates or diverges. Too small a learning rate converges correctly but very slowly. Learning rate scheduling (decay, warm-up) or adaptive optimizers (Adam) help manage this.",
             2),

            (transformers,
             "In the Transformer architecture, what problem does the attention mechanism solve that RNNs struggled with?",
             .explainThis, [],
             "Long-range dependencies. RNNs process sequences step-by-step and struggle to retain information from distant positions. Attention allows every position to directly attend to every other position in O(1) steps.",
             "RNNs suffer from vanishing gradients over long sequences — information from early tokens gets diluted. Self-attention computes a weighted sum of ALL positions simultaneously, creating direct connections regardless of distance. This is why Transformers revolutionized NLP (BERT, GPT) and now vision (ViT).",
             4),

            (regularize,
             "What does Batch Normalization do and why does it help training?",
             .explainThis, [],
             "It normalizes layer inputs to have zero mean and unit variance, then applies learnable scale and shift. This stabilizes training, allows higher learning rates, and reduces sensitivity to initialization.",
             "Without BN, the distribution of each layer's input shifts as earlier layer weights update (internal covariate shift). BN re-centers and re-scales activations at each batch, keeping gradients in a healthy range. Side effect: mild regularization because of batch-level noise. Note: BN behaves differently at inference (uses running stats instead of batch stats).",
             3),

            (regularize,
             "How does Dropout work as a regularizer?",
             .mcq,
             ["It reduces the model size by permanently removing neurons",
              "During training it randomly zeros out neurons with probability p, forcing the network to learn redundant representations",
              "It clips gradients to prevent explosion",
              "It normalizes activations across the batch"],
             "During training it randomly zeros out neurons with probability p, forcing the network to learn redundant representations",
             "Dropout randomly disables neurons during each forward pass (typically p=0.5). This prevents co-adaptation — neurons can't rely on specific others. The network learns multiple independent sub-networks. At inference, dropout is disabled and activations are scaled by (1-p). Effect: acts like an ensemble of exponentially many smaller networks.",
             3),
        ]

        insertQuestions(questions, into: subject)
    }

    // MARK: - Data Analysis Questions

    private func addDataAnalysisQuestions(to subject: Subject) {
        let pandas  = subject.topics.first { $0.name == "Pandas DataFrames" }
        let numpy   = subject.topics.first { $0.name == "NumPy Arrays & Operations" }
        let eda     = subject.topics.first { $0.name == "Exploratory Data Analysis" }

        let questions: [(Topic?, String, QuestionType, [String], String, String, Int)] = [
            (pandas,
             "What is the difference between df.loc[] and df.iloc[]?",
             .mcq,
             ["loc uses integer positions; iloc uses labels",
              "loc uses labels (index names); iloc uses integer positions",
              "They are identical",
              "loc is for rows only; iloc is for columns only"],
             "loc uses labels (index names); iloc uses integer positions",
             "df.loc['a':'c'] selects rows by label. df.iloc[0:3] selects rows by integer position (0-indexed). When the index is integers, they look the same but differ on slicing: loc includes the endpoint, iloc excludes it (like Python slicing). Always prefer explicit loc/iloc over the deprecated df[idx] to avoid ambiguity.",
             2),

            (pandas,
             "What will df.groupby('category')['sales'].mean() return?",
             .explainThis, [],
             "A Series with one row per unique value in 'category', where each value is the mean of 'sales' for that group.",
             "groupby splits the DataFrame into groups by the 'category' column, then .mean() aggregates the 'sales' column for each group. The result index is the unique categories. Common follow-up: .agg({'sales': 'mean', 'qty': 'sum'}) to aggregate multiple columns with different functions.",
             2),

            (numpy,
             "What is broadcasting in NumPy?",
             .explainThis, [],
             "NumPy's ability to perform element-wise operations on arrays with different shapes by virtually expanding the smaller array to match, without copying data.",
             "Broadcasting rules: arrays are compared from trailing dimensions. Dimensions are compatible if equal OR one of them is 1. A (3,1) array added to a (1,4) array produces a (3,4) result. No actual data is copied — it's a view trick. This makes NumPy operations both concise and memory-efficient.",
             3),

            (numpy,
             "True or False: NumPy operations on arrays are generally faster than equivalent Python loops because they are implemented in C and can leverage vectorization.",
             .trueFalse, ["True", "False"], "True",
             "True. NumPy's operations are compiled C code operating on contiguous memory blocks. Python loops have interpreter overhead for each iteration. Vectorized operations also benefit from SIMD (Single Instruction Multiple Data) CPU instructions. For large arrays, NumPy can be 100x+ faster than pure Python loops.",
             1),

            (eda,
             "In EDA, what does a high correlation (r ≈ 0.95) between two features suggest, and why is it a concern for some models?",
             .explainThis, [],
             "The features carry nearly identical information (multicollinearity). For linear/logistic regression, this inflates coefficient variance and makes interpretation unreliable. Tree models are less affected.",
             "Multicollinearity doesn't hurt predictive power much but destroys coefficient interpretability. Variance Inflation Factor (VIF) quantifies it. Solutions: drop one feature, use PCA to combine them, or use regularization (Ridge handles it better than Lasso). For tree-based models, high correlation just means two features split on similar information — usually fine.",
             3),

            (eda,
             "Which of these best describes what df.describe() outputs?",
             .mcq,
             ["The first 5 rows of the DataFrame",
              "Count, mean, std, min, 25th/50th/75th percentiles, and max for each numeric column",
              "The data types of all columns",
              "The number of null values per column"],
             "Count, mean, std, min, 25th/50th/75th percentiles, and max for each numeric column",
             "df.describe() gives the 8-number summary for numeric columns. It's the first EDA step. Pair it with df.info() (types + nulls), df.isnull().sum() (missing counts), and df.value_counts() for categoricals. Use df.describe(include='all') to include non-numeric columns.",
             1),
        ]

        insertQuestions(questions, into: subject)
    }

    // MARK: - Statistics & Math Questions

    private func addStatsQuestions(to subject: Subject) {
        let probability = subject.topics.first { $0.name == "Probability Basics" }
        let hypothesis  = subject.topics.first { $0.name == "Hypothesis Testing" }
        let linalg      = subject.topics.first { $0.name == "Linear Algebra" }

        let questions: [(Topic?, String, QuestionType, [String], String, String, Int)] = [
            (probability,
             "What is the difference between P(A|B) and P(B|A)?",
             .explainThis, [],
             "P(A|B) is the probability of A given B has occurred. P(B|A) is the probability of B given A has occurred. They are generally NOT equal — confusing them is the base rate fallacy.",
             "This is the basis of Bayes' theorem: P(A|B) = P(B|A) * P(A) / P(B). Classic mistake: a medical test is 99% accurate (P(positive|disease)) but if the disease is rare (P(disease)=0.001), most positives are false positives (P(disease|positive) << 0.99). Always check the base rate.",
             3),

            (hypothesis,
             "If a hypothesis test returns p=0.03 with α=0.05, what is the correct interpretation?",
             .mcq,
             ["There is a 3% probability the null hypothesis is true",
              "There is a 97% probability the alternative hypothesis is true",
              "If the null hypothesis were true, we'd see results this extreme only 3% of the time by chance",
              "The effect size is 3%"],
             "If the null hypothesis were true, we'd see results this extreme only 3% of the time by chance",
             "p-value is NOT the probability that H0 is true. It's the probability of observing data at least as extreme as yours, assuming H0 is true. p=0.03 < α=0.05 → reject H0. This does NOT tell you H1 is 97% likely. It's a decision rule, not a measure of belief. Always pair with effect size (Cohen's d, R²).",
             4),

            (hypothesis,
             "True or False: Statistical significance (p < 0.05) guarantees practical significance.",
             .trueFalse, ["True", "False"], "False",
             "False. With a large enough sample, even a trivially small effect becomes statistically significant. A drug that reduces blood pressure by 0.1 mmHg could have p=0.001 with n=100,000 patients — statistically significant but clinically useless. Always report effect size alongside p-values. In ML, focus on business metrics, not just p-values.",
             2),

            (linalg,
             "What does the dot product of two vectors represent geometrically?",
             .explainThis, [],
             "The product of their magnitudes times the cosine of the angle between them. It measures how much one vector projects onto another.",
             "a·b = |a||b|cos(θ). If θ=0° (parallel), dot product = |a||b|. If θ=90° (orthogonal), dot product = 0. This is the foundation of cosine similarity in ML (used in embeddings, recommendation systems, NLP). Negative dot product means vectors point in opposite directions (θ > 90°).",
             3),

            (linalg,
             "In ML, what is the purpose of an eigenvector and eigenvalue?",
             .mcq,
             ["They measure the correlation between features",
              "An eigenvector is a direction unchanged by a matrix transformation; the eigenvalue is the scaling factor in that direction",
              "They define the gradient in optimization",
              "They are used only in neural networks"],
             "An eigenvector is a direction unchanged by a matrix transformation; the eigenvalue is the scaling factor in that direction",
             "For matrix A: Av = λv. v = eigenvector (direction), λ = eigenvalue (how much it stretches/shrinks). PCA finds eigenvectors of the covariance matrix — the directions of maximum variance. The eigenvalue tells you how much variance is captured. Sorting by eigenvalue descending gives you principal components in order of importance.",
             4),
        ]

        insertQuestions(questions, into: subject)
    }

    // MARK: - MLOps Questions

    private func addMLOpsQuestions(to subject: Subject) {
        let docker  = subject.topics.first { $0.name == "Docker & Containers" }
        let fastapi = subject.topics.first { $0.name == "REST APIs with FastAPI" }

        let questions: [(Topic?, String, QuestionType, [String], String, String, Int)] = [
            (docker,
             "What is the difference between a Docker image and a Docker container?",
             .mcq,
             ["They are the same thing",
              "An image is a read-only blueprint; a container is a running instance of that image",
              "A container is the blueprint; an image is the running instance",
              "Images run on Linux only; containers run on any OS"],
             "An image is a read-only blueprint; a container is a running instance of that image",
             "A Docker image is like a class — it defines the environment (OS, dependencies, code). A container is like an instance — it's the running process created from that image. You can run multiple containers from one image. Images are built from a Dockerfile and stored in registries (Docker Hub, ECR).",
             1),

            (docker,
             "True or False: Containerizing an ML model ensures it runs identically in development, staging, and production environments.",
             .trueFalse, ["True", "False"], "True",
             "True — this is Docker's core value proposition. 'Works on my machine' disappears because the container bundles the exact Python version, library versions, and system dependencies. The same image runs locally and on any cloud VM. Critical for ML where library versions (numpy, scikit-learn) directly affect model outputs.",
             1),

            (fastapi,
             "What HTTP status code should a successful model prediction endpoint return, and what should a bad request return?",
             .mcq,
             ["200 for success, 400 for bad input, 500 for server error",
              "201 for success, 404 for bad input",
              "200 for everything, differentiate via the response body",
              "202 for predictions since they're async"],
             "200 for success, 400 for bad input, 500 for server error",
             "200 OK = successful prediction. 422 Unprocessable Entity (FastAPI default) or 400 Bad Request = invalid input schema. 500 Internal Server Error = model crashed. 503 Service Unavailable = model loading. Proper status codes let API consumers handle errors programmatically without parsing response bodies.",
             2),
        ]

        insertQuestions(questions, into: subject)
    }

    // MARK: - SQL Questions

    private func addSQLQuestions(to subject: Subject) {
        let joins    = subject.topics.first { $0.name == "JOINs" }
        let aggs     = subject.topics.first { $0.name == "Aggregations & GROUP BY" }
        let windows  = subject.topics.first { $0.name == "Window Functions" }

        let questions: [(Topic?, String, QuestionType, [String], String, String, Int)] = [
            (joins,
             "What is the difference between LEFT JOIN and INNER JOIN?",
             .mcq,
             ["INNER JOIN returns all rows from both tables; LEFT JOIN returns only matching rows",
              "INNER JOIN returns only rows with matches in both tables; LEFT JOIN returns all rows from the left table plus matches from the right (NULL if no match)",
              "They are identical in output",
              "LEFT JOIN is faster than INNER JOIN"],
             "INNER JOIN returns only rows with matches in both tables; LEFT JOIN returns all rows from the left table plus matches from the right (NULL if no match)",
             "INNER JOIN = intersection. LEFT JOIN = all of left table + matched right rows (right side is NULL for non-matches). Use LEFT JOIN to 'keep all customers even if they have no orders'. RIGHT JOIN is the mirror. FULL OUTER JOIN keeps all rows from both sides. In data analysis, LEFT JOINs are most common when starting from a fact table.",
             2),

            (aggs,
             "What is the correct order of SQL clauses?\n\nSELECT, FROM, WHERE, GROUP BY, HAVING, ORDER BY",
             .trueFalse, ["True", "False"], "True",
             "True — this is the logical order. FROM (get data) → WHERE (filter rows) → GROUP BY (aggregate) → HAVING (filter groups) → SELECT (compute output) → ORDER BY (sort). HAVING filters AFTER aggregation (used with GROUP BY). WHERE filters BEFORE aggregation. Confusing them is a common SQL interview mistake.",
             2),

            (aggs,
             "What does this query do?\nSELECT department, COUNT(*), AVG(salary)\nFROM employees\nGROUP BY department\nHAVING COUNT(*) > 5",
             .explainThis, [],
             "For each department with more than 5 employees, it returns the department name, the number of employees, and the average salary.",
             "GROUP BY department groups all rows with the same department value. COUNT(*) counts employees per group, AVG(salary) averages salaries per group. HAVING COUNT(*) > 5 removes groups with 5 or fewer employees (you can't use WHERE here since WHERE runs before aggregation). Result: one row per qualifying department.",
             2),

            (windows,
             "What is the key difference between a window function and GROUP BY aggregation?",
             .mcq,
             ["Window functions are only available in PostgreSQL",
              "Window functions return a value for each row without collapsing rows; GROUP BY collapses rows into one per group",
              "GROUP BY is faster than window functions",
              "Window functions cannot compute sums or averages"],
             "Window functions return a value for each row without collapsing rows; GROUP BY collapses rows into one per group",
             "GROUP BY + COUNT returns one row per group. A window function like COUNT(*) OVER (PARTITION BY department) returns the department count on EVERY employee row — the original row count is preserved. This lets you do 'show each employee's salary vs their department average' in a single query, which is impossible with GROUP BY alone.",
             3),

            (windows,
             "What does ROW_NUMBER() OVER (PARTITION BY dept ORDER BY salary DESC) do?",
             .explainThis, [],
             "Assigns a sequential number (1, 2, 3...) to each row within each department, ordered by salary descending. The highest-paid employee in each department gets rank 1.",
             "PARTITION BY restarts numbering for each department (like GROUP BY but without collapsing rows). ORDER BY salary DESC ranks highest first. This pattern is used to find the top-N per group: wrap it in a CTE and filter WHERE row_num = 1 to get the highest-paid employee per department. Also useful for deduplication.",
             3),
        ]

        insertQuestions(questions, into: subject)
    }

    // MARK: - DSA Questions

    private func addDSAQuestions(to subject: Subject) {
        let bigO   = subject.topics.first { $0.name == "Big-O Analysis" }
        let dp     = subject.topics.first { $0.name == "Dynamic Programming" }
        let trees  = subject.topics.first { $0.name == "Trees & BST" }
        let graphs = subject.topics.first { $0.name == "Graphs & BFS/DFS" }

        let questions: [(Topic?, String, QuestionType, [String], String, String, Int)] = [
            (bigO,
             "What is the time complexity of looking up an element in a hash map (average case)?",
             .mcq,
             ["O(n)", "O(log n)", "O(1)", "O(n²)"],
             "O(1)",
             "Hash maps compute a hash of the key and jump directly to that bucket — constant time regardless of map size. Worst case is O(n) when all keys collide into one bucket, but a good hash function makes this extremely rare. This is why converting arrays to sets/dicts is a classic interview optimization.",
             1),

            (bigO,
             "True or False: An O(n log n) sorting algorithm is always faster than an O(n²) algorithm in practice.",
             .trueFalse, ["True", "False"], "False",
             "False. Big-O ignores constants and small inputs. Insertion sort (O(n²)) is often faster than Merge Sort (O(n log n)) for small arrays (n < 20) because it has lower constant factors and better cache behavior. Python's Timsort uses insertion sort for small segments. Big-O describes growth rate, not absolute speed.",
             3),

            (dp,
             "What are the two key properties a problem must have to be solvable with Dynamic Programming?",
             .explainThis, [],
             "1. Optimal substructure: optimal solution can be built from optimal solutions to subproblems. 2. Overlapping subproblems: the same subproblems are solved repeatedly.",
             "DP avoids redundant computation by storing subproblem results (memoization = top-down, tabulation = bottom-up). Without overlapping subproblems, recursion/divide-and-conquer suffice. Without optimal substructure, greedy or brute force. Classic DP: Fibonacci, Knapsack, Longest Common Subsequence, coin change.",
             4),

            (trees,
             "What is the time complexity of search, insert, and delete in a balanced BST vs an unbalanced one?",
             .mcq,
             ["Both are O(log n) for all operations",
              "Balanced: O(log n) for all; Unbalanced: O(n) worst case (degenerates to linked list)",
              "Balanced: O(1); Unbalanced: O(log n)",
              "They have identical time complexity"],
             "Balanced: O(log n) for all; Unbalanced: O(n) worst case (degenerates to linked list)",
             "A balanced BST (AVL, Red-Black Tree) guarantees height = O(log n). An unbalanced BST built from sorted input becomes a linked list — height = O(n), making all operations O(n). This is why interview problems use balanced BSTs or ask you to rebalance. Python's `sortedcontainers.SortedList` maintains sorted order in O(log n).",
             3),

            (graphs,
             "When would you use BFS over DFS for graph traversal?",
             .mcq,
             ["BFS uses less memory than DFS",
              "BFS finds the shortest path in an unweighted graph; DFS does not guarantee shortest path",
              "BFS works on directed graphs; DFS only on undirected",
              "DFS is always preferred for graph problems"],
             "BFS finds the shortest path in an unweighted graph; DFS does not guarantee shortest path",
             "BFS explores level by level using a queue — it finds the shortest path (fewest edges) first. DFS explores as deep as possible using a stack/recursion — useful for cycle detection, topological sort, connected components. For shortest paths with weights, use Dijkstra (non-negative) or Bellman-Ford (negative edges).",
             3),
        ]

        insertQuestions(questions, into: subject)
    }

    // MARK: - Question Insert Helper

    private func insertQuestions(
        _ questions: [(Topic?, String, QuestionType, [String], String, String, Int)],
        into subject: Subject
    ) {
        for (topic, questionText, type, options, answer, explanation, difficulty) in questions {
            let q = Question(
                topic: topic,
                questionText: questionText,
                questionType: type,
                options: options,
                correctAnswer: answer,
                explanation: explanation,
                difficulty: difficulty
            )
            context.insert(q)
            topic?.questions.append(q)
        }
    }

    // MARK: - Achievements

    private func seedAchievements() {
        for def in AchievementDefinitions.all {
            let achievement = Achievement(
                id: def.id,
                name: def.name,
                descriptionText: def.description,
                icon: def.icon,
                rarity: def.rarity,
                targetValue: def.targetValue
            )
            context.insert(achievement)
        }
    }

    // MARK: - Article Seeding

    private func seedArticles(subjects: [Subject]) {
        let dl = subjects.first { $0.name == "Deep Learning" }
        let ml = subjects.first { $0.name == "Machine Learning" }
        let py = subjects.first { $0.name == "Python" }

        if let topic = dl?.topics.first(where: { $0.name == "Neural Network Fundamentals" }), topic.article == nil {
            addArticle(to: topic, sections: neuralNetworkSections())
        }
        if let topic = dl?.topics.first(where: { $0.name == "Regularization (Dropout, BN)" }), topic.article == nil {
            addArticle(to: topic, sections: regularizationSections())
        }
        if let topic = ml?.topics.first(where: { $0.name == "Bias-Variance Tradeoff" }), topic.article == nil {
            addArticle(to: topic, sections: biasVarianceSections())
        }
        if let topic = py?.topics.first(where: { $0.name == "Decorators & Generators" }), topic.article == nil {
            addArticle(to: topic, sections: decoratorsSections())
        }

        try? context.save()
    }

    private func addArticle(to topic: Topic, sections: [(ArticleSectionType, String, String)]) {
        let article = TopicArticle()
        article.isAIGenerated = false
        context.insert(article)
        topic.article = article
        article.topic = topic

        for (i, (type, title, content)) in sections.enumerated() {
            let s = ArticleSection(order: i, type: type, title: title, content: content, confidence: .high)
            s.isVerified = true
            s.article    = article
            context.insert(s)
            article.sections.append(s)
        }
    }

    // MARK: - Neural Network Fundamentals

    private func neuralNetworkSections() -> [(ArticleSectionType, String, String)] {[
        (.summary, "What is a Neural Network?",
         "A neural network is a computational model loosely inspired by the brain. It consists of layers of interconnected nodes (neurons) that transform input data into predictions through a series of weighted, non-linear operations. The network **learns** by adjusting its weights to minimise a loss function via gradient descent."),

        (.concepts, "Key Concepts",
         """
         - **Neuron (Node)**: Computes a weighted sum of its inputs, adds a bias, then applies an activation function.
         - **Layer**: A group of neurons. Every network has an input layer, one or more hidden layers, and an output layer.
         - **Weight (W)**: A learnable parameter controlling how strongly one neuron influences the next.
         - **Bias (b)**: An extra learnable parameter that shifts the activation, allowing the network to fit data that doesn't pass through the origin.
         - **Activation Function**: Introduces non-linearity (ReLU, Sigmoid, Tanh, Softmax). Without it, stacking layers collapses to a single linear transformation.
         - **Loss Function**: Measures how wrong the network's predictions are (MSE for regression, cross-entropy for classification).
         - **Epoch**: One full pass over the entire training dataset.
         - **Batch Size**: Number of samples processed before updating weights. Smaller batches = noisier but faster updates.
         """),

        (.explanation, "How a Forward Pass Works",
         """
         For each layer l, the computation is:

         z = W · x + b
         a = activation(z)

         where **x** is the input, **W** is the weight matrix, **b** is the bias vector, and **a** is the output (activation) passed to the next layer.

         **Input layer** receives raw features (e.g., pixel values, token embeddings).

         **Hidden layers** progressively learn more abstract representations — early layers detect edges, later layers detect faces in a CNN, for example.

         **Output layer** produces the final prediction. For binary classification, a single sigmoid neuron outputs a probability. For multi-class, softmax produces a probability distribution over K classes.

         The entire forward pass is a chain of matrix multiplications and element-wise non-linearities. This is why GPUs excel — they parallelise matrix ops.
         """),

        (.code, "PyTorch — Minimal MLP",
         """
         ```python
         import torch
         import torch.nn as nn

         class MLP(nn.Module):
             def __init__(self, input_dim, hidden_dim, output_dim):
                 super().__init__()
                 self.net = nn.Sequential(
                     nn.Linear(input_dim, hidden_dim),
                     nn.ReLU(),
                     nn.Linear(hidden_dim, hidden_dim),
                     nn.ReLU(),
                     nn.Linear(hidden_dim, output_dim),
                 )

             def forward(self, x):
                 return self.net(x)

         # 10 features → 2 classes
         model = MLP(input_dim=10, hidden_dim=64, output_dim=2)
         criterion = nn.CrossEntropyLoss()
         optimizer = torch.optim.Adam(model.parameters(), lr=1e-3)

         # Training step
         x = torch.randn(32, 10)   # batch of 32 samples
         y = torch.randint(0, 2, (32,))
         loss = criterion(model(x), y)
         loss.backward()
         optimizer.step()
         ```
         """),

        (.mistakes, "Common Mistakes",
         """
         - **No activation functions between layers**: Stacking linear layers without activations gives you a single linear transformation regardless of depth — useless for non-linear problems.
         - **Wrong output activation**: Using sigmoid for multi-class classification instead of softmax, or forgetting to remove activation on the output when using `nn.CrossEntropyLoss` (which applies softmax internally in PyTorch).
         - **Not normalising inputs**: Raw pixel values [0–255] or large feature values cause unstable gradients. Always standardise: (x - mean) / std.
         - **Too many neurons, too little data**: A massive network on a small dataset memorises noise. Start small, then scale.
         - **Forgetting `optimizer.zero_grad()`**: PyTorch accumulates gradients by default. Omitting this corrupts updates after the first step.
         - **Evaluating without `model.eval()`**: Dropout and BatchNorm behave differently during inference. Always switch modes.
         """),

        (.reference, "Quick Reference",
         """
         - **ReLU**: `max(0, x)` — default hidden activation. Fast, no vanishing gradient for positive inputs.
         - **Sigmoid**: `1/(1+e^-x)` — binary output probability. Suffers vanishing gradients deep in network.
         - **Softmax**: `e^xi / Σe^xj` — multi-class output probabilities. Sum = 1.
         - **Xavier init**: Recommended for tanh layers — scales weights by `sqrt(1/fan_in)`.
         - **He init**: Recommended for ReLU layers — scales by `sqrt(2/fan_in)`.
         - **Universal approximation theorem**: A single hidden layer with enough neurons can approximate any continuous function — but deep networks learn it more efficiently.
         - **Parameters = W + b**: An (m → n) linear layer has m×n weights + n biases.
         """),
    ]}

    // MARK: - Regularization (Dropout, BN)

    private func regularizationSections() -> [(ArticleSectionType, String, String)] {[
        (.summary, "What is Regularization?",
         "Regularization is any technique that reduces a model's tendency to overfit training data. The two most important regularisation methods in deep learning are **Dropout** (randomly disabling neurons during training) and **Batch Normalisation** (normalising layer outputs to stabilise and accelerate training)."),

        (.concepts, "Key Concepts",
         """
         - **Overfitting**: Model memorises training noise — high train accuracy, poor test accuracy.
         - **Dropout**: During each forward pass, each neuron is independently zeroed out with probability p (typically 0.2–0.5). At inference, dropout is disabled and weights are scaled by (1-p).
         - **Batch Normalization (BN)**: Normalises the output of a layer to have zero mean and unit variance across the current mini-batch, then applies learnable scale (γ) and shift (β).
         - **L1/L2 regularization**: Add weight penalties to the loss — L2 (weight decay) is standard in Adam via `weight_decay` parameter.
         - **Early Stopping**: Stop training when validation loss stops improving to prevent memorising training set.
         - **Data Augmentation**: Artificially expand dataset by transforming inputs (crops, flips, noise).
         """),

        (.explanation, "How Dropout Works in Detail",
         """
         **Training phase**: For each neuron, sample a Bernoulli variable with P(keep) = 1-p. Multiply the neuron's output by this mask. This means each mini-batch sees a different "thinned" network.

         **Why it helps**: Forces the network to learn redundant representations — no single neuron can specialise in one feature because it might be absent next batch. This acts like training an **ensemble** of 2^n sub-networks simultaneously.

         **Inference phase**: Dropout is off. All neurons are active. But because training used only (1-p) of neurons on average, weights are multiplied by (1-p) to keep expected activations consistent — this is called **inverted dropout** (PyTorch's default).

         **Batch Norm** solves the **internal covariate shift** problem — as early layers update, their output distributions shift, making downstream layers chase a moving target. BN re-centres each layer's inputs every batch, allowing much higher learning rates and making training dramatically more stable.

         BN also acts as a regulariser because the normalisation adds noise from mini-batch statistics, reducing the need for Dropout in some architectures (e.g., ResNets use BN but minimal Dropout).
         """),

        (.code, "Dropout & BatchNorm in PyTorch",
         """
         ```python
         import torch.nn as nn

         class RegularizedNet(nn.Module):
             def __init__(self):
                 super().__init__()
                 self.net = nn.Sequential(
                     nn.Linear(784, 512),
                     nn.BatchNorm1d(512),   # BN before activation
                     nn.ReLU(),
                     nn.Dropout(p=0.4),     # drop 40% of neurons

                     nn.Linear(512, 256),
                     nn.BatchNorm1d(256),
                     nn.ReLU(),
                     nn.Dropout(p=0.3),

                     nn.Linear(256, 10),
                 )

             def forward(self, x):
                 return self.net(x)

         model = RegularizedNet()

         # CRITICAL: switch modes
         model.train()   # dropout ON, BN uses batch stats
         model.eval()    # dropout OFF, BN uses running stats
         ```
         """),

        (.mistakes, "Common Mistakes",
         """
         - **Forgetting `model.eval()`**: Dropout and BN both behave differently at inference. Not calling `eval()` means you get different (wrong) predictions every time you run inference.
         - **Dropout after BN in wrong order**: Standard order is Linear → BN → ReLU → Dropout. Applying BN after Dropout can cause issues because the batch statistics are computed on zeroed-out values.
         - **Too high dropout rate**: p=0.8 effectively destroys information. p=0.1-0.5 is the practical range. Use higher dropout for larger layers.
         - **BN with batch size 1**: BN is undefined for batch_size=1 (can't compute batch statistics). Use GroupNorm or LayerNorm instead for small batches or RNNs.
         - **Not setting `weight_decay`**: Forgetting L2 regularisation in the optimizer is a common omission. `Adam(params, lr=1e-3, weight_decay=1e-4)` is a sensible default.
         """),

        (.reference, "Quick Reference",
         """
         - **Dropout p**: Probability of zeroing a neuron. Typical: 0.2–0.5 for FC layers, 0.1–0.2 for conv layers.
         - **BN position**: Conv/Linear → BN → Activation (most common). Some papers use Post-Norm (after residual).
         - **L2 regularisation (weight decay)**: Adds λ·||W||² to loss. Equivalent to decaying weights each step.
         - **`model.train()` vs `model.eval()`**: MUST switch. `eval()` disables dropout, switches BN to use running mean/var.
         - **`torch.no_grad()`**: Disables gradient computation during inference — faster and less memory.
         - **Inverted dropout**: PyTorch scales activations by 1/(1-p) during training so inference weights are unchanged.
         """),
    ]}

    // MARK: - Bias-Variance Tradeoff

    private func biasVarianceSections() -> [(ArticleSectionType, String, String)] {[
        (.summary, "What is the Bias-Variance Tradeoff?",
         "Every model's prediction error can be decomposed into **Bias** (systematic error from wrong assumptions), **Variance** (sensitivity to fluctuations in training data), and irreducible noise. Reducing bias typically increases variance and vice versa — this is the tradeoff. The goal is to find a model complexity that minimises total error on unseen data."),

        (.concepts, "Key Concepts",
         """
         - **Bias**: Error from incorrect assumptions. High bias → model too simple → underfitting. E.g., fitting a line to quadratic data.
         - **Variance**: Error from sensitivity to training data. High variance → model too complex → overfitting. E.g., a depth-20 decision tree on 100 samples.
         - **Underfitting**: High bias, low variance. Model misses the signal. Fix: more complex model, more features, less regularisation.
         - **Overfitting**: Low bias, high variance. Model captures noise. Fix: regularisation, more data, simpler model, ensemble methods.
         - **Total Error** = Bias² + Variance + Irreducible Noise.
         - **Validation curve**: Plot train and val error vs model complexity. The "sweet spot" is where val error is minimum.
         - **Learning curve**: Plot train and val error vs dataset size. If they converge to a high error → high bias. If they have a large gap → high variance.
         """),

        (.explanation, "Finding the Sweet Spot",
         """
         **Bias-Variance decomposition** (for MSE):

         Expected Error = Bias(f̂)² + Var(f̂) + σ²

         where σ² is irreducible noise (inherent data randomness).

         **Diagnosing your model:**
         - Train acc = 98%, Val acc = 70% → **high variance** (overfitting). Add regularisation (L2, Dropout), get more data, reduce model complexity.
         - Train acc = 70%, Val acc = 68% → **high bias** (underfitting). Use a bigger model, add features, reduce regularisation, train longer.
         - Train acc = 95%, Val acc = 94% → good fit. Marginal gains from more data or tuning.

         **Ensemble methods reduce variance without increasing bias:**
         - **Bagging** (Random Forests): train many high-variance trees on bootstrap samples and average. Reduces variance dramatically.
         - **Boosting** (XGBoost): sequentially train weak learners to reduce bias. Can overfit — tune `n_estimators` + learning rate carefully.
         """),

        (.code, "Diagnosing with Learning Curves",
         """
         ```python
         from sklearn.model_selection import learning_curve
         from sklearn.tree import DecisionTreeClassifier
         import numpy as np, matplotlib.pyplot as plt

         model = DecisionTreeClassifier(max_depth=5)
         train_sizes, train_scores, val_scores = learning_curve(
             model, X, y,
             cv=5,
             scoring='accuracy',
             train_sizes=np.linspace(0.1, 1.0, 10)
         )

         train_mean = train_scores.mean(axis=1)
         val_mean   = val_scores.mean(axis=1)

         plt.plot(train_sizes, train_mean, label='Train accuracy')
         plt.plot(train_sizes, val_mean,   label='Val accuracy')
         plt.xlabel('Training samples')
         plt.ylabel('Accuracy')
         plt.legend()

         # Large gap between lines → high variance (overfit)
         # Both lines low and converging → high bias (underfit)
         ```
         """),

        (.mistakes, "Common Mistakes",
         """
         - **Evaluating only on training data**: High train accuracy tells you nothing about generalisation. Always report val/test performance.
         - **Treating all error as reducible**: Some error is irreducible noise in the data. Don't expect 100% accuracy on noisy data.
         - **Adding features to fix high variance**: More features without regularisation increases variance. Fix variance with regularisation or data, not features.
         - **Using test set to tune hyperparameters**: You're leaking test information. The test set should be untouched until final evaluation — use a val set or CV for tuning.
         - **Ignoring the gap between train and val**: A model with 99% train, 60% val is useless. The val error is your real-world proxy.
         """),

        (.reference, "Quick Reference",
         """
         - **High bias signals**: Train ≈ Val error, both high. Model too simple.
         - **High variance signals**: Train error << Val error. Model too complex.
         - **Fix high bias**: Bigger model, more features, less regularisation, more epochs.
         - **Fix high variance**: More data, regularisation (L2/Dropout), fewer features, early stopping, ensemble.
         - **Random Forest**: Reduces variance (bagging of high-variance trees).
         - **Boosting**: Reduces bias (ensemble of weak/high-bias learners).
         - **k-fold CV**: More reliable estimate of generalisation than a single train/val split.
         """),
    ]}

    // MARK: - Decorators & Generators

    private func decoratorsSections() -> [(ArticleSectionType, String, String)] {[
        (.summary, "Decorators & Generators",
         "**Decorators** are functions that wrap other functions to add behaviour without modifying their source code. **Generators** are functions that yield values one at a time using `yield`, enabling lazy evaluation of potentially infinite sequences. Both are core Python idioms used extensively in frameworks like Flask, FastAPI, and PyTorch."),

        (.concepts, "Key Concepts",
         """
         - **Higher-order function**: A function that takes or returns another function. Decorators are built on this.
         - **`@` syntax**: `@decorator` above a function is syntactic sugar for `f = decorator(f)`.
         - **`functools.wraps`**: Preserves the wrapped function's `__name__`, `__doc__` etc. — always use it inside decorators.
         - **`yield`**: Pauses function execution and returns a value. Resumes on next `next()` call.
         - **Generator object**: Created when you call a generator function. Is an iterator — can only be iterated once.
         - **`yield from`**: Delegates to another iterable/generator, flattening nested generators.
         - **Lazy evaluation**: Generators compute values on demand — O(1) memory regardless of sequence length.
         """),

        (.explanation, "How Decorators Work",
         """
         A decorator is just a callable that takes a function and returns a (usually modified) function.

         **Three steps happening under the hood:**
         1. Python defines `original_function`.
         2. Python calls `decorator(original_function)` and stores the result back as `original_function`.
         3. When you call `original_function(args)`, you're actually calling the wrapper.

         **Decorator with arguments** requires an extra layer — a decorator factory that returns the actual decorator.

         **Generators — how `yield` works:**
         When Python encounters a `yield`, it freezes the function's local state (variables, instruction pointer) and returns the value. The next `next()` call resumes from exactly that point. This makes generators memory-efficient for large datasets — you can iterate a 10GB file line-by-line using a generator without loading it into RAM.

         **Common real-world uses:**
         - `@staticmethod`, `@classmethod`, `@property` — built-in decorators
         - `@app.route('/path')` — Flask/FastAPI routing
         - `@torch.no_grad()` — PyTorch gradient context
         - Generators: `range()`, file iteration, data pipelines
         """),

        (.code, "Decorator & Generator Examples",
         """
         ```python
         import functools, time

         # --- Decorator ---
         def timer(func):
             @functools.wraps(func)   # preserve metadata
             def wrapper(*args, **kwargs):
                 start = time.perf_counter()
                 result = func(*args, **kwargs)
                 elapsed = time.perf_counter() - start
                 print(f"{func.__name__} took {elapsed:.4f}s")
                 return result
             return wrapper

         @timer
         def slow_function(n):
             return sum(range(n))

         slow_function(10_000_000)  # prints execution time

         # --- Decorator with arguments ---
         def retry(times=3):
             def decorator(func):
                 @functools.wraps(func)
                 def wrapper(*args, **kwargs):
                     for attempt in range(times):
                         try:
                             return func(*args, **kwargs)
                         except Exception as e:
                             if attempt == times - 1:
                                 raise
                     return wrapper
                 return decorator

         @retry(times=5)
         def unstable_api_call(): ...

         # --- Generator ---
         def read_large_file(path):
             with open(path) as f:
                 for line in f:
                     yield line.strip()  # one line at a time, O(1) memory

         # Generator expression (lazy list comprehension)
         squares = (x**2 for x in range(10**9))  # no memory cost until iteration
         print(next(squares))  # 0
         print(next(squares))  # 1
         ```
         """),

        (.mistakes, "Common Mistakes",
         """
         - **Forgetting `functools.wraps`**: Without it, the wrapped function loses its name and docstring — `help(func)` and stack traces show 'wrapper' everywhere.
         - **Calling a generator function twice expecting a reset**: Generators are exhausted after one iteration. Call the function again to get a fresh generator.
         - **Using `return` with a value in a generator**: In Python 3, `return value` in a generator raises `StopIteration(value)` — it doesn't yield the value. Use `yield` to produce values.
         - **Decorator with parentheses when not needed**: `@timer` vs `@timer()`. If `timer` is a plain decorator, use `@timer`. If it's a factory (takes config args), use `@timer()`. Mixing these causes a TypeError.
         - **Mutating state in a decorator that's applied to a class method**: `self` is the first arg — make sure `*args, **kwargs` capture it correctly.
         """),

        (.reference, "Quick Reference",
         """
         - **`@functools.wraps(func)`**: Always use inside decorators to preserve metadata.
         - **`@property`**: Turns a method into a read-only attribute: `obj.value` calls the method.
         - **`@staticmethod`**: Method with no `self`/`cls` — behaves like a plain function in the class namespace.
         - **`@classmethod`**: Receives the class (`cls`) as first arg — used for alternative constructors.
         - **`yield` vs `return`**: `yield` pauses + produces; `return` terminates (raises StopIteration in generators).
         - **`list(gen)`**: Materialise a generator into a list — use when you need random access or multiple passes.
         - **`itertools`**: `chain`, `islice`, `cycle`, `product` — powerful tools to compose generators.
         """),
    ]}
}
