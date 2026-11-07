import Foundation

/// Thin Codable mirror of the Claude Messages API request/response shapes actually
/// used by this app. Kept generic (not extraction-specific) so every agent — Debrief,
/// Recall, Weekly reviewer, Planner — can be built on the same `LLMClient`.

public enum MessageRole: String, Codable, Sendable {
    case user
    case assistant
}

/// A single piece of message content. Request-side, this app only ever sends `.text`.
/// Response-side, Claude may return `.text` (e.g. reasoning before a tool call) and
/// `.toolUse` (the forced tool call's arguments).
public enum ContentBlock: Sendable, Equatable {
    case text(String)
    case toolUse(id: String, name: String, input: JSONValue)
}

extension ContentBlock: Codable {
    private enum CodingKeys: String, CodingKey {
        case type, text, id, name, input
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "text":
            self = .text(try container.decode(String.self, forKey: .text))
        case "tool_use":
            self = .toolUse(
                id: try container.decode(String.self, forKey: .id),
                name: try container.decode(String.self, forKey: .name),
                input: try container.decode(JSONValue.self, forKey: .input)
            )
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type, in: container, debugDescription: "Unknown content block type: \(type)"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let text):
            try container.encode("text", forKey: .type)
            try container.encode(text, forKey: .text)
        case .toolUse(let id, let name, let input):
            try container.encode("tool_use", forKey: .type)
            try container.encode(id, forKey: .id)
            try container.encode(name, forKey: .name)
            try container.encode(input, forKey: .input)
        }
    }
}

public struct MessageParam: Codable, Sendable, Equatable {
    public var role: MessageRole
    public var content: [ContentBlock]

    public init(role: MessageRole, content: [ContentBlock]) {
        self.role = role
        self.content = content
    }

    public static func user(_ text: String) -> MessageParam {
        MessageParam(role: .user, content: [.text(text)])
    }
}

public struct ToolDefinition: Encodable, Sendable, Equatable {
    public var name: String
    public var description: String
    public var inputSchema: JSONValue

    private enum CodingKeys: String, CodingKey {
        case name, description
        case inputSchema = "input_schema"
    }

    public init(name: String, description: String, inputSchema: JSONValue) {
        self.name = name
        self.description = description
        self.inputSchema = inputSchema
    }
}

/// Forces Claude to call a specific tool rather than choosing freely or replying with
/// plain text — guarantees the response shape for structured extraction.
public struct ToolChoice: Encodable, Sendable, Equatable {
    public var type: String
    public var name: String?

    public static func tool(named name: String) -> ToolChoice {
        ToolChoice(type: "tool", name: name)
    }
}

public struct MessageRequest: Encodable, Sendable {
    public var model: String
    public var maxTokens: Int
    public var system: String?
    public var messages: [MessageParam]
    public var tools: [ToolDefinition]
    public var toolChoice: ToolChoice?

    private enum CodingKeys: String, CodingKey {
        case model, system, messages, tools
        case maxTokens = "max_tokens"
        case toolChoice = "tool_choice"
    }

    public init(
        model: String,
        maxTokens: Int,
        system: String? = nil,
        messages: [MessageParam],
        tools: [ToolDefinition] = [],
        toolChoice: ToolChoice? = nil
    ) {
        self.model = model
        self.maxTokens = maxTokens
        self.system = system
        self.messages = messages
        self.tools = tools
        self.toolChoice = toolChoice
    }
}

public struct Usage: Codable, Sendable, Equatable {
    public var inputTokens: Int
    public var outputTokens: Int

    private enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
    }
}

public struct MessageResponse: Decodable, Sendable, Equatable {
    public var id: String
    public var model: String
    public var role: MessageRole
    public var content: [ContentBlock]
    public var stopReason: String?
    public var usage: Usage?

    private enum CodingKeys: String, CodingKey {
        case id, model, role, content, usage
        case stopReason = "stop_reason"
    }

    /// The input of the first `tool_use` block named `name`, if any. Extraction code
    /// uses this to pull its forced tool call's arguments out of the response.
    public func toolUseInput(named name: String) -> JSONValue? {
        for block in content {
            if case .toolUse(_, let blockName, let input) = block, blockName == name {
                return input
            }
        }
        return nil
    }
}
