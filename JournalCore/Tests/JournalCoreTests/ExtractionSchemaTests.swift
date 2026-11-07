import Foundation
import Testing
@testable import JournalCore

@Suite
struct ExtractionSchemaTests {
    private func decode(_ json: String) throws -> DraftExtraction {
        try JSONDecoder().decode(DraftExtraction.self, from: Data(json.utf8))
    }

    @Test
    func decodesFullyPopulatedDraft() throws {
        let json = """
        {
            "title": "Butterfly sweep: elevate with the hook",
            "techniques": [
                {"name": "Butterfly sweep", "position": "Butterfly guard", "type": "sweep"}
            ],
            "coachDetails": "Lift with the hook, not the arms.",
            "whatWorked": "Got the angle early.",
            "whatWentWrong": "Head on the wrong side.",
            "openQuestions": ["Which grip for the sweep?"],
            "durationMinutes": 90
        }
        """

        let draft = try decode(json)
        #expect(draft.title == "Butterfly sweep: elevate with the hook")
        #expect(draft.techniques == [Technique(name: "Butterfly sweep", position: "Butterfly guard", type: .sweep)])
        #expect(draft.coachDetails == "Lift with the hook, not the arms.")
        #expect(draft.openQuestions == ["Which grip for the sweep?"])
        #expect(draft.durationMinutes == 90)
    }

    @Test
    func decodesWithOptionalFieldsAbsent() throws {
        let json = """
        {"title": "Open mat", "techniques": [], "openQuestions": []}
        """

        let draft = try decode(json)
        #expect(draft.title == "Open mat")
        #expect(draft.techniques.isEmpty)
        #expect(draft.coachDetails == nil)
        #expect(draft.durationMinutes == nil)
    }

    @Test
    func unrecognizedTechniqueTypeFallsBackToOther() throws {
        let json = """
        {
            "title": "No-gi rounds",
            "techniques": [{"name": "Berimbolo", "type": "guard_attack_thing"}],
            "openQuestions": []
        }
        """

        let draft = try decode(json)
        #expect(draft.techniques.first?.type == .other)
    }

    @Test
    func malformedJSONThrowsDecodingError() {
        let json = "{\"title\": \"missing closing brace\""
        #expect(throws: (any Error).self) {
            try decode(json)
        }
    }

    @Test
    func missingRequiredFieldThrowsDecodingError() {
        let json = """
        {"title": "No techniques key at all"}
        """
        #expect(throws: (any Error).self) {
            try decode(json)
        }
    }
}
