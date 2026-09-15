#if canImport(UIKit)
import UIKit
import ObjectiveC

enum ActivityIndicatorFreezing {
  private static let installed: Void = {
    guard
      let original = class_getInstanceMethod(UIActivityIndicatorView.self, #selector(UIActivityIndicatorView.startAnimating)),
      let replacement = class_getInstanceMethod(UIActivityIndicatorView.self, #selector(UIActivityIndicatorView.emg_frozenStartAnimating))
    else { return }
    method_exchangeImplementations(original, replacement)
  }()

  static func install() {
    _ = installed
  }
}

private extension UIActivityIndicatorView {
  @objc func emg_frozenStartAnimating() {}
}
#endif
