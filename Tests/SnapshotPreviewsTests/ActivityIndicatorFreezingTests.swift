#if canImport(UIKit) && !os(watchOS)
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

  func testFreezingIsEnabledByDefault() {
    XCTAssertTrue(ActivityIndicatorFreezing.isEnabled(environment: [:]))
  }

  func testFreezingIsDisabledByEnvironmentVariable() {
    XCTAssertFalse(ActivityIndicatorFreezing.isEnabled(environment: ["SNAPSHOTS_DISABLE_FREEZE_SPINNERS": "1"]))
  }
}
#endif
