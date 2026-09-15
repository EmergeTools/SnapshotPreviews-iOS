#if canImport(UIKit) && !os(watchOS)
import UIKit
import ObjectiveC

enum ActivityIndicatorFreezing {
  private static let installed: Void = {
    guard
      let original = class_getInstanceMethod(UIActivityIndicatorView.self, #selector(UIActivityIndicatorView.startAnimating)),
      let replacement = class_getInstanceMethod(UIActivityIndicatorView.self, #selector(UIActivityIndicatorView.snapshotPreviews_frozenStartAnimating))
    else { return }
    method_exchangeImplementations(original, replacement)
  }()

  static func isEnabled(environment: [String: String] = ProcessInfo.processInfo.environment) -> Bool {
    environment["SNAPSHOTS_DISABLE_FREEZE_SPINNERS"] != "1"
  }

  static func install() {
    guard isEnabled() else { return }
    _ = installed
  }
}

private extension UIActivityIndicatorView {
  @objc dynamic func snapshotPreviews_frozenStartAnimating() {}
}
#endif
