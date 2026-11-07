/// The one place a Claude model ID is hard-coded. Every call site reads it from
/// here (or from a user override, once Settings exposes one) rather than embedding
/// a model string of its own.
public enum AppConfig {
    public static let defaultExtractionModel = "claude-haiku-4-5-20251001"
}
