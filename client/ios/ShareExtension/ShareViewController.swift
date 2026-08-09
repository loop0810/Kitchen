import Foundation
import Social
import UniformTypeIdentifiers

final class ShareViewController: SLComposeServiceViewController {
  override func isContentValid() -> Bool { true }

  override func didSelectPost() {
    handleShare()
  }

  override func configurationItems() -> [Any]! { [] }

  private func handleShare() {
    guard let inputItems = extensionContext?.inputItems as? [NSExtensionItem],
          !inputItems.isEmpty
    else {
      complete(withError: "没有可导入的分享内容。")
      return
    }

    let providers = inputItems.flatMap { $0.attachments ?? [] }
    let shareId = UUID().uuidString.lowercased()
    let createdAt = Date()
    do {
      let directory = try KitchenNotesShareStaging.shared.createShareDirectory(id: shareId)
      let group = DispatchGroup()
      let lock = NSLock()
      var textParts = [String]()
      var files = [ShareFile]()
      var firstError: Error?
      var nextPosition = 0

      for provider in providers {
        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
          let position: Int
          lock.lock()
          position = nextPosition
          nextPosition += 1
          lock.unlock()
          group.enter()
          provider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, error in
            defer { group.leave() }
            do {
              guard let url else { throw error ?? ShareStagingError.unsupportedType }
              let file = try KitchenNotesShareStaging.shared.copyFile(
                from: url,
                to: directory,
                position: position,
                typeIdentifier: UTType.image.identifier
              )
              lock.lock()
              files.append(file)
              lock.unlock()
            } catch {
              lock.lock()
              firstError = firstError ?? error
              lock.unlock()
            }
          }
        } else if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
          group.enter()
          provider.loadItem(forTypeIdentifier: UTType.url.identifier) { item, error in
            defer { group.leave() }
            lock.lock()
            if let url = item as? URL {
              textParts.append(url.absoluteString)
            } else if let string = item as? String {
              textParts.append(string)
            } else if let error {
              firstError = firstError ?? error
            }
            lock.unlock()
          }
        } else if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
          group.enter()
          provider.loadItem(forTypeIdentifier: UTType.text.identifier) { item, error in
            defer { group.leave() }
            lock.lock()
            if let string = item as? String {
              textParts.append(string)
            } else if let error {
              firstError = firstError ?? error
            }
            lock.unlock()
          }
        } else {
          firstError = ShareStagingError.unsupportedType
        }
      }

      group.notify(queue: .main) {
        do {
          if let firstError { throw firstError }
          let totalBytes = files.reduce(Int64(0)) { $0 + $1.byteCount }
          guard totalBytes <= KitchenNotesShareStaging.maxShareBytes,
                !textParts.isEmpty || !files.isEmpty
          else { throw ShareStagingError.unsupportedType }
          let manifest = ShareManifest(
            version: KitchenNotesShareStaging.manifestVersion,
            id: shareId,
            status: "ready",
            createdAtEpochMilliseconds: Int64(createdAt.timeIntervalSince1970 * 1000),
            mimeType: files.isEmpty ? "public.text" : UTType.image.identifier,
            title: "",
            subject: "",
            text: textParts.joined(separator: "\n"),
            files: files.sorted(by: { $0.position < $1.position }),
            errorCode: nil
          )
          try KitchenNotesShareStaging.shared.writeReadyManifest(manifest, in: directory)
          self.complete()
        } catch {
          KitchenNotesShareStaging.shared.writeFailedManifest(
            id: shareId,
            createdAt: createdAt,
            errorCode: String(describing: error),
            in: directory
          )
          self.complete(withError: "分享内容暂时无法保存，请稍后重试。")
        }
      }
    } catch {
      complete(withError: "厨房手记暂时无法接收分享内容。")
    }
  }

  private func complete(withError message: String? = nil) {
    if let message {
      let error = NSError(domain: "KitchenNotesShareExtension", code: 1, userInfo: [
        NSLocalizedDescriptionKey: message,
      ])
      extensionContext?.cancelRequest(withError: error)
    } else {
      extensionContext?.completeRequest(returningItems: nil)
    }
  }
}
