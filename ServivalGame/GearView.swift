//
//  GearView.swift
//  ServivalGame
//
//  Created by 田中志門 on 6/1/25.
//

import SwiftUI

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

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {

                let groupedGuns = Dictionary(grouping: ownedGuns) { $0.category }
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
                        onWeaponAdded: { gun in
                            var categorizedGun = gun
                            if gun.category == "アサルトライフル" {
                                categorizedGun = Gun(id: gun.id, name: gun.name, imageURL: gun.imageURL, category: "アサルト")
                            } else if gun.category == "スナイパーライフル" {
                                categorizedGun = Gun(id: gun.id, name: gun.name, imageURL: gun.imageURL, category: "ライフル")
                            } else if gun.category == "SMG" || gun.category == "サブマシンガン" {
                                categorizedGun = Gun(id: gun.id, name: gun.name, imageURL: gun.imageURL, category: "その他")
                            }
                            ownedGuns.append(categorizedGun)
                        },
                        dismiss: {
                            isPresentingSearch = false
                        }
                    )
                }
            }
            .padding()
            .navigationTitle("装備")
        }
        .onAppear {
            if let decoded = try? JSONDecoder().decode([Gun].self, from: savedGunsData) {
                ownedGuns = decoded
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

                NavigationLink(destination: CategoryDetailView(category: category, guns: groupedGuns[category] ?? [])) {
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

    func fetchGuns(matching keyword: String) {
        let escaped = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "https://my-api-4aul.onrender.com/guns/search?q=\(escaped)") else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else { return }
            _ = try? JSONDecoder().decode([Gun].self, from: data)
        }.resume()
    }
}

struct CategoryDetailView: View {
    let category: String
    let guns: [Gun]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                // VStack(alignment: .leading, spacing: 8) {
                //     Text("\(category)の装備")
                //         .font(.largeTitle)
                // }
                // .padding()
                EmptyView()

                if guns.isEmpty {
                    // Text("武器が登録されていません")
                    //     .foregroundColor(.gray)
                    //     .padding()
                    EmptyView()
                } else {
                    ForEach(guns) { gun in
                        HStack {
                            if let imageUrl = gun.imageURL {
                                AsyncImage(url: imageUrl) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 60, height: 60)
                                        .clipShape(RoundedRectangle(cornerRadius: 50))
<<<<<<< HEAD
                                        .overlay(RoundedRectangle(cornerRadius: 50).stroke(Color.gray, lineWidth: 2))
=======
>>>>>>> 804559e97eee42438a52a73468e722050fcc63be
                                } placeholder: {
                                    ProgressView()
                                }
                            }
                            Text(gun.name)
                                .font(.headline)
                            Spacer()
                        }
                        .padding()
                        .background(Color(red: 245/255, green: 245/255, blue: 245/255))
                        .cornerRadius(12)
                        .shadow(radius: 1)
                        .padding(.horizontal)
                    }
                }
            }
        }
        .navigationTitle(category)
    }
}

struct Gun: Identifiable, Codable {
    let id: String
    let name: String
    let imageURL: URL?
    let category: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case imageURL
        case category = "type"
    }
}

struct WeaponSearchView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @State private var searchText: String = ""
    @State private var searchResults: [Gun] = []
    @State private var didSearch: Bool = false
    let onWeaponAdded: (Gun) -> Void
    let dismiss: () -> Void

    @State private var isPresentingDetail: Bool = false
    @State private var selectedGun: Gun? = nil

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        TextField("会社名や名前を入力", text: $searchText, onCommit: {
                            performSearch()
                        })
<<<<<<< HEAD
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
=======
                        .foregroundColor(.black)
                        .padding(10)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.black, lineWidth: 1)
                        )
                        .placeholder(when: searchText.isEmpty) {
                            Text("会社名や名前を入力")
                                .foregroundColor(.gray)
>>>>>>> 804559e97eee42438a52a73468e722050fcc63be
                                .padding(10)
                        }

                        Button(action: {
                            print("🔘 検索ボタンがタップされました")
                            performSearch()
                        }) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .padding(10)
                        }
<<<<<<< HEAD
                        .background(colorScheme == .dark ? Color.black : Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(colorScheme == .dark ? Color.white : Color.black, lineWidth: 1)
=======
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.black, lineWidth: 1)
>>>>>>> 804559e97eee42438a52a73468e722050fcc63be
                        )
                    }

                    if searchResults.isEmpty && didSearch {
                        Spacer()
                        Text("該当するものはありませんでした")
                            .foregroundColor(.gray)
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(searchResults) { gun in
                                    Button(action: {
                                        // Present detail view modally
                                        selectedGun = gun
                                        isPresentingDetail = true
                                    }) {
                                        HStack {
                                            if let url = gun.imageURL {
                                                AsyncImage(url: url) { image in
                                                    image
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fit)
                                                        .frame(width: 60, height: 60)
                                                        .clipShape(RoundedRectangle(cornerRadius: 50))
<<<<<<< HEAD
                                                        .overlay(RoundedRectangle(cornerRadius: 50).stroke(Color.gray, lineWidth: 2))
=======
>>>>>>> 804559e97eee42438a52a73468e722050fcc63be
                                                } placeholder: {
                                                    ProgressView()
                                                }
                                            }
                                            Text(gun.name)
                                                .font(.headline)
                                                .foregroundColor(.black)
                                            Spacer()
                                        }
                                        .padding()
                                        .background(Color(red: 245/255, green: 245/255, blue: 245/255))
                                        .cornerRadius(10)
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
                .padding()
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
        .fullScreenCover(item: $selectedGun) { gun in
            WeaponDetailView(
                gun: gun,
                onAdd: {
                    onWeaponAdded(gun)
                    self.selectedGun = nil
                    self.isPresentingDetail = false
                    dismiss()
                }
            )
        }
    }

    func performSearch() {
        print("🔎 検索ボタンを押しました: \(searchText)")
        let escaped = searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://my-api-4aul.onrender.com/guns/search?q=\(escaped)"
        print("検索URL: \(urlString)")
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("検索エラー: \(error.localizedDescription)")
                return
            }
            guard let data = data else {
                print("データがありません")
                return
            }

            if let jsonString = String(data: data, encoding: .utf8) {
                print("📦 APIからのレスポンス: \(jsonString)")
            }

            do {
                let guns = try JSONDecoder().decode([Gun].self, from: data)
                DispatchQueue.main.async {
                    searchResults = guns
                    didSearch = true
                    print("取得した武器数: \(guns.count)")
                }
            } catch {
                print("デコード失敗: \(error.localizedDescription)")
            }
        }.resume()
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

struct WeaponDetailView: View {
    let gun: Gun
    let onAdd: () -> Void
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ZStack {
<<<<<<< HEAD
                Color(UIColor.systemBackground)
=======
                Color.white
>>>>>>> 804559e97eee42438a52a73468e722050fcc63be
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    if let url = gun.imageURL {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
<<<<<<< HEAD
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 50))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 50)
                                        .stroke(Color.gray, lineWidth: 2)
                                )
=======
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 50))
>>>>>>> 804559e97eee42438a52a73468e722050fcc63be
                        } placeholder: {
                            ProgressView()
                        }
                    }

                    Text(gun.name)
                        .font(.title)
                        .padding()

                    SwipeToAddButton {
                        onAdd()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .padding()
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
    let onAdd: () -> Void
    @State private var offset: CGFloat = 0
    @State private var didAnimate: Bool = false
    @State private var animationTimer: Timer?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
<<<<<<< HEAD
                .fill(Color.primary)
                .frame(height: 60)
            Text("スワイプして追加")
                .foregroundColor(Color(UIColor.systemBackground))
=======
                .fill(Color(UIColor { traitCollection in
                    return traitCollection.userInterfaceStyle == .dark ? UIColor.white : UIColor.black
                }))
                .frame(height: 60)
            Text("スワイプして追加")
                .foregroundColor(Color(UIColor { traitCollection in
                    return traitCollection.userInterfaceStyle == .dark ? UIColor.black : UIColor.white
                }))
>>>>>>> 804559e97eee42438a52a73468e722050fcc63be
        }
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    offset = max(0, gesture.translation.width)
                }
                .onEnded { gesture in
                    if gesture.translation.width > 80 {
                        withAnimation(.spring()) {
                            offset = UIScreen.main.bounds.width
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onAdd()
                            offset = 0
                        }
                    } else {
                        withAnimation {
                            offset = 0
                        }
                    }
                }
        )
        .offset(x: offset)
        .onAppear {
            guard !didAnimate else { return }
            didAnimate = true

            startBounceAnimation()
            animationTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                startBounceAnimation()
            }
        }
        .onDisappear {
            animationTimer?.invalidate()
            animationTimer = nil
        }
        .animation(.spring(), value: offset)
    }

    private func startBounceAnimation() {
        guard offset == 0 else { return } // prevent animating if swipe has started

        withAnimation(Animation.easeInOut(duration: 0.4)) {
            offset = 20
        }
<<<<<<< HEAD
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
=======
        DispatchQuçeue.main.asyncAfter(deadline: .now() + 0.4) {
>>>>>>> 804559e97eee42438a52a73468e722050fcc63be
            withAnimation(Animation.easeInOut(duration: 0.3)) {
                offset = 0
            }
        }
    }
}
<<<<<<< HEAD

=======
>>>>>>> 804559e97eee42438a52a73468e722050fcc63be
