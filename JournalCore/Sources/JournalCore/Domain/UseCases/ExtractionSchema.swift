/// The forced tool call that turns a raw note into a `DraftExtraction`. One tool,
/// one schema, kept next to the type it decodes into so the two can't drift apart.
///
/// Built from small named pieces rather than one nested literal: a dictionary
/// literal this deep is both unreadable and slow for the type checker to infer.
public enum ExtractionSchema {
    public static let toolName = "extract_training_entry"

    private static func stringSchema(_ description: String? = nil) -> JSONValue {
        var fields: [String: JSONValue] = ["type": .string("string")]
        if let description { fields["description"] = .string(description) }
        return .object(fields)
    }

    private static func arraySchema(of items: JSONValue, description: String? = nil) -> JSONValue {
        var fields: [String: JSONValue] = ["type": .string("array"), "items": items]
        if let description { fields["description"] = .string(description) }
        return .object(fields)
    }

    private static let techniqueTypeSchema = JSONValue.object([
        "type": .string("string"),
        "enum": .array(TechniqueType.allCases.map { .string($0.rawValue) }),
    ])

    private static let techniqueItemSchema = JSONValue.object([
        "type": .string("object"),
        "properties": .object([
            "name": stringSchema(),
            "position": stringSchema("The position this technique is from or leads to, if mentioned."),
            "type": techniqueTypeSchema,
        ]),
        "required": .array([.string("name"), .string("type")]),
    ])

    private static let propertiesSchema = JSONValue.object([
        "title": stringSchema("A short, specific title for this session, e.g. the main technique worked on."),
        "techniques": arraySchema(
            of: techniqueItemSchema,
            description: "Every technique mentioned, in the order they come up."
        ),
        "coachDetails": stringSchema("Specific instruction or correction attributed to the coach, if any."),
        "whatWorked": stringSchema(),
        "whatWentWrong": stringSchema(),
        "openQuestions": arraySchema(
            of: stringSchema(),
            description: "Things the note leaves unclear that are worth asking about later."
        ),
        "durationMinutes": stringSchema("Session length in minutes, only if explicitly stated."),
    ])

    public static let tool = ToolDefinition(
        name: toolName,
        description: "Record the structured details of a BJJ training note: a short title, "
            + "the techniques covered, what the coach said, what worked, what went wrong, "
            + "and anything left unclear.",
        inputSchema: .object([
            "type": .string("object"),
            "properties": propertiesSchema,
            "required": .array([.string("title"), .string("techniques"), .string("openQuestions")]),
        ])
    )
}
