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
    @State private var ownedGuns: [Gun] = []
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
                                } placeholder: {
                                    ProgressView()
                                }
                            }
                            Text(gun.name)
                                .font(.headline)
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .navigationTitle(category)
    }
}

struct Gun: Identifiable, Decodable {
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
                Color.white
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 0) {
                        TextField("会社名や名前を入力", text: $searchText)
                            .foregroundColor(.black)
                            .placeholder(when: searchText.isEmpty) {
                                Text("会社名や名前を入力")
                                    .foregroundColor(.gray)
                            }
                            .padding(10)
                            .submitLabel(.search)
                        Button(action: {
                            print("🔘 検索ボタンがタップされました")
                            performSearch()
                        }) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.black)
                                .padding(10)
                                .frame(height: 40)
                        }
                        .contentShape(Rectangle())
                        .allowsHitTesting(true)
                    }
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black, lineWidth: 1)
                    )
                    .cornerRadius(12)
                    .onAppear {
                        print("🔍 検索画面を開きました")
                    }
                    .onSubmit {
                        performSearch()
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
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 20) {
                if let url = gun.imageURL {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 200)
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
    }
}

struct SwipeToAddButton: View {
    let onAdd: () -> Void
    @State private var offset: CGFloat = 0

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue)
                .frame(height: 60)
            Text("スワイプして追加")
                .foregroundColor(.white)
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
        .animation(.spring(), value: offset)
    }
}
  
