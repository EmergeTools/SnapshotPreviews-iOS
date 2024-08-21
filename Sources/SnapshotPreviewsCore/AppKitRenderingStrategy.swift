//
//  AppKitRenderingStrategy.swift
//
//
//  Created by Noah Martin on 8/8/24.
//

#if canImport(AppKit)
import Foundation
import AppKit
import SwiftUI
import SnapshotSharedModels

class BorderlessWindow: NSWindow {
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing bufferingType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [.borderless], backing: bufferingType, defer: flag)
        self.isOpaque = false
        self.backgroundColor = NSColor.clear
    }
}

public class AppKitRenderingStrategy: RenderingStrategy {

  private let window: NSWindow

  public init() {
    window = BorderlessWindow()
    window.setContentSize(NSSize(width: 100, height: 100))
    window.makeKeyAndOrderFront(nil)
  }

  private var colorScheme: ColorScheme? = nil

  @MainActor public func render(
    preview: SnapshotPreviewsCore.Preview,
    completion: @escaping (SnapshotResult) -> Void)
  {
    let view = preview.view()
    let vc = AppKitContainer(rootView: view)
    vc.setupView(layout: preview.layout)
    vc.rendered = { mode, precision, accessibilityEnabled in
      let image = vc.view.snapshot()
      completion(
        SnapshotResult(
          image: image != nil ? .success(image!) : .failure(SwiftUIRenderingError.renderingError),
          precision: precision,
          accessibilityEnabled: accessibilityEnabled,
          accessibilityMarkers: nil,
          colorScheme: nil))
    }
    window.contentViewController = vc
  }
}

final class AppKitContainer: NSHostingController<EmergeModifierView> {

  private var didCall = false

  private var heightAnchor: NSLayoutConstraint?
  private var widthAnchor: NSLayoutConstraint?

  public var rendered: ((EmergeRenderingMode?, Float?, Bool?) -> Void)? {
    didSet { didCall = false }
  }

  init<Content: View>(rootView: Content) {
    super.init(rootView: EmergeModifierView(wrapped: rootView))

    if #available(macOS 13.0, *) {
      sizingOptions = .intrinsicContentSize
    }
    view.translatesAutoresizingMaskIntoConstraints = false
  }

  @MainActor required dynamic init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public func removeConstraints() {
    heightAnchor?.isActive = false
    widthAnchor?.isActive = false
    heightAnchor = nil
    widthAnchor = nil
  }

  public func setupView(layout: PreviewLayout) {
    removeConstraints()
    switch layout {
    case let .fixed(width: width, height: height):
      widthAnchor = view.widthAnchor.constraint(equalToConstant: width)
      widthAnchor?.isActive = true
      heightAnchor = view.heightAnchor.constraint(equalToConstant: height)
      heightAnchor?.isActive = true
    default:
      let fittingSize = sizeThatFits(in: NSScreen.main!.frame.size)
      widthAnchor = view.widthAnchor.constraint(greaterThanOrEqualToConstant: fittingSize.width)
      widthAnchor?.isActive = true
      heightAnchor = view.heightAnchor.constraint(greaterThanOrEqualToConstant: fittingSize.height)
      heightAnchor?.isActive = true
    }
  }

  private func runCallback() {
    guard !didCall else { return }

    didCall = true
    rendered?(rootView.emergeRenderingMode, rootView.precision, rootView.accessibilityEnabled)
  }

  override func viewDidLayout() {
    super.viewDidLayout()
    runCallback()
  }
}

extension NSView {
    func snapshot() -> NSImage? {
        guard let bitmapRep = bitmapImageRepForCachingDisplay(in: bounds) else {
            return nil
        }
        bitmapRep.size = bounds.size
        cacheDisplay(in: bounds, to: bitmapRep)

        let image = NSImage(size: bounds.size)
        image.addRepresentation(bitmapRep)

        return image
    }
}
#endif