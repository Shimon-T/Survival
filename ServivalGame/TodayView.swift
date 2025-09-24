//
//  TodayView.swift
//  ServivalGame
//
//  Created by 田中志門 on 6/1/25.
//

import SwiftUI
import PhotosUI
import UIKit
import TOCropViewController

// Wrapper to make Data Identifiable for .sheet(item:)
struct IdentifiableData: Identifiable {
    var id = UUID()
    let data: Data
}

struct TodayView: View {
    @EnvironmentObject var journalStore: JournalStore
    
    @State private var selectedImage: UIImage?
    @State private var selectedImageData: IdentifiableData?
    @State private var showPhotoPicker = false
    @State private var showGearViewSheet = false
    @State private var showAddJournalSheet = false
    @State private var showIconSelection = false
    @State private var showPhotoLibrary = false
    @AppStorage("selectedIconName") private var selectedIconName: String = "d_icon_1"
    @AppStorage("userSelectedImageData") private var storedImageData: Data?
    @AppStorage("journalEntries") private var savedJournalEntriesData: Data = Data()
    @AppStorage("userName") private var userName: String = "ユーザー名"
    
    @State private var isEditingName = false
    @FocusState private var isNameFieldFocused: Bool
    @State private var playCount: Int = 0 // Added playCount state

    let cardMaxWidth = UIScreen.main.bounds.width * 0.8

    private var latestJournalEntry: JournalEntry? {
        guard let decoded = try? JSONDecoder().decode([JournalEntry].self, from: savedJournalEntriesData), !decoded.isEmpty else { return nil }
        return decoded.sorted { $0.date > $1.date }.first
    }
    
    private var achievementBadges: [(icon: String, title: String, reached: Bool, color: Color)] {
        let milestones = [(5, "star"), (10, "flame"), (30, "crown"), (50, "trophy")]
        let colors: [Color] = [.yellow, .orange, .pink, .red]
        return milestones.enumerated().map { (idx, pair) in
            let (count, icon) = pair
            let reached = playCount >= count
            let color = reached ? colors[idx] : .gray
            return (icon: icon, title: "\(count)回", reached: reached, color: color)
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Image("BackGround")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                mainContent
            }
        }
        .photosPicker(isPresented: $showPhotoLibrary, selection: $photoItem, matching: .images)
        .sheet(isPresented: $showGearViewSheet) {
            GearView(startWithAddGear: true)
        }
        .sheet(isPresented: $showAddJournalSheet) {
            JournalView(startWithAddEntry: true)
                .environmentObject(journalStore)
        }
        .sheet(isPresented: $showIconSelection) {
            IconSelectionSheet(selectedIconName: $selectedIconName, storedImageData: $storedImageData, showPhotoLibrary: $showPhotoLibrary)
        }
    }
    
    @State private var photoItem: PhotosPickerItem? = nil
    @State private var suggestions: [Gun] = []
    @State private var favoriteGun: String = ""
    
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 50)
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        userIconButton
                        userNameView
                    }
                    playStatsSection
                }
                .frame(maxWidth: 300)
                .padding(.top, 30)
                .background(
                    RoundedRectangle(cornerRadius: 32)
                        .fill(Color.white.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1.0)
                )
                .shadow(color:
                        .black.opacity(0.15), radius: 8, y: 4)
                .padding(.horizontal, 12)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("最近のプレイ履歴")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if let entry = latestJournalEntry {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.date, style: .date)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.85))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("フィールド: \(entry.fieldName)")
                                .font(.body)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            if !entry.gameContent.isEmpty {
                                Text("内容: \(entry.gameContent)")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.9))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            if !entry.weapons.isEmpty {
                                Text("武器: \(entry.weapons.joined(separator: ", "))")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.8))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    } else {
                        Text("まだ履歴がありません")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(width: 300, alignment: .leading)
                .padding(18)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.07)))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.15), lineWidth: 1.0))
                .shadow(color: .black.opacity(0.10), radius: 4, y: 2)
                .padding(.horizontal, 12)

                VStack(alignment: .leading, spacing: 10) {
                    Text("アチーブメントバッチ")
                        .font(.headline)
                        .foregroundColor(.white)
                    HStack(spacing: 8) {
                        ForEach(achievementBadges, id: \.icon) { badge in
                            VStack(spacing: 4) {
                                Image(systemName: badge.icon)
                                    .resizable()
                                    .frame(width: 32, height: 32)
                                    .foregroundColor(badge.color)
                                    .opacity(badge.reached ? 1.0 : 0.4)
                                Text(badge.title)
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            }
                            .frame(width: 56)
                        }
                    }
                }
                .frame(width: 300)
                .multilineTextAlignment(.leading)
                .padding(18)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.07)))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.13), lineWidth: 1))
                .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
                .padding(.horizontal, 12)

                HStack(spacing: 16) {
                    Button(action: { showGearViewSheet = true }) {
                        ZStack {
                            Image("camo1")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 140, height: 60)
                                .clipped()
                                .cornerRadius(16)
                            Text("装備")
                                .foregroundColor(.white)
                                .font(.headline)
                                .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 0)
                        }
                    }
                    .frame(width: 140, height: 60)
                    .buttonStyle(.plain)

                    Button(action: { showAddJournalSheet = true }) {
                        ZStack {
                            Image("camo2")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 140, height: 60)
                                .clipped()
                                .cornerRadius(16)
                            Text("記録")
                                .foregroundColor(.white)
                                .foregroundStyle(.white)
                                .colorMultiply(.white)
                                .font(.headline)
                                .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 0)
                        }
                    }
                    .frame(width: 140 , height: 60)
                    .buttonStyle(.plain)
                }
                .frame(width: 300)
                .padding(.horizontal, 12)

                Spacer(minLength: 12)
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 24)
        }
        .background(Color.clear)
        .scrollIndicators(.hidden)
        .navigationTitle("アカウント")
        .toolbarColorScheme(.dark)
        .onAppear {
            var count = 0
            if let decoded = try? JSONDecoder().decode([JournalEntry].self, from: savedJournalEntriesData) {
                count = decoded.count
            }
            self.playCount = count
            print("[DEBUG] UserDefaults(AppStorage)から取得したプレイ数: \(count)")
        }
        .onChange(of: savedJournalEntriesData) { _ in
            if let decoded = try? JSONDecoder().decode([JournalEntry].self, from: savedJournalEntriesData) {
                self.playCount = decoded.count
            } else {
                self.playCount = 0
            }
        }
        .onChange(of: photoItem) { newPhotoItem in
            guard let photoItem = newPhotoItem else { return }
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
    }
    
    private var userNameView: some View {
        HStack {
            if isEditingName {
                TextField("ユーザー名", text: $userName, onCommit: {
                    isEditingName = false
                    isNameFieldFocused = false
                })
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($isNameFieldFocused)
                .onSubmit {
                    isEditingName = false
                    isNameFieldFocused = false
                }
                .submitLabel(.done)
            } else {
                if userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("...")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .onTapGesture {
                            isEditingName = true
                            isNameFieldFocused = true
                        }
                } else {
                    HStack(spacing: 4) {
                        Text(userName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Image(systemName: "pencil")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .onTapGesture {
                        isEditingName = true
                        isNameFieldFocused = true
                    }
                }
            }
        }
        .padding(.horizontal, 10)
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
                    .overlay(Circle().fill(Color.black.opacity(0.36)))
                    .overlay(Circle().stroke(Color.white.opacity(0.7), lineWidth: 2))
            } else {
                Image(selectedIconName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 97, height: 97)
                    .clipShape(Circle())
                    .overlay(Circle().fill(Color.black.opacity(0.36)))
                    .overlay(Circle().stroke(Color.white.opacity(0.7), lineWidth: 2))
            }
        }
    }
    
    private var playStatsSection: some View {
        VStack(spacing: 8) {
            Text("プレイ回数: \(playCount)回")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
    }

    @ViewBuilder
    private func searchGuns(keyword: String) {
        guard let url = Bundle.main.url(forResource: "guns", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Gun].self, from: data) else {
            self.suggestions = []
            return
        }

        let filtered = decoded.filter { $0.name.localizedCaseInsensitiveContains(keyword) }
        self.suggestions = filtered
    }

    struct Gun: Identifiable, Codable {
        let id: String
        let name: String
        let imageURL: String
    }
}

struct IconSelectionSheet: View {
    @Binding var selectedIconName: String
    @Binding var storedImageData: Data?
    @Binding var showPhotoLibrary: Bool
    @Environment(\.dismiss) private var dismiss

    let iconNames = (1...9).map { "d_icon_\($0)" }

    var body: some View {
        NavigationView {
            VStack(spacing: 18) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 18), count: 3), spacing: 22) {
                    ForEach(iconNames, id: \.self) { name in
                        Button(action: {
                            selectedIconName = name
                            storedImageData = nil
                            dismiss()
                        }) {
                            Image(name)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 68, height: 68)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(selectedIconName == name ? Color.blue : .clear, lineWidth: 3))
                        }
                    }
                }
                .padding(.vertical, 6)
                Divider()
                Button(action: {
                    showPhotoLibrary = true
                    dismiss()
                }) {
                    Label("写真から選ぶ", systemImage: "photo.on.rectangle")
                        .font(.title3.bold())
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.13))
                        .cornerRadius(10)
                }
            }
            .padding()
            .navigationTitle("アイコン選択")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
}

// Suggestion for JournalStore removal of UserDefaults key when all records deleted
// This is NOT part of TodayView.swift but to fulfill instruction:
//
// In JournalStore.swift (not shown here), inside the method that deletes entries, add:
//
// if entries.isEmpty {
//     UserDefaults.standard.removeObject(forKey: "JournalEntries")
// }

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

