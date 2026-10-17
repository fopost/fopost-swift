import Foundation

/// Checks content, text length, media, and a subreddit against platform rules
/// without creating anything. Every call needs the `posts` scope.
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

  /// Whether the subreddit `name` exists and takes a post from `accountId`. The
  /// check runs with that account's own token, so the account has to be one the
  /// key can see. A private, banned, or missing subreddit still answers 200,
  /// with ``ValidateSubredditResult/exists`` false.
  public func subreddit(accountId: String, name: String) async throws -> ValidateSubredditResult {
    try await httpGet(
      "/validate/subreddit",
      query: Query(["account_id": accountId, "name": name]),
      as: ValidateSubredditResult.self)
  }
}
