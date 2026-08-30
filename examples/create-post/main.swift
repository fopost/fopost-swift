import FoPost
import Foundation

// Creates a post and publishes it. Run it with FOPOST_API_KEY set:
//
//     FOPOST_API_KEY=fp_... swift run fopost-example

@main
struct CreatePostExample {
  static func main() async {
    do {
      try await run()
    } catch let error as FoPostError {
      FileHandle.standardError.write(Data("\(error.localizedDescription)\n".utf8))
      if let upgradeURL = error.upgradeURL {
        FileHandle.standardError.write(Data("Upgrade at \(upgradeURL)\n".utf8))
      }
      exit(1)
    } catch {
      FileHandle.standardError.write(Data("\(error)\n".utf8))
      exit(1)
    }
  }

  static func run() async throws {
    let client = try FoPostClient()

    guard let workspace = try await client.workspaces.list().first else {
      print("No workspaces yet — create one at https://app.fopost.com first.")
      return
    }
    print("Workspace: \(workspace.name ?? workspace.id)")

    let accounts = try await client.accounts.list(workspaceID: workspace.id)
    guard !accounts.isEmpty else {
      print("No connected accounts yet — connect one at https://app.fopost.com first.")
      return
    }
    for account in accounts {
      print("  \(account.platform?.rawValue ?? "?") @\(account.username ?? "?")")
    }

    let post = try await client.posts.create(
      CreatePostRequest(
        workspaceID: workspace.id,
        accounts: accounts.map(\.id),
        content: .text("Hello from the FoPost Swift SDK.")))
    print("Created post \(post.id)")

    // Preflight is advisory — it reports blockers without publishing.
    let preflight = try await client.posts.preflight(post.id)
    for account in preflight.accounts ?? [] where !(account.ready ?? true) {
      print(
        "  not ready: @\(account.username ?? "?") \((account.issues ?? []).joined(separator: ", "))"
      )
    }

    let result = try await client.posts.publish(post.id)
    print("Publish queued, post status \(result.postStatus?.rawValue ?? "unknown")")
    for delivery in result.deliveries ?? [] {
      print("  \(delivery.accountId ?? "?") → \(delivery.status?.rawValue ?? "?")")
    }
  }
}
