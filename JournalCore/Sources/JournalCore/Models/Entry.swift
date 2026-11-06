import Foundation

public enum ClassType: String, Codable, CaseIterable, Hashable, Sendable {
    case gi
    case noGi = "no_gi"
    case openMat = "open_mat"
    case other
}

public enum EntryStatus: String, Codable, Hashable, Sendable {
    case pending
    case structured
}

public enum TechniqueType: String, Codable, CaseIterable, Hashable, Sendable {
    case sweep
    case submission
    case escape
    case pass
    case takedown
    case guardRetention = "guard_retention"
    case other

    /// BJJ vocabulary drifts ("knee cut" vs "knee slice") and the model may emit a
    /// type we haven't enumerated yet. Falling back to `.other` keeps the whole
    /// extraction from failing over one unrecognized category, rather than throwing.
    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = TechniqueType(rawValue: raw) ?? .other
    }
}

public struct Technique: Codable, Equatable, Sendable {
    public var name: String
    public var position: String?
    public var type: TechniqueType

    public init(name: String, position: String? = nil, type: TechniqueType) {
        self.name = name
        self.position = position
        self.type = type
    }
}

/// A single training session: starts as a raw note and becomes `structured` once the
/// user approves an extracted draft. `rawText` is never discarded, so extraction can
/// be rerun later against an improved prompt or schema.
public struct Entry: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var sessionDate: Date
    public var classType: ClassType
    public var rawText: String
    public var status: EntryStatus
    public var title: String?
    public var techniques: [Technique]
    public var coachDetails: String?
    public var whatWorked: String?
    public var whatWentWrong: String?
    public var openQuestions: [String]
    public var durationMinutes: Int?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        sessionDate: Date,
        classType: ClassType,
        rawText: String,
        status: EntryStatus = .pending,
        title: String? = nil,
        techniques: [Technique] = [],
        coachDetails: String? = nil,
        whatWorked: String? = nil,
        whatWentWrong: String? = nil,
        openQuestions: [String] = [],
        durationMinutes: Int? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.sessionDate = sessionDate
        self.classType = classType
        self.rawText = rawText
        self.status = status
        self.title = title
        self.techniques = techniques
        self.coachDetails = coachDetails
        self.whatWorked = whatWorked
        self.whatWentWrong = whatWentWrong
        self.openQuestions = openQuestions
        self.durationMinutes = durationMinutes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
