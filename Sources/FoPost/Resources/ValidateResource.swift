import Foundation

/// Checks content, text length, and media against platform rules without
/// creating anything. Every call needs the `posts` scope.
public struct ValidateResource: Resource {
  let transport: Transport

  /// Checks a post's text and media against each platform.
  public func post(_ body: ValidatePostRequest) async throws -> ValidatePostResult {
    try await httpPost("/validate/post", body: body, as: ValidatePostResult.self)
  }

  /// Measures text against each platform's limit.
  public func length(_ body: ValidateLengthRequest) async throws -> ValidateLengthResult {
    try await httpPost("/validate/length", body: body, as: ValidateLengthResult.self)
  }

  /// Fetches a public file URL and reports whether it can be attached.
  public func media(_ body: ValidateMediaRequest) async throws -> ValidateMediaResult {
    try await httpPost("/validate/media", body: body, as: ValidateMediaResult.self)
  }
}
