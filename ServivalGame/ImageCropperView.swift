//
//  ImageCropperView.swift
//  ServivalGame
//
//  Created by 田中志門 on 6/4/25.
//

import SwiftUI

struct ImageCropperView: View {
    let imageData: Data
    let onCrop: (UIImage) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var zoom: CGFloat = 1.0
    @State private var offset: CGSize = .zero

    var body: some View {
        VStack {
            if let uiImage = UIImage(data: imageData) {
                GeometryReader { geometry in
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(zoom)
                        .offset(offset)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    zoom = value
                                }
                        )
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    offset = value.translation
                                }
                        )
                }
                .clipped()
                .padding()

                HStack {
                    Button("キャンセル") {
                        dismiss()
                    }
                    Spacer()
                    Button("決定") {
                        onCrop(uiImage)
                        dismiss()
                    }
                }
                .padding()
            } else {
                Text("画像の読み込みに失敗しました")
            }
        }
    }
}
