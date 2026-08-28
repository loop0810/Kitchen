import CryptoKit
import Foundation

/// Share Extension 与主 App 之间的文件交接协议。
///
/// 原生扩展只负责把系统临时引用复制到 App Group；主 App 接管成功前不会删除这些文件。
final class KitchenNotesShareStaging {
  static let shared = KitchenNotesShareStaging()

  static let manifestVersion = 1
  static let maxFileBytes: Int64 = 20 * 1024 * 1024
  static let maxShareBytes: Int64 = 80 * 1024 * 1024

  private let fileManager = FileManager.default
  private let encoder: JSONEncoder
  private let decoder: JSONDecoder

  private init() {
    encoder = JSONEncoder()
    decoder = JSONDecoder()
  }

  var groupIdentifier: String {
    (Bundle.main.object(forInfoDictionaryKey: "KitchenNotesAppGroup") as? String)
      ?? "group.com.loop.kitchenNotes.shared"
  }

  var stagingRoot: URL? {
    guard let container = fileManager.containerURL(
      forSecurityApplicationGroupIdentifier: groupIdentifier
    ) else {
      return nil
    }
    return container.appendingPathComponent("import_share_staging", isDirectory: true)
  }

  func listReadyManifests() -> [[String: Any]] {
    // 主 App 只接收 ready 且经过路径、大小、SHA-256 校验的清单。这里的校验把
    // 原生扩展和 Flutter 之间的文件交接收束成可信输入，避免把任意路径交给 OCR。
    guard let root = stagingRoot,
          let directories = try? fileManager.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
          ) else {
      return []
    }

    return directories.compactMap { directory in
      guard let manifest = readManifest(in: directory),
            manifest.status == "ready",
            let payload = payload(from: manifest, directory: directory)
      else { return nil }
      return payload
    }
  }

  func acknowledge(id: String) throws {
    // 只有主 App 已经把清单转换成 ImportTask 后才会调用 acknowledge；在此之前
    // 保留目录是崩溃恢复机制的一部分，而不是普通的临时文件清理。
    guard isSafeIdentifier(id), let root = stagingRoot else { return }
    let directory = root.appendingPathComponent(id, isDirectory: true)
    guard directory.path.hasPrefix(root.path + "/") else { return }
    if fileManager.fileExists(atPath: directory.path) {
      try fileManager.removeItem(at: directory)
    }
  }

  /// 只清理长期失败的扩展暂存；ready 内容必须等主 App 成功接管后才能删除。
  func purgeExpiredFailedShares(olderThan age: TimeInterval) {
    guard let root = stagingRoot,
          let directories = try? fileManager.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
          )
    else { return }
    let cutoff = Date().addingTimeInterval(-age)
    for directory in directories {
      guard let manifest = readManifest(in: directory),
            manifest.status == "failed"
      else { continue }
      let date = Date(
        timeIntervalSince1970: TimeInterval(manifest.createdAtEpochMilliseconds) / 1000
      )
      guard date < cutoff else { continue }
      try? fileManager.removeItem(at: directory)
    }
  }

  func createShareDirectory(id: String) throws -> URL {
    guard isSafeIdentifier(id), let root = stagingRoot else {
      throw ShareStagingError.unavailable
    }
    try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
    let directory = root.appendingPathComponent(id, isDirectory: true)
    try fileManager.createDirectory(at: directory, withIntermediateDirectories: false)
    return directory
  }

  func writeReadyManifest(_ manifest: ShareManifest, in directory: URL) throws {
    let temporary = directory.appendingPathComponent("manifest.json.tmp")
    let final = directory.appendingPathComponent("manifest.json")
    try encoder.encode(manifest).write(to: temporary, options: [.atomic])
    if fileManager.fileExists(atPath: final.path) {
      try fileManager.removeItem(at: final)
    }
    try fileManager.moveItem(at: temporary, to: final)
  }

  func writeFailedManifest(
    id: String,
    createdAt: Date,
    errorCode: String,
    in directory: URL
  ) {
    let manifest = ShareManifest(
      version: Self.manifestVersion,
      id: id,
      status: "failed",
      createdAtEpochMilliseconds: Int64(createdAt.timeIntervalSince1970 * 1000),
      mimeType: "",
      title: "",
      subject: "",
      text: "",
      files: [],
      errorCode: errorCode
    )
    try? writeReadyManifest(manifest, in: directory)
  }

  func copyFile(
    from source: URL,
    to directory: URL,
    position: Int,
    typeIdentifier: String
  ) throws -> ShareFile {
    let values = try source.resourceValues(forKeys: [.fileSizeKey])
    let byteCount = Int64(values.fileSize ?? 0)
    guard byteCount <= Self.maxFileBytes else { throw ShareStagingError.fileTooLarge }
    let ext = source.pathExtension.isEmpty
      ? preferredExtension(for: typeIdentifier)
      : source.pathExtension
    let destination = directory.appendingPathComponent(
      "\(String(format: "%03d", position)).\(ext)"
    )
    if fileManager.fileExists(atPath: destination.path) {
      try fileManager.removeItem(at: destination)
    }
    try fileManager.copyItem(at: source, to: destination)
    let data = try Data(contentsOf: destination, options: [.mappedIfSafe])
    return ShareFile(
      path: destination.path,
      position: position,
      typeIdentifier: typeIdentifier,
      byteCount: byteCount,
      sha256: SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    )
  }

  private func readManifest(in directory: URL) -> ShareManifest? {
    let url = directory.appendingPathComponent("manifest.json")
    guard let data = try? Data(contentsOf: url) else { return nil }
    return try? decoder.decode(ShareManifest.self, from: data)
  }

  private func payload(from manifest: ShareManifest, directory: URL) -> [String: Any]? {
    guard manifest.version == Self.manifestVersion,
          isSafeIdentifier(manifest.id),
          directory.path.hasPrefix((stagingRoot?.path ?? "") + "/")
    else { return nil }
    var files = [[String: Any]]()
    for file in manifest.files.sorted(by: { $0.position < $1.position }) {
      let url = URL(fileURLWithPath: file.path).standardizedFileURL
      guard url.path.hasPrefix(directory.standardizedFileURL.path + "/"),
            fileManager.fileExists(atPath: url.path),
            let data = try? Data(contentsOf: url, options: [.mappedIfSafe]),
            Int64(data.count) == file.byteCount,
            SHA256.hash(data: data).map({ String(format: "%02x", $0) }).joined() == file.sha256
      else { return nil }
      files.append([
        "path": url.path,
        "position": file.position,
        "typeIdentifier": file.typeIdentifier,
        "byteCount": file.byteCount,
        "sha256": file.sha256,
      ])
    }
    return [
      "version": manifest.version,
      "id": manifest.id,
      "status": manifest.status,
      "createdAtEpochMilliseconds": manifest.createdAtEpochMilliseconds,
      "mimeType": manifest.mimeType,
      "title": manifest.title,
      "subject": manifest.subject,
      "text": manifest.text,
      "files": files,
    ]
  }

  private func isSafeIdentifier(_ value: String) -> Bool {
    !value.isEmpty && value.range(of: "^[A-Za-z0-9-]+$", options: .regularExpression) != nil
  }

  private func preferredExtension(for typeIdentifier: String) -> String {
    switch typeIdentifier {
    case "public.png": return "png"
    case "public.heic": return "heic"
    case "public.jpeg": return "jpg"
    default: return "jpg"
    }
  }
}

struct ShareManifest: Codable {
  let version: Int
  let id: String
  let status: String
  let createdAtEpochMilliseconds: Int64
  let mimeType: String
  let title: String
  let subject: String
  let text: String
  let files: [ShareFile]
  let errorCode: String?
}

struct ShareFile: Codable {
  let path: String
  let position: Int
  let typeIdentifier: String
  let byteCount: Int64
  let sha256: String
}

enum ShareStagingError: Error {
  case unavailable
  case fileTooLarge
  case unsupportedType
}
