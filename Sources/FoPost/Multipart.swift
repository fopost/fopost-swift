import Foundation

/// A multipart/form-data body, buffered whole so a retry can replay it.
struct MultipartForm {
  let boundary: String
  private var body = Data()

  init(boundary: String = "fopost-\(UUID().uuidString)") {
    self.boundary = boundary
  }

  var contentType: String { "multipart/form-data; boundary=\(boundary)" }

  mutating func addField(_ name: String, _ value: String?) {
    guard let value, !value.isEmpty else { return }
    append("--\(boundary)\r\n")
    append("Content-Disposition: form-data; name=\"\(escape(name))\"\r\n\r\n")
    append("\(value)\r\n")
  }

  mutating func addFile(field: String, filename: String, mimeType: String? = nil, data: Data) {
    let type = mimeType ?? MultipartForm.mimeType(for: filename)
    append("--\(boundary)\r\n")
    append(
      "Content-Disposition: form-data; name=\"\(escape(field))\"; filename=\"\(escape(filename))\"\r\n"
    )
    append("Content-Type: \(type)\r\n\r\n")
    body.append(data)
    append("\r\n")
  }

  /// Closes the form and returns the bytes to send.
  func encoded() -> Data {
    var finished = body
    finished.append(Data("--\(boundary)--\r\n".utf8))
    return finished
  }

  private mutating func append(_ string: String) {
    body.append(Data(string.utf8))
  }

  private func escape(_ value: String) -> String {
    value.replacingOccurrences(of: "\"", with: "%22")
      .replacingOccurrences(of: "\r", with: "")
      .replacingOccurrences(of: "\n", with: "")
  }

  static func mimeType(for filename: String) -> String {
    switch (filename as NSString).pathExtension.lowercased() {
    case "jpg", "jpeg": return "image/jpeg"
    case "png": return "image/png"
    case "gif": return "image/gif"
    case "webp": return "image/webp"
    case "mp4": return "video/mp4"
    case "mov": return "video/quicktime"
    case "webm": return "video/webm"
    case "pdf": return "application/pdf"
    case "csv": return "text/csv"
    case "tsv": return "text/tab-separated-values"
    case "txt": return "text/plain"
    default: return "application/octet-stream"
    }
  }
}
