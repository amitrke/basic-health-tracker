import Flutter
import Foundation

/// Reads and writes the one sync file in the app's iCloud container, for the
/// Dart side (`lib/sync/icloud_backend.dart`).
///
/// The version is the file's modification time plus size, so a write can be
/// refused if another device changed it since it was read.
final class ICloudSync {
  static let channelName = "wellbite/icloud"
  static let containerId = "iCloud.com.subnext.wellbite"
  static let fileName = "wellbite-sync.json"

  private let queue = DispatchQueue(label: "wellbite.icloud", qos: .utility)

  static func register(with messenger: FlutterBinaryMessenger) {
    let sync = ICloudSync()
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      sync.queue.async {
        let reply: Any?
        do {
          reply = try sync.handle(call)
        } catch {
          DispatchQueue.main.async {
            result(
              FlutterError(
                code: "icloud", message: error.localizedDescription, details: nil))
          }
          return
        }
        DispatchQueue.main.async { result(reply) }
      }
    }
  }

  private func handle(_ call: FlutterMethodCall) throws -> Any? {
    switch call.method {
    case "status":
      // Signed out of iCloud, or iCloud Drive off for this app.
      guard FileManager.default.ubiquityIdentityToken != nil else { return "signedOut" }
      guard fileURL() != nil else { return "unavailable" }
      return "ok"
    case "read":
      return try read()
    case "write":
      let args = call.arguments as? [String: Any]
      guard let text = args?["text"] as? String else {
        throw NSError(
          domain: "wellbite", code: 1,
          userInfo: [NSLocalizedDescriptionKey: "Missing text"])
      }
      return try write(text, ifVersion: args?["ifVersion"] as? String)
    default:
      throw NSError(
        domain: "wellbite", code: 2,
        userInfo: [NSLocalizedDescriptionKey: "Unknown method \(call.method)"])
    }
  }

  /// Blocks while iCloud sets the container up, so call off the main thread.
  private func fileURL() -> URL? {
    FileManager.default
      .url(forUbiquityContainerIdentifier: Self.containerId)?
      .appendingPathComponent(Self.fileName)
  }

  private func version(of url: URL) -> String? {
    guard
      let values = try? url.resourceValues(forKeys: [
        .contentModificationDateKey, .fileSizeKey,
      ]),
      let date = values.contentModificationDate
    else { return nil }
    return "\(Int(date.timeIntervalSince1970 * 1000))-\(values.fileSize ?? 0)"
  }

  /// iCloud may list a file before its bytes arrive; ask for them and wait.
  private func ensureDownloaded(_ url: URL) throws {
    let keys: Set<URLResourceKey> = [.ubiquitousItemDownloadingStatusKey]
    func current() -> Bool {
      let status = try? url.resourceValues(forKeys: keys).ubiquitousItemDownloadingStatus
      return status == nil || status == .current
    }
    if current() { return }
    try FileManager.default.startDownloadingUbiquitousItem(at: url)
    for _ in 0..<50 {
      if current() { return }
      Thread.sleep(forTimeInterval: 0.2)
    }
    throw NSError(
      domain: "wellbite", code: 3,
      userInfo: [NSLocalizedDescriptionKey: "iCloud is still downloading the sync file."])
  }

  private func read() throws -> [String: String]? {
    guard let url = fileURL() else {
      throw NSError(
        domain: "wellbite", code: 4,
        userInfo: [NSLocalizedDescriptionKey: "iCloud is not available."])
    }
    guard FileManager.default.fileExists(atPath: url.path) else { return nil }
    try ensureDownloaded(url)

    var coordinationError: NSError?
    var output: [String: String]?
    var readError: Error?
    NSFileCoordinator().coordinate(
      readingItemAt: url, options: [], error: &coordinationError
    ) { readURL in
      do {
        let data = try Data(contentsOf: readURL)
        if let text = String(data: data, encoding: .utf8) {
          output = ["text": text, "version": self.version(of: readURL) ?? "0"]
        }
      } catch {
        readError = error
      }
    }
    if let error = coordinationError ?? readError { throw error }
    return output
  }

  /// Returns "conflict" if the file changed since [ifVersion] was read.
  private func write(_ text: String, ifVersion: String?) throws -> String {
    guard let url = fileURL() else {
      throw NSError(
        domain: "wellbite", code: 4,
        userInfo: [NSLocalizedDescriptionKey: "iCloud is not available."])
    }

    var coordinationError: NSError?
    var outcome = "ok"
    var writeError: Error?
    NSFileCoordinator().coordinate(
      writingItemAt: url, options: .forReplacing, error: &coordinationError
    ) { writeURL in
      let exists = FileManager.default.fileExists(atPath: writeURL.path)
      let current = exists ? self.version(of: writeURL) : nil
      if current != ifVersion {
        outcome = "conflict"
        return
      }
      do {
        try text.data(using: .utf8)!.write(to: writeURL, options: .atomic)
      } catch {
        writeError = error
      }
    }
    if let error = coordinationError ?? writeError { throw error }
    return outcome
  }
}
