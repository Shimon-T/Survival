//
//  TodayView.swift
//  ServivalGame
//
//  Created by 田中志門 on 6/1/25.
//


import SwiftUI
import PhotosUI

// Wrapper to make Data Identifiable for .sheet(item:)
struct IdentifiableData: Identifiable {
    var id = UUID()
    let data: Data
}

struct TodayView: View {
    @State private var playCount = 0
    @State private var selectedImage: UIImage?
    @State private var selectedImageData: IdentifiableData?
    @State private var showPhotoPicker = false
    @State private var showGunEntrySheet = false
    @State private var favoriteGun: String = ""
    @State private var battleLogs: [String] = []
    @State private var showAllBattles: Bool = false
    @State private var photoItem: PhotosPickerItem?
    @State private var suggestions: [Gun] = []
    @State private var showIconSelection = false
    @AppStorage("selectedIconName") private var selectedIconName: String = "d_icon_1"
    @AppStorage("userSelectedImageData") private var storedImageData: Data?

var body: some View {
    ZStack {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color.white, location: 0.0),
                .init(color: Color(white: 0.9), location: 0.5),
                .init(color: Color(white: 0.85), location: 1.0)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        mainContent
    }
    .photosPicker(isPresented: $showPhotoPicker, selection: $photoItem, matching: .images)
}

private var mainContent: some View {
    NavigationView {
        VStack(spacing: 24) {
            Spacer()

            userIconButton

            playStatsSection

            favoriteGunSection

            ForEach(showAllBattles ? battleLogs : Array(battleLogs.prefix(3)), id: \.self) { log in
                Text("・\(log)")
                    .font(.body)
            }

            if battleLogs.count >= 4 && !showAllBattles {
                Button("もっと") {
                    showAllBattles = true
                }
                .padding(.top, 8)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("アカウント")
        .onChange(of: photoItem) {
            guard let photoItem else { return }
            Task {
                if let data = try? await photoItem.loadTransferable(type: Data.self) {
                    selectedImageData = IdentifiableData(data: data)
                }
            }
        }
        .sheet(item: $selectedImageData) { wrapper in
            if let uiImage = UIImage(data: wrapper.data) {
                if let data = uiImage.jpegData(compressionQuality: 1.0) {
                    CircularImageCropperView(imageData: data) { croppedImage in
                        selectedImage = croppedImage
                        storedImageData = croppedImage.jpegData(compressionQuality: 0.9)
                        selectedIconName = "user"
                        selectedImageData = nil
                    }
                }
            }
        }
        .sheet(isPresented: $showGunEntrySheet) {
            GunEntrySheet(favoriteGun: $favoriteGun,
                          suggestions: $suggestions,
                          searchGuns: searchGuns)
        }
    }
    .sheet(isPresented: $showIconSelection) {
        iconSelectionSheet
    }
}

private var userIconButton: some View {
    Button {
        showIconSelection = true
    } label: {
        if let data = storedImageData, let restoredImage = UIImage(data: data) {
            Image(uiImage: restoredImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .clipped()
        } else {
            Image(selectedIconName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 97, height: 97)
                .clipShape(Circle())
        }
    }
}

private var playStatsSection: some View {
    VStack(spacing: 8) {
        Text("サバゲープレイ数: \(playCount)回")
            .font(.headline)
        Text("ランキング: 全国102位")
            .font(.subheadline)
            .foregroundColor(.gray)
        Button("プレイ数を追加") {
            playCount += 1
        }
    }
}

private var favoriteGunSection: some View {
    VStack(alignment: .center, spacing: 12) {
        Text("お気に入りの銃")
            .font(.title2)
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity, alignment: .leading)

        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 200, height: 80)
                .overlay(
                    favoriteGunImageOnlyView()
                )
                .onTapGesture {
                    showGunEntrySheet = true
                }

            if let selected = suggestions.first(where: { $0.name == favoriteGun }) {
                Text(selected.name)
                    .font(.caption)
            } else {
                Text("未登録")
                    .font(.caption)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)

        Text("直近のバトル記録")
            .font(.title3)
            .padding(.top, 16)
    }
    .padding(.horizontal)
}

private var iconSelectionSheet: some View {
    VStack(spacing: 20) {
        Text("アイコンを選択")
            .font(.headline)

        let defaultIcons = (1...9).map { "d_icon_\($0)" }
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 3), spacing: 16) {
            ForEach(defaultIcons, id: \.self) { iconName in
                ZStack {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 80, height: 80)
                    Image(iconName)
                        .resizable(capInsets: EdgeInsets(), resizingMode: .stretch)
                        .scaledToFill()
                        .frame(width: 88, height: 88) // 1.1x of 80
                        .clipShape(Circle())
                }
                .onTapGesture {
                    selectedImage = nil
                    storedImageData = nil
                    selectedIconName = iconName
                    showIconSelection = false
                }
            }
        }

        Button("写真から選ぶ") {
            showIconSelection = false
            showPhotoPicker = true
        }
        .padding()
    }
    .padding()
}
    
    @ViewBuilder
    private func favoriteGunImageOnlyView() -> some View {
        if let selected = suggestions.first(where: { $0.name == favoriteGun }) {
            AsyncImage(url: URL(string: selected.imageURL)) { image in
                image
                    .resizable(capInsets: EdgeInsets(), resizingMode: .stretch)
                    .scaledToFit()
                    .frame(width: 200)
                    .clipped()
                    .cornerRadius(10)
            } placeholder: {
                Color.gray
                    .frame(width: 200, height: 80)
                    .cornerRadius(10)
            }
        }
    }
    
    @ViewBuilder
    private func favoriteGunView() -> some View {
        if let selected = suggestions.first(where: { $0.name == favoriteGun }) {
            VStack {
                AsyncImage(url: URL(string: selected.imageURL)) { image in
                    image.resizable().scaledToFit().frame(height: 60)
                } placeholder: {
                    Color.gray.frame(height: 60)
                }
                Text(selected.name)
                    .font(.caption)
            }
        } else {
            Text("未登録")
                .font(.headline)
        }
    }
    
    private func searchGuns(keyword: String) {
        guard let encoded = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://my-api-4aul.onrender.com/guns/search?q=\(encoded)") else {
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data {
                if let decoded = try? JSONDecoder().decode([Gun].self, from: data) {
                    DispatchQueue.main.async {
                        self.suggestions = decoded
                    }
                }
            }
        }.resume()
    }
    
    struct Gun: Identifiable, Codable {
        let id: String
        let name: String
        let imageURL: String
    }
}

struct GunEntrySheet: View {
    @Binding var favoriteGun: String
    @Binding var suggestions: [TodayView.Gun]
    var searchGuns: (String) -> Void
    @State private var newGunName = ""
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("銃の名前")) {
                    TextField("例: M4A1", text: $newGunName)
                        .submitLabel(.done)
                        .onSubmit {
                            searchGuns(newGunName)
                        }

                    ForEach(suggestions) { gun in
                        HStack {
                            AsyncImage(url: URL(string: gun.imageURL)) { image in
                                image.resizable().frame(width: 40, height: 30).cornerRadius(5)
                            } placeholder: {
                                Color.gray.frame(width: 40, height: 30)
                            }
                            Text(gun.name)
                        }
                        .onTapGesture {
                            favoriteGun = gun.name
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("銃を登録")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        if !newGunName.isEmpty {
                            favoriteGun = newGunName
                        }
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
    }
}

import UIKit
import TOCropViewController

struct CircularImageCropperView: UIViewControllerRepresentable {
    let imageData: Data
    var onCropped: (UIImage) -> Void

    func makeUIViewController(context: Context) -> TOCropViewController {
        guard let image = UIImage(data: imageData) else {
            return TOCropViewController()
        }
        let controller = TOCropViewController(croppingStyle: .circular, image: image)
        controller.rotateButtonsHidden = true
        controller.resetButtonHidden = true
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: TOCropViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, TOCropViewControllerDelegate {
        let parent: CircularImageCropperView

        init(_ parent: CircularImageCropperView) {
            self.parent = parent
        }

        func cropViewController(_ cropViewController: TOCropViewController, didCropToCircularImage image: UIImage, with cropRect: CGRect, angle: Int) {
            parent.onCropped(image)
            cropViewController.dismiss(animated: true)
        }

        func cropViewController(_ cropViewController: TOCropViewController, didFinishCancelled cancelled: Bool) {
            cropViewController.dismiss(animated: true)
        }
    }
}
