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
    
    @State private var isShowingMyCardDetail = false // added for my card sheet presentation

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
        .sheet(isPresented: $isShowingMyCardDetail) {
            MyCardDetailView()
        }
    }
    
    @State private var photoItem: PhotosPickerItem? = nil
    @State private var suggestions: [Gun] = []
    @State private var favoriteGun: String = ""
    
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 50)
                
                // --- マイカード上部 ---
                MyCardView(
                    cardMaxWidth: cardMaxWidth,
                    userName: userName,
                    selectedIconName: selectedIconName,
                    storedImageData: storedImageData,
                    playCount: playCount,
                    onTap: {
                        print("Hello")
                        isShowingMyCardDetail = true
                    }
                )
                .padding(.horizontal, 12)
                // -------------------

                VStack(alignment: .leading, spacing: 12) {
                    Text("最近のプレイ履歴")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if let entry = latestJournalEntry {
                        VStack(alignment: .leading, spacing: 4) {
                            // Field name (bold, headline)
                            Text(entry.fieldName)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            // Date/time (caption, secondary)
                            Text(entry.date, style: .date)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            // Content (subheadline/caption)
                            if !entry.gameContent.isEmpty {
                                Text(entry.gameContent)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            // Weapons (caption2)
                            if !entry.weapons.isEmpty {
                                Text("武器: \(entry.weapons.joined(separator: ", "))")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.8))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            // Result (caption2, slightly more prominent)
                            Text("勝敗: \(entry.result.displayText)")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.8))
                                .frame(maxWidth: .infinity, alignment: .leading)
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

                // --- マイカード下部（予備・削除済）---
                // この下部のMyCardViewは削除しました。
                // -----------------------------

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
            Spacer(minLength: 18)
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

// MARK: - MyCardView and MyCardDetailView
// Updated MyCardView to show userName, user icon (image or system), playCount, and matching bottom card design

struct MyCardView: View {
    let cardMaxWidth: CGFloat
    let userName: String
    let selectedIconName: String
    let storedImageData: Data?
    let playCount: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .opacity(0.85)

                VStack(spacing: 12) {
                    // --- Title at top left ---
                    HStack {
                        Text("マイカード")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    // User icon
                    if let data = storedImageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.7), lineWidth: 2))
                            .shadow(radius: 4)
                    } else {
                        Image(selectedIconName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.7), lineWidth: 2))
                            .shadow(radius: 4)
                    }
                    
                    // User name
                    Text(userName.isEmpty ? "ユーザー名" : userName)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .padding(.horizontal, 16)
                    
                    // Play count
                    Text("プレイ回数: \(playCount)回")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .fontWeight(.medium)
                }
                .padding(20)
            }
            .frame(width: 300, height: 220)
            .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MyCardDetailView: View {
    @AppStorage("userName") private var userName: String = "ユーザー名"
    @AppStorage("selectedIconName") private var selectedIconName: String = "d_icon_1"
    @AppStorage("userSelectedImageData") private var storedImageData: Data?
    @AppStorage("journalEntries") private var savedJournalEntriesData: Data = Data()
    
    @State private var isEditingName = false
    @FocusState private var isNameFieldFocused: Bool
    
    @State private var selectedImageData: IdentifiableData?
    @State private var showIconSelection = false
    @State private var showPhotoLibrary = false
    
    // Journal entries decoded for stats
    private var journalEntries: [JournalEntry] {
        (try? JSONDecoder().decode([JournalEntry].self, from: savedJournalEntriesData)) ?? []
    }
    
    // Calculate play counts
    private var playCount: Int {
        journalEntries.count
    }
    
    // 勝敗結果が enum GameResult? 型のため、optionalチェーンや lowercased() を使わずに型安全に比較するよう修正
    private var winCount: Int {
        journalEntries.filter { $0.result == .win }.count
    }
    private var loseCount: Int {
        journalEntries.filter { $0.result == .lose }.count
    }
    private var drawCount: Int {
        journalEntries.filter { $0.result == .draw }.count
    }
    
    private var totalCount: Int {
        max(playCount, 1) // avoid zero division
    }
    
    private var winRate: Double {
        Double(winCount) / Double(totalCount)
    }
    private var loseRate: Double {
        Double(loseCount) / Double(totalCount)
    }
    private var drawRate: Double {
        Double(drawCount) / Double(totalCount)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // --- ユーザーアイコン表示エリア ---
                    userIconButton
                        .padding(.top, 30)
                    
                    // --- ユーザー名編集エリア ---
                    // *** 修正: 中央寄せ・フォント大きく、鉛筆マークは下に小さく配置 ***
                    userNameView
                    
                    // --- プレイ回数表示 ---
                    // *** 修正: フォントを少し小さく調整(.title3), かつ中央寄せ ***
                    Text("プレイ回数: \(playCount)回")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    // --- 勝率半円グラフと数値表示 ---
                    VStack(spacing: 12) {
                        Text("勝率")
                            .font(.headline)
                        
                        HalfPieChart(winRate: winRate, loseRate: loseRate, drawRate: drawRate)
                            .frame(width: 250, height: 125) // 高さを半分にして半円がきれいに表示されるよう調整
                        
                        HStack(spacing: 24) {
                            StatLegend(color: .green, label: "勝ち", rate: winRate)
                            StatLegend(color: .red, label: "負け", rate: loseRate)
                            StatLegend(color: .gray, label: "引き分け", rate: drawRate)
                        }
                    }
                    .padding()
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
                .navigationTitle("マイカード詳細")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("閉じる") {
                            dismiss()
                        }
                    }
                }
            }
            .sheet(isPresented: $showIconSelection) {
                IconSelectionSheet(selectedIconName: $selectedIconName, storedImageData: $storedImageData, showPhotoLibrary: $showPhotoLibrary)
            }
            .photosPicker(isPresented: $showPhotoLibrary, selection: $photoItem, matching: .images)
            .sheet(item: $selectedImageData) { wrapper in
                if let uiImage = UIImage(data: wrapper.data) {
                    if let data = uiImage.jpegData(compressionQuality: 1.0) {
                        CircularImageCropperView(imageData: data) { croppedImage in
                            storedImageData = croppedImage.jpegData(compressionQuality: 0.9)
                            selectedIconName = "user"
                            selectedImageData = nil
                        }
                    }
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
        }
    }
    
    @Environment(\.dismiss) private var dismiss
    @State private var photoItem: PhotosPickerItem? = nil
    
    // --- ユーザーアイコンボタン ---
    private var userIconButton: some View {
        Button {
            // アイコン選択sheetを表示
            showIconSelection = true
        } label: {
            Group {
                if let data = storedImageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Image(selectedIconName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
            }
            .frame(width: 140, height: 140)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.primary.opacity(0.4), lineWidth: 3))
            .shadow(radius: 6)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // --- ユーザー名編集ビュー ---
    // HStackでTextとpencilアイコンを横並び、適切なスペースとスケーリングで中央寄せ
    private var userNameView: some View {
        HStack(spacing: 6) {
            if isEditingName {
                TextField("ユーザー名", text: $userName, onCommit: {
                    isEditingName = false
                    isNameFieldFocused = false
                })
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .multilineTextAlignment(.center)
                .focused($isNameFieldFocused)
                .onSubmit {
                    isEditingName = false
                    isNameFieldFocused = false
                }
                .submitLabel(.done)
                .frame(maxWidth: 250)
            } else {
                Text(userName.isEmpty ? "ユーザー名" : userName)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .onTapGesture {
                        isEditingName = true
                        isNameFieldFocused = true
                    }
                Image(systemName: "pencil")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .onTapGesture {
                        isEditingName = true
                        isNameFieldFocused = true
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, 12)
    }
}

// --- 半円グラフ (PieChart) 表示用カスタムビュー ---
// 勝ち/負け/引き分けの割合で色分けした半円グラフを表示。下にパーセント数値も表示。
// *** 修正：GeometryReader内のZStackの背景円とArcShapeの描画処理を見直し、重複描画を回避し、
// 半円グラフが綺麗に１つだけ表示されるように調整しました。具体的にはframeとpositionを修正。***

struct HalfPieChart: View {
    var winRate: Double
    var loseRate: Double
    var drawRate: Double
    
    private var angles: [Double] {
        let total = winRate + loseRate + drawRate
        if total == 0 {
            return [0, 0, 0]
        }
        return [winRate / total, loseRate / total, drawRate / total]
    }
    
    var body: some View {
        GeometryReader { geo in
            let diameter = min(geo.size.width, geo.size.height * 2)
            let radius = diameter / 2
            let center = CGPoint(x: diameter / 2, y: diameter / 2)
            let startAngle = Angle(degrees: 180)
            
            ZStack {
                // Background arc (gray)
                ArcShape(startAngle: startAngle, endAngle: startAngle + Angle(degrees: 180))
                    .stroke(Color.gray.opacity(0.2), lineWidth: 30)
                    .frame(width: diameter, height: diameter)
                
                // Win slice (green)
                if angles[0] > 0 {
                    ArcShape(startAngle: startAngle, endAngle: startAngle + Angle(degrees: 180 * angles[0]))
                        .stroke(Color.green, lineWidth: 30)
                        .frame(width: diameter, height: diameter)
                }
                
                // Lose slice (red)
                if angles[1] > 0 {
                    ArcShape(
                        startAngle: startAngle + Angle(degrees: 180 * angles[0]),
                        endAngle: startAngle + Angle(degrees: 180 * (angles[0] + angles[1]))
                    )
                    .stroke(Color.red, lineWidth: 30)
                    .frame(width: diameter, height: diameter)
                }
                
                // Draw slice (gray)
                if angles[2] > 0 {
                    ArcShape(
                        startAngle: startAngle + Angle(degrees: 180 * (angles[0] + angles[1])),
                        endAngle: startAngle + Angle(degrees: 180)
                    )
                    .stroke(Color.gray, lineWidth: 30)
                    .frame(width: diameter, height: diameter)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
    }
}

// 半円のArc形状（Stroke用）
struct ArcShape: Shape {
    var startAngle: Angle
    var endAngle: Angle
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // 半円の中心は矩形の下中央に設定
        let radius = min(rect.width, rect.height * 2) / 2
        let center = CGPoint(x: rect.midX, y: rect.maxY)
        
        path.addArc(center: center, radius: radius,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: false)
        return path
    }
}

// --- 各率表示用小ビュー ---
struct StatLegend: View {
    var color: Color
    var label: String
    var rate: Double
    
    var body: some View {
        VStack {
            Circle()
                .fill(color)
                .frame(width: 14, height: 14)
            Text(label)
                .font(.subheadline)
            Text(String(format: "%.0f%%", rate * 100))
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 60)
    }
}


// MARK: - Extension for GameResult display text
extension GameResult {
    var displayText: String {
        switch self {
        case .win: return "勝利"
        case .lose: return "敗北"
        case .draw: return "引き分け"
        @unknown default:
            return "不明"
        }
    }
}
