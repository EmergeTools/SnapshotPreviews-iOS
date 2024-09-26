//
//  SwiftUIRenderingStrategy.swift
//  
//
//  Created by Noah Martin on 7/5/24.
//

import Foundation
import SwiftUI

enum SwiftUIRenderingError: Error {
  case renderingError
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *)
public class SwiftUIRenderingStrategy: RenderingStrategy {

  public init() { }

  private var colorScheme: ColorScheme? = nil

  @MainActor public func render(
    preview: SnapshotPreviewsCore.Preview,
    completion: @escaping (SnapshotResult) -> Void)
  {
    Task { @MainActor in
      Self.setup()
      await preparePreview(preview: preview)
      var view = preview.view()
      colorScheme = nil
      view = PreferredColorSchemeWrapper {
        AnyView(view)
      } colorSchemeUpdater: { [weak self] scheme in
        self?.colorScheme = scheme
      }
      let wrappedView = EmergeModifierView(wrapped: view)
      let renderer = ImageRenderer(content: wrappedView)
#if canImport(UIKit)
      let image = renderer.uiImage
#else
      let image = renderer.nsImage
#endif
      if let image {
        completion(SnapshotResult(image: .success(image), precision: wrappedView.precision, accessibilityEnabled: wrappedView.accessibilityEnabled, accessibilityMarkers: [], colorScheme: colorScheme))
      } else {
        completion(SnapshotResult(image: .failure(SwiftUIRenderingError.renderingError), precision: wrappedView.precision, accessibilityEnabled: wrappedView.accessibilityEnabled, accessibilityMarkers: [], colorScheme: colorScheme))
      }
    }
  }
}
