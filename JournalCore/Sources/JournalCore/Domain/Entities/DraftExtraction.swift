/// What the model fills in. Deliberately excludes `sessionDate` and `classType` —
/// the user already supplied those when starting the entry, so asking the model to
/// infer them would just invite a wrong guess the user has no reason to make.
public struct DraftExtraction: Codable, Equatable, Sendable {
    public var title: String?
    public var techniques: [Technique]
    public var coachDetails: String?
    public var whatWorked: String?
    public var whatWentWrong: String?
    public var openQuestions: [String]
    public var durationMinutes: Int?

    public init(
        title: String? = nil,
        techniques: [Technique] = [],
        coachDetails: String? = nil,
        whatWorked: String? = nil,
        whatWentWrong: String? = nil,
        openQuestions: [String] = [],
        durationMinutes: Int? = nil
    ) {
        self.title = title
        self.techniques = techniques
        self.coachDetails = coachDetails
        self.whatWorked = whatWorked
        self.whatWentWrong = whatWentWrong
        self.openQuestions = openQuestions
        self.durationMinutes = durationMinutes
    }
}
