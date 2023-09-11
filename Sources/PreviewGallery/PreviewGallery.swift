//
//  PreviewGallery.swift
//
//
//  Created by Noah Martin on 7/3/23.
//

import Foundation
import SwiftUI
import SnapshotPreviewsCore

struct PreviewCellView: View {
  let preview: PreviewType
  
  var body: some View {
    NavigationLink {
      PreviewsDetail(previewType: preview)
    } label: {
      VStack(alignment: .center, spacing: 8) {
        TitleSubtitleRow(
          title: preview.displayName,
          subtitle: "\(preview.previews.count) Preview\(preview.previews.count != 1 ? "s" : "")")
        PreviewCell(preview: preview.previews[0])
        Divider()
      }
    }
    .background(Color(UIColor.systemBackground))
  }
}

public struct PreviewGallery: View {
  
  let data: PreviewData
  
  public init(data: PreviewData = .default) {
    self.data = data
  }
  
  public var body: some View {
    if data.modules.count > 1 {
      List {
        ForEach(Array(data.modules).sorted(), id: \.self) { module in
          ModulePreviews(module: module, data: data)
        }
      }.navigationTitle("Modules")
    } else {
      ScrollView {
        LazyVStack(alignment: .leading) {
          ForEach(data.previews(in: data.modules.first!)) { preview in
            PreviewCellView(preview: preview)
          }
        }
      }
    }
  }
}
