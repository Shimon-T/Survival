//
//  GearView.swift
//  ServivalGame
//
//  Created by 田中志門 on 6/1/25.
//

import SwiftUI
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

struct ForegroundCutoutImage: View {
    let imageUrl: URL
    @State private var processedImage: UIImage?
    @State private var isProcessing = false
    private let outlineRadius: CGFloat = 1

    var body: some View {
        Group {
            if let processedImage {
                Image(uiImage: processedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                AsyncImage(url: imageUrl) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView()
                }
                .onAppear {
                    if !isProcessing { processImage() }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 50))
    }

    private func processImage() {
        isProcessing = true
        DispatchQueue.global(qos: .userInitiated).async {
            guard let data = try? Data(contentsOf: imageUrl), let uiImage = UIImage(data: data), let cgImage = uiImage.cgImage else {
                isProcessing = false
                return
            }
            let request = VNGenerateForegroundInstanceMaskRequest()
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
                guard let firstObservation = request.results?.first as? VNInstanceMaskObservation else {
                    isProcessing = false
                    return
                }
                let mask = try firstObservation.generateScaledMaskForImage(forInstances: firstObservation.allInstances, from: handler)
                let ciImage = CIImage(cgImage: cgImage)
                let maskImage = CIImage(cvPixelBuffer: mask)
                let compositor = CIFilter.blendWithMask()
                compositor.inputImage = ciImage
                compositor.backgroundImage = CIImage(color: .clear).cropped(to: ciImage.extent)
                compositor.maskImage = maskImage

                guard let cutoutCI = compositor.outputImage else {
                    isProcessing = false
                    return
                }

                let dilated = maskImage.applyingFilter("CIMorphologyMaximum", parameters: [kCIInputRadiusKey: outlineRadius])
                let eroded  = maskImage.applyingFilter("CIMorphologyMinimum", parameters: [kCIInputRadiusKey: outlineRadius])
                let outlineBand = dilated.applyingFilter("CIDifferenceBlendMode", parameters: [kCIInputBackgroundImageKey: eroded])

                let strokeCIColor = CIColor(red: 245.0/25.0, green: 245.0/255.0, blue: 245.0/255.0, alpha: 1)
                let strokeImage = CIImage(color: strokeCIColor).cropped(to: ciImage.extent)
                let strokeBlend = CIFilter.blendWithMask()
                strokeBlend.inputImage = strokeImage
                strokeBlend.backgroundImage = cutoutCI
                strokeBlend.maskImage = outlineBand

                let context = CIContext()
                guard let finalCI = strokeBlend.outputImage, let cgFinal = context.createCGImage(finalCI, from: ciImage.extent) else {
                    isProcessing = false
                    return
                }
                let result = UIImage(cgImage: cgFinal)
                DispatchQueue.main.async {
                    self.processedImage = result
                }
            } catch {
                print("Vision error: \(error)")
            }
            isProcessing = false
        }
    }
}

extension UIImage {
    func drawnWithOutline(outlineColor: UIColor, lineWidth: CGFloat) -> UIImage {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        let context = UIGraphicsGetCurrentContext()!
        draw(in: rect)
        context.saveGState()
        context.setStrokeColor(outlineColor.cgColor)
        context.setLineWidth(lineWidth)
        context.setAlpha(0.7)
        context.stroke(rect)
        context.restoreGState()
        let outlined = UIGraphicsGetImageFromCurrentImageContext() ?? self
        UIGraphicsEndImageContext()
        return outlined
    }
}

struct Gun: Identifiable, Codable {
    let id: String
    let name: String
    let type: String
    let maker: String
    let imageURL: String?
    let ageRating: Int?
    let siteURL: String?

    var imageURLValue: URL? {
        if let urlString = imageURL {
            return URL(string: urlString)
        }
        return nil
    }

    var identityKey: String {
        "\(id)|\(name)|\(maker)"
    }
}


struct GearView: View {
    let iconNames: [String: String] = [
        "ハンドガン": "icon_handgun",
        "ショットガン": "icon_shotgun",
        "アサルト": "icon_assault",
        "ライフル": "icon_rifle",
        "グレネード": "icon_grenade",
        "その他": "icon_other"
    ]
    @AppStorage("savedGuns") private var savedGunsData: Data = Data()
    @State private var ownedGuns: [Gun] = [] {
        didSet {
            if let encoded = try? JSONEncoder().encode(ownedGuns) {
                savedGunsData = encoded
            }
        }
    }
    @State private var isPresentingSearch: Bool = false

    init(startWithAddGear: Bool = false) {
        _isPresentingSearch = State(initialValue: startWithAddGear)
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {

                let groupedGuns = Dictionary(grouping: ownedGuns) { $0.type }
                let categories = ["ハンドガン", "ショットガン", "アサルト", "ライフル", "グレネード", "その他"]

                categoryScrollView(groupedGuns: groupedGuns, categories: categories)

                Button(action: {
                    isPresentingSearch = true
                }) {
                    Text("装備を追加")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 245/255, green: 245/255, blue: 245/255))
                        .cornerRadius(12)
                }
                .fullScreenCover(isPresented: $isPresentingSearch) {
                    WeaponSearchView(
                        ownedGuns: $ownedGuns,
                        onWeaponAdded: { gun in
                            var categorizedGun = gun
                            if gun.type == "アサルト" {
                                categorizedGun = Gun(
                                    id: gun.id,
                                    name: gun.name,
                                    type: "アサルト",
                                    maker: gun.maker,
                                    imageURL: gun.imageURL,
                                    ageRating: gun.ageRating,
                                    siteURL:gun.siteURL
                                )
                            } else if gun.type == "スナイパーライフル" {
                                categorizedGun = Gun(
                                    id: gun.id,
                                    name: gun.name,
                                    type: "ライフル",
                                    maker: gun.maker,
                                    imageURL: gun.imageURL,
                                    ageRating: gun.ageRating,
                                    siteURL:gun.siteURL
                                )
                            } else if gun.type == "SMG" || gun.type == "サブマシンガン" {
                                categorizedGun = Gun(
                                    id: gun.id,
                                    name: gun.name,
                                    type: "その他",
                                    maker: gun.maker,
                                    imageURL: gun.imageURL,
                                    ageRating: gun.ageRating,
                                    siteURL:gun.siteURL
                                )
                            }
                            if !ownedGuns.contains(where: { $0.identityKey == categorizedGun.identityKey }) {
                                ownedGuns.append(categorizedGun)
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                reloadOwnedGuns()
                            } else {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                reloadOwnedGuns()
                            }
                        },
                        onWeaponRemoved: { gun in
                            ownedGuns.removeAll(where: { $0.identityKey == gun.identityKey })
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            reloadOwnedGuns()
                        },
                        dismiss: {
                            isPresentingSearch = false
                        }
                    )
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(
                ZStack {
                    Image("BackGround_g")
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                }
            )
            .navigationTitle("装備")
            .toolbarColorScheme(.dark)
        }
        .onAppear {
            if let decoded = try? JSONDecoder().decode([Gun].self, from: savedGunsData), !decoded.isEmpty {
                ownedGuns = decoded
            } else {
                ownedGuns = []
            }
        }
    }

    private func categoryScrollView(groupedGuns: [String: [Gun]], categories: [String]) -> some View {
        let columns: [GridItem] = [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ]

        return LazyVGrid(columns: columns, spacing: 16) {
            ForEach(0..<categories.count, id: \.self) { (index: Int) in
                let category = categories[index]

                NavigationLink(destination: CategoryDetailView(category: category, ownedGuns: $ownedGuns, onRemove: { gun in
                    ownedGuns.removeAll { $0.identityKey == gun.identityKey }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    reloadOwnedGuns()
                })) {
                    VStack(alignment: .leading, spacing: 8) {
                        if let iconName = iconNames[category] {
                            Image(iconName)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity, maxHeight: 60)
                                .padding(.bottom, 4)
                        }

                        Text(category)
                            .font(.headline)
                            .foregroundColor(.black)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                            .multilineTextAlignment(.leading)

                        Text("登録数: \(groupedGuns[category]?.count ?? 0)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color(red: 245/255, green: 245/255, blue: 245/255))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                }
            }
        }
        .padding(.top)
        .padding(.horizontal)
    }

    private func reloadOwnedGuns() {
        if let decoded = try? JSONDecoder().decode([Gun].self, from: savedGunsData) {
            ownedGuns = decoded
        }
    }

}

struct CategoryDetailView: View {
    let category: String
    @Binding var ownedGuns: [Gun]
    let onRemove: (Gun) -> Void
    @AppStorage("journalEntries") private var savedJournalEntriesData: Data = Data()

    private var journalEntries: [JournalEntry] {
        (try? JSONDecoder().decode([JournalEntry].self, from: savedJournalEntriesData)) ?? []
    }

    private var guns: [Gun] {
        var seen = Set<String>()
        var unique: [Gun] = []
        for g in ownedGuns where g.type == category {
            if !seen.contains(g.identityKey) {
                seen.insert(g.identityKey)
                unique.append(g)
            }
        }
        return unique
    }

    private func usageCount(for gun: Gun) -> Int {
        journalEntries.reduce(0) { count, entry in
            count + entry.weapons.filter { $0 == gun.name }.count
        }
    }

    var body: some View {
        VStack {
            Spacer(minLength: 0)
            if guns.isEmpty {
                VStack(spacing: 24) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.gray.opacity(0.6))
                    Text("武器が登録されていません")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(guns, id: \.identityKey) { gun in
                        let count = usageCount(for: gun)
                        HStack(spacing: 12) {
                            if let imageUrl = gun.imageURLValue {
                                ForegroundCutoutImage(imageUrl: imageUrl)
                                    .frame(width: 70, height: 70)
                            } else {
                                Color.clear.frame(width: 70, height: 70)
                            }
                            VStack(alignment: .leading, spacing: 8) {
                                Text(gun.name)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)

                                Text("使用回数: \(count)回")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: 140)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 12)
                            }
                            Spacer()
                        }
                        .frame(height: 60)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.gray.opacity(0.8), Color.black],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 2, y: 2)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .padding(.horizontal)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                onRemove(gun)
                            } label: {
                                Label("削除", systemImage: "trash")
                            }
                            .tint(.red)
                        }
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
            }
            Spacer(minLength: 0)
        }
        .navigationTitle(category)
    }
}

struct WeaponSearchView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @State private var searchText: String = ""
    @State private var searchResults: [Gun] = []
    @State private var didSearch: Bool = false
    @State private var isLoading = false
    @Binding var ownedGuns: [Gun]
    let onWeaponAdded: (Gun) -> Void
    let onWeaponRemoved: (Gun) -> Void
    let dismiss: () -> Void
    
    @State private var isPresentingDetail: Bool = false
    @State private var selectedGun: Gun? = nil
    @GestureState private var isPressed = false

    private var searchResultsView: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(searchResults, id: \.identityKey) { gun in
                    Button(action: {
                        selectedGun = gun
                        isPresentingDetail = true
                    }) {
                        HStack(alignment: .center, spacing: 12) {
                            if let url = gun.imageURLValue {
                                ForegroundCutoutImage(imageUrl: url)
                                    .frame(width: 60, height: 60)
                            } else {
                                Color.clear.frame(width: 60, height: 60)
                            }
                            Text(gun.name)
                                .font(.headline)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.leading)
                            Spacer()
                        }
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.gray.opacity(0.8), Color.black],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(10)
                        .scaleEffect(isPressed ? 0.95 : 1.0)
                        .animation(.spring(), value: isPressed)
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .updating($isPressed) { _, state, _ in state = true }
                    )
                }
            }
        }
    }

    private var emptyResultsView: some View {
        VStack {
            Spacer()
            Text("該当するものはありませんでした")
                .foregroundColor(.gray)
            Spacer()
        }
    }
    
    private var mainContentView: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        TextField("会社名や名前を入力", text: $searchText, onCommit: {
                            self.performSearch()
                        })
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .padding(10)
                        .background(colorScheme == .dark ? Color.black : Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(colorScheme == .dark ? Color.white : Color.black, lineWidth: 1)
                        )
                        .placeholder(when: searchText.isEmpty) {
                            Text("会社名や名前を入力")
                                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.5) : Color.black.opacity(0.5))
                                .background(colorScheme == .dark ? Color.black : Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(colorScheme == .dark ? Color.white : Color.black, lineWidth: 1)
                                )
                        }
                    }
                    
                    if searchResults.isEmpty && didSearch {
                        emptyResultsView
                    } else {
                        searchResultsView
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.horizontal)
                
                if isLoading {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                    ProgressView()
                        .scaleEffect(1.6)
                }
            }
            .fullScreenCover(item: $selectedGun) { gun in
                WeaponDetailView(
                    gun: gun,
                    ownedGuns: ownedGuns,
                    onAdd: {
                        onWeaponAdded(gun)
                        self.selectedGun = nil
                        self.isPresentingDetail = false
                        dismiss()
                    },
                    onRemove: {
                        onWeaponRemoved(gun)
                        self.selectedGun = nil
                        self.isPresentingDetail = false
                        dismiss()
                    }
                )
            }
            .navigationTitle("武器検索")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }

    var body: some View {
        mainContentView
    }
    
    private func dedup(_ guns: [Gun]) -> [Gun] {
        var seen = Set<String>()
        var result: [Gun] = []
        for g in guns {
            if !seen.contains(g.identityKey) {
                seen.insert(g.identityKey)
                result.append(g)
            }
        }
        return result
    }

    private func performSearch() {
        guard !searchText.isEmpty else { return }
        isLoading = true
        didSearch = false

        guard let encodedQuery = searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://my-api-4aul.onrender.com/guns/search?q=\(encodedQuery)") else {
            print("❌ URL 構築に失敗")
            self.isLoading = false
            self.didSearch = true
            self.searchResults = []
            return
        }

        print("🌐 API呼び出し: \(url)")

        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                self.didSearch = true
            }

            if let error = error {
                print("❌ API エラー: \(error)")
                DispatchQueue.main.async {
                    self.searchResults = []
                }
                return
            }

            guard let data = data else {
                print("❌ データなし")
                DispatchQueue.main.async {
                    self.searchResults = []
                }
                return
            }

            do {
                let decodedGuns = try JSONDecoder().decode([Gun].self, from: data)
                let uniqueResults = dedup(decodedGuns)
                DispatchQueue.main.async {
                    self.searchResults = uniqueResults
                    print("✅ Decoded guns: \(decodedGuns.count) → unique: \(uniqueResults.count)")
                    uniqueResults.prefix(10).forEach { gun in
                        print("• \(gun.name) [maker=\(gun.maker)] type=\(gun.type)")
                    }
                }
            } catch {
                print("❌ JSON デコード失敗: \(error)")
                DispatchQueue.main.async {
                    self.searchResults = []
                }
            }
        }.resume()
    }
    
    struct WeaponDetailView: View {
        let gun: Gun
        let ownedGuns: [Gun]
        let onAdd: () -> Void
        let onRemove: () -> Void
        @Environment(\.presentationMode) var presentationMode
        @State private var cardOffsetY: CGFloat = 0
        
        var body: some View {
            NavigationView {
                ZStack {
                    Color(UIColor.systemBackground)
                        .ignoresSafeArea()

                    VStack(spacing: 12) {
                        Spacer().frame(height: 10)
                        if let url = gun.imageURLValue {
                            ZStack {
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .fill(.regularMaterial)
                                    .shadow(radius: 8)
                                    .frame(
                                        width: UIScreen.main.bounds.width * 0.9,
                                        height: UIScreen.main.bounds.height * 0.5
                                    )
                                VStack(spacing: 10) {
                                    if gun.type == "グレネード" || gun.type == "その他" {
                                        ForegroundCutoutImage(imageUrl: url)
                                            .frame(height: 200)
                                            .clipped()
                                    } else {
                                        ForegroundCutoutImage(imageUrl: url)
                                            .frame(width: UIScreen.main.bounds.width * 0.9)
                                            .clipped()
                                    }

                                    Text(gun.name)
                                        .font(.title)

                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("種類: \(gun.type)")
                                            .font(.body)
                                            .foregroundColor(.primary)
                                        Text("メーカー: \(gun.maker)")
                                            .font(.body)
                                            .foregroundColor(.primary)
                                        if let rating = gun.ageRating {
                                            Text("対象年齢: \(rating)歳以上")
                                                .font(.body)
                                                .foregroundColor(.primary)
                                        }
                                        if let site = gun.siteURL {
                                            let normalizedSite = site.starts(with: "http") ? site : "https://\(site)"
                                            if let url = URL(string: normalizedSite) {
                                                Link("公式サイトを見る", destination: url)
                                                    .font(.body)
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.vertical)
                            .offset(y: cardOffsetY)
                            .animation(.spring(), value: cardOffsetY)
                            Spacer().frame(height: 20)
                        }
                        Spacer()
                    }
                    VStack {
                        Spacer()
                        SwipeToAddButton(
                            isAlreadyAdded: ownedGuns.contains(where: { $0.id == gun.id && $0.name == gun.name && $0.maker == gun.maker }),
                            onAdd: {
                                onAdd()
                                presentationMode.wrappedValue.dismiss()
                            },
                            onRemove: {
                                onRemove()
                                presentationMode.wrappedValue.dismiss()
                            },
                            onProgress: { progress in
                                cardOffsetY = -progress * (UIScreen.main.bounds.height * 0.25)
                            }
                        )
                        .padding(.bottom, 30)
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("戻る") {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }
        }
    }
    
    struct SwipeToAddButton: View {
        let isAlreadyAdded: Bool
        let onAdd: (() -> Void)?
        let onRemove: (() -> Void)?
        let onProgress: ((CGFloat) -> Void)?
        @State private var offset: CGFloat = 0
        private let railWidth: CGFloat = 340
        private let railHeight: CGFloat = 90
        private let circleSize: CGFloat = 74
        private let padding: CGFloat = 8

        var body: some View {
            let maxOffset: CGFloat = railWidth - circleSize - padding*2
            let normalized: CGFloat = max(0, min(offset / maxOffset, 1))
            let knobOffsetLeft: CGFloat  = -(offset - (railWidth/2) + (circleSize/2) + padding)
            let knobOffsetRight: CGFloat =  (offset - (railWidth/2) + (circleSize/2) + padding)
            let knobOffset: CGFloat = isAlreadyAdded ? knobOffsetLeft : knobOffsetRight
            let textOffset: CGFloat = isAlreadyAdded ? -30 : 30

            onProgress?(normalized)

            return ZStack {
                Capsule()
                    .fill(Color.primary.opacity(0.1))
                    .frame(width: railWidth, height: railHeight)

                Text(isAlreadyAdded ? "スワイプして削除" : "スワイプして追加")
                    .foregroundColor(.primary)
                    .font(.headline)
                    .opacity(1.0 - normalized)
                    .offset(x: textOffset)

                Circle()
                    .fill(isAlreadyAdded ? Color.red : Color.accentColor)
                    .frame(width: circleSize, height: circleSize)
                    .overlay(
                        Image(systemName: isAlreadyAdded ? "arrow.left" : "arrow.right")
                            .foregroundColor(.white)
                            .font(.system(size: 28, weight: .bold))
                    )
                    .offset(x: knobOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newOffset = max(0, min(abs(value.translation.width), maxOffset))
                                offset = newOffset
                            }
                            .onEnded { _ in
                                if offset > maxOffset - 8 {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    if isAlreadyAdded {
                                        onRemove?()
                                    } else {
                                        onAdd?()
                                    }
                                }
                                withAnimation { offset = 0 }
                            }
                    )
            }
            .frame(width: railWidth, height: railHeight)
            .padding()
        }
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            if shouldShow {
                placeholder()
            }
            self
        }
    }
}

extension Text {
    func outlinedText(strokeColor: Color = .black, strokeWidth: CGFloat = 2) -> some View {
        ZStack {
            self.foregroundColor(strokeColor).offset(x: strokeWidth, y: 0)
            self.foregroundColor(strokeColor).offset(x: -strokeWidth, y: 0)
            self.foregroundColor(strokeColor).offset(x: 0, y: strokeWidth)
            self.foregroundColor(strokeColor).offset(x: 0, y: -strokeWidth)
            self.foregroundColor(strokeColor).offset(x: strokeWidth, y: strokeWidth)
            self.foregroundColor(strokeColor).offset(x: strokeWidth, y: -strokeWidth)
            self.foregroundColor(strokeColor).offset(x: -strokeWidth, y: strokeWidth)
            self.foregroundColor(strokeColor).offset(x: -strokeWidth, y: -strokeWidth)
            self
        }
    }
}

