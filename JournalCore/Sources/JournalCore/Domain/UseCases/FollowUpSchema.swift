struct ProposedFollowUpQuestions: Codable, Equatable, Sendable {
    var questions: [String]
}

/// The forced tool call behind `FollowUpQuestionsUseCase`.
enum FollowUpSchema {
    static let toolName = "propose_follow_up_questions"

    static let tool = ToolDefinition(
        name: toolName,
        description: "Record up to three follow-up questions worth asking before structuring "
            + "this training note — or none, if the note is already clear.",
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([
                "questions": .object([
                    "type": .string("array"),
                    "description": .string("Zero to three short, specific questions."),
                    "items": .object(["type": .string("string")]),
                ])
            ]),
            "required": .array([.string("questions")]),
        ])
    )
}
