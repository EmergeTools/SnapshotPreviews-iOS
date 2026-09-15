#if canImport(UIKit)
import XCTest
import UIKit
@testable import SnapshotPreviewsCore

final class ActivityIndicatorFreezingTests: XCTestCase {
  @MainActor
  func testStartAnimatingIsNoOpAfterRenderingSetup() {
    UIKitRenderingStrategy.setup()

    let indicator = UIActivityIndicatorView(style: .medium)
    indicator.startAnimating()

    XCTAssertFalse(indicator.isAnimating)
  }
}
#endif
