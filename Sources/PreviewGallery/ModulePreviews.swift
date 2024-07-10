//
//  ModulePreviews.swift
//
//
//  Created by Noah Martin on 7/3/23.
//

import Foundation
import SwiftUI

struct ModulePreviews: View {
  let module: String
  let data: PreviewData
  
  var body: some View {
    let componentProviders = data.previews(in: module).filter { provider in
      return provider.previews.contains { preview in
        return !preview.requiresFullScreen
      }
    }
    let featureProviders = data.previews(in: module).filter { provider in
      return provider.previews.contains { preview in
        return preview.requiresFullScreen
      }
    }
    return NavigationLink(module) {
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 12) {
          if !featureProviders.isEmpty {
            NavigationLink(destination: ModuleScreens(module: module, data: data)) {
              TitleSubtitleRow(
                title: "Screens",
                subtitle: "\(featureProviders.count) Preview\(featureProviders.count != 1 ? "s" : "")")
              .padding(16)
              #if !os(watchOS)
              .background(Color(PlatformColor.gallerySecondaryBackground))
              #endif
            }
          }
          ForEach(componentProviders) { preview in
            NavigationLink(destination: PreviewsDetail(previewType: preview)) {
              PreviewCellView(preview: preview)
              #if !os(watchOS)
                .background(Color(PlatformColor.gallerySecondaryBackground))
              #endif
                .allowsHitTesting(false)
            }
            #if canImport(UIKit) && !os(visionOS) && !os(watchOS)
            .frame(width: UIScreen.main.bounds.width)
            #endif
          }
        }
      }
      #if !os(watchOS)
      .background(Color(PlatformColor.galleryBackground))
      #endif
      .navigationTitle(module)
    }
  }
}
