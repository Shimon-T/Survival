import SwiftUI

struct JournalView: View {
    @State private var entries: [JournalEntry] = []
    @State private var isShowingAddEntry = false
    @State private var isShowingEditEntry = false
    @State private var editTargetIndex: Int? = nil
    @State private var expandedEntryID: UUID? = nil

    // Fields for new entry and editing (shared)
    @State private var fieldName: String = ""
    @State private var date: Date = Date()
    let gameModes = ["フラッグ戦", "殲滅戦", "占領戦", "カウンター戦", "ポリタンク輸送戦", "大統領選", "カスタム(自分で入力)"]
    @State private var selectedGameMode: String = "フラッグ戦"
    @State private var customGameContent: String = ""
    @State private var selectedWeapons: [String] = []
    @State private var weaponQuery: String = ""
    @State private var searchResults: [Gun] = []
    @State private var isSearchingWeapons: Bool = false
    @State private var searchHint: String = ""
    @State private var lastSearchedKeyword: String = ""
    @State private var lastSearchError: String? = nil
    @State private var weaponSearchTask: Task<Void, Never>? = nil

    @State private var result: GameResult = .unknown

    @AppStorage("savedGuns") private var savedGunsData: Data = Data()
    @AppStorage("journalEntries") private var savedJournalEntriesData: Data = Data()
    @State private var ownedGuns: [Gun] = []

    init(startWithAddEntry: Bool = false) {
        _isShowingAddEntry = State(initialValue: startWithAddEntry)
    }

    var body: some View {
        NavigationView {
            Group {
                if entries.isEmpty {
                    List {
                        Section {
                            VStack {
                                Spacer(minLength: 120)
                                Text("記録がまだありません")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                Spacer(minLength: 120)
                            }
                            .frame(maxWidth: .infinity)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                        .foregroundColor(.white)
                    }
                    .listStyle(.plain)
                } else {
                    List {
                        ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(entry.fieldName)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text(entry.date, style: .date)
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                if expandedEntryID == entry.id {
                                    Divider()
                                    Text("勝敗: \(entry.result.rawValue)")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                    if !entry.gameContent.isEmpty {
                                        Text("ゲーム内容: \(entry.gameContent)")
                                            .font(.subheadline)
                                            .foregroundColor(.white)
                                    }
                                    if !entry.weapons.isEmpty {
                                        Text("武器: \(entry.weapons.joined(separator: "、"))")
                                            .font(.subheadline)
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .padding(.vertical, expandedEntryID == entry.id ? 10 : 4)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation {
                                    expandedEntryID = (expandedEntryID == entry.id) ? nil : entry.id
                                }
                            }
                            .onLongPressGesture {
                                editTargetIndex = index
                                loadEntryForEditing(entry: entry)
                                isShowingEditEntry = true
                            }
                            .listRowBackground(Color.clear)
                        }
                        .onDelete(perform: deleteEntries)
                    }
                    .listStyle(.plain)
                }
            }
            .scrollContentBackground(.hidden)
            .background(
                ZStack {
                    Image("BackGround_j")
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                }
            )
//            .navigationTitle("記録")
//            .toolbarColorScheme(.dark)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("記録")
                        .foregroundColor(.white)
                        .font(.title)
                }
            }
            .toolbarBackground(Color.clear, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { prepareNewEntry(); isShowingAddEntry = true }) {
                        HStack {
                            Image(systemName: "square.and.pencil")
                            Text("記録")
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
        .onAppear {
            if let decoded = try? JSONDecoder().decode([Gun].self, from: savedGunsData) {
                ownedGuns = decoded
            }
            if let decodedEntries = try? JSONDecoder().decode([JournalEntry].self, from: savedJournalEntriesData) {
                entries = decodedEntries
            }
        }
        // Add Entry Sheet
        .sheet(isPresented: $isShowingAddEntry) {
            NavigationView {
                entryFormView(
                    onCancel: {
                        resetEntryFields()
                        isShowingAddEntry = false
                    },
                    onSave: {
                        let content = selectedGameMode == "カスタム(自分で入力)" ? customGameContent : selectedGameMode
                        let entry = JournalEntry(
                            id: UUID(),
                            date: date,
                            fieldName: fieldName,
                            gameContent: content,
                            weapons: selectedWeapons,
                            result: result
                        )
                        entries.append(entry)
                        persistEntries()
                        resetEntryFields()
                        isShowingAddEntry = false
                    },
                    saveDisabled: fieldName.isEmpty,
                    onDelete: nil
                )
                .navigationTitle("記録を追加")
                .foregroundColor(.white)
            }
        }
        // Edit Entry Sheet
        .sheet(isPresented: $isShowingEditEntry) {
            NavigationView {
                entryFormView(
                    onCancel: {
                        resetEntryFields()
                        isShowingEditEntry = false
                        editTargetIndex = nil
                    },
                    onSave: {
                        guard let index = editTargetIndex else { return }
                        let content = selectedGameMode == "カスタム(自分で入力)" ? customGameContent : selectedGameMode
                        let editedEntry = JournalEntry(
                            id: entries[index].id,
                            date: date,
                            fieldName: fieldName,
                            gameContent: content,
                            weapons: selectedWeapons,
                            result: result
                        )
                        entries[index] = editedEntry
                        persistEntries()
                        resetEntryFields()
                        isShowingEditEntry = false
                        editTargetIndex = nil
                    },
                    saveDisabled: fieldName.isEmpty,
                    onDelete: {
                        if let index = editTargetIndex {
                            entries.remove(at: index)
                            persistEntries()
                            resetEntryFields()
                            isShowingEditEntry = false
                            editTargetIndex = nil
                        }
                    }
                )
                .navigationTitle("記録を編集")
                .foregroundColor(.white)
            }
        }
    }

    private func deleteEntries(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        persistEntries()
    }

    private func loadEntryForEditing(entry: JournalEntry) {
        fieldName = entry.fieldName
        selectedWeapons = entry.weapons
        weaponQuery = ""
        searchResults = []
        date = entry.date
        result = entry.result
        if gameModes.contains(entry.gameContent) {
            selectedGameMode = entry.gameContent
            customGameContent = ""
        } else {
            selectedGameMode = "カスタム(自分で入力)"
            customGameContent = entry.gameContent
        }
    }

    private func prepareNewEntry() {
        resetEntryFields()
    }

    private func resetEntryFields() {
        fieldName = ""
        date = Date()
        selectedGameMode = "フラッグ戦"
        customGameContent = ""
        selectedWeapons = []
        weaponQuery = ""
        searchResults = []
        lastSearchedKeyword = ""
        lastSearchError = nil
        searchHint = ""
        weaponSearchTask?.cancel()
        weaponSearchTask = nil
        result = .unknown
    }

    private func persistEntries() {
        if let data = try? JSONEncoder().encode(entries) {
            savedJournalEntriesData = data
        }
    }

    @MainActor
    private func queryWeapons(keyword: String) async {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        lastSearchedKeyword = trimmed
        lastSearchError = nil
        guard !trimmed.isEmpty else { self.searchResults = []; return }

        isSearchingWeapons = true
        defer { isSearchingWeapons = false }

        let baseURL = "https://my-api-4aul.onrender.com/guns/search"
        guard var components = URLComponents(string: baseURL) else {
            self.lastSearchError = "検索URLの生成に失敗しました"
            return
        }
        components.queryItems = [URLQueryItem(name: "q", value: trimmed)]

        guard let url = components.url else {
            self.lastSearchError = "検索URLが無効です"
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                self.lastSearchError = "サーバーエラー"
                return
            }

            let decoded = try JSONDecoder().decode([Gun].self, from: data)
            let filtered = decoded.filter { !selectedWeapons.contains($0.name) }
            self.searchResults = Array(filtered.prefix(20))
        } catch {
            self.lastSearchError = "検索に失敗しました"
            self.searchResults = []
        }
    }

    @ViewBuilder
    private func entryFormView(
        onCancel: @escaping () -> Void,
        onSave: @escaping () -> Void,
        saveDisabled: Bool,
        onDelete: (() -> Void)? = nil
    ) -> some View {
        Form {
            Section(header: Text("フィールド名").foregroundColor(.white)) {
                TextField("例: フィールドABC", text: $fieldName)
                    .autocapitalization(.none)
                    .foregroundColor(.white)
            }
            Section(header: Text("日付").foregroundColor(.white)) {
                DatePicker("日付", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(.white)
            }
            Section(header: Text("ゲーム内容").foregroundColor(.white)) {
                Picker("ゲーム内容を選択", selection: $selectedGameMode) {
                    ForEach(gameModes, id: \.self) { Text($0).foregroundColor(.white) }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if selectedGameMode == "カスタム(自分で入力)" {
                    TextField("カスタム内容を入力", text: $customGameContent)
                        .autocapitalization(.none)
                        .foregroundColor(.white)
                }
            }
            Section(header: Text("勝敗").foregroundColor(.white)) {
                Picker("勝敗", selection: $result) {
                    ForEach(GameResult.allCases) { r in
                        Text(r.rawValue).tag(r)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            Section(header: Text("使用武器").foregroundColor(.white)) {
                // Owned guns quick-pick (same as before, but add to multi-select)
                if !ownedGuns.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(ownedGuns) { gun in
                                Button(action: {
                                    if !selectedWeapons.contains(gun.name) { selectedWeapons.append(gun.name) }
                                }) {
                                    HStack {
                                        if let imageURLString = gun.imageURL,
                                           let imageURL = URL(string: imageURLString) {
                                            AsyncImage(url: imageURL) { image in
                                                image
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 36, height: 24)
                                                    .cornerRadius(5)
                                            } placeholder: {
                                                Color.gray
                                                    .frame(width: 36, height: 24)
                                                    .cornerRadius(5)
                                            }
                                        }
                                        Text(gun.name).font(.caption).foregroundColor(.white)
                                    }
                                    .padding(6)
                                    .background(Color.gray.opacity(0.18))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                } else {
                    Text("もしも装備品が表示されない場合は一度装備タブを読み込んでください")
                        .foregroundColor(.white)
                }

                // Selected weapons chips with tap-to-remove
                if !selectedWeapons.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(selectedWeapons, id: \.self) { name in
                                Button(action: { selectedWeapons.removeAll { $0 == name } }) {
                                    Text(name)
                                        .font(.caption)
                                        .padding(6)
                                        .background(Color.gray.opacity(0.25))
                                        .cornerRadius(8)
                                        .foregroundColor(.white)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(Text("選択武器 \(name)"))
                                .accessibilityHint(Text("タップで削除"))
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }

                // Search field (like equipment tab) + API-driven suggestions
                VStack(alignment: .leading, spacing: 6) {
                    TextField("名前で検索 (例: M4, グロック)", text: $weaponQuery)
                        .autocapitalization(.none)
                        .foregroundColor(.white)
                        .onSubmit {
                            let trimmed = weaponQuery.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            Task {
                                await queryWeapons(keyword: trimmed)
                                // 送信語と完全一致する候補があれば即追加、なければ候補から選んでもらう
                                if let exact = searchResults.first(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) {
                                    if !selectedWeapons.contains(exact.name) { selectedWeapons.append(exact.name) }
                                    weaponQuery = ""
                                    searchResults = []
                                    searchHint = ""
                                } else {
                                    searchHint = "候補から選んで追加してください"
                                }
                            }
                        }
                        .onChange(of: weaponQuery) { newValue in
                            searchHint = ""
                            weaponSearchTask?.cancel()
                            let query = newValue
                            weaponSearchTask = Task { [query] in
                                try? await Task.sleep(nanoseconds: 250_000_000)
                                guard !Task.isCancelled else { return }
                                await queryWeapons(keyword: query)
                            }
                        }

                    if !searchHint.isEmpty {
                        Text(searchHint)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }

                    if isSearchingWeapons {
                        ProgressView("検索中…")
                            .foregroundColor(.white)
                    }
                    if !isSearchingWeapons && !searchResults.isEmpty {
                        Text("候補数: \(searchResults.count)")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }

                    // Error message
                    if let err = lastSearchError, !err.isEmpty {
                        Text(err)
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    // No results message and fallback add button
                    if !isSearchingWeapons && !weaponQuery.isEmpty && searchResults.isEmpty && lastSearchError == nil {
                        Text("候補は見つかりませんでした（\(lastSearchedKeyword)）")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        Button(action: {
                            let trimmed = weaponQuery.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            if !selectedWeapons.contains(trimmed) { selectedWeapons.append(trimmed) }
                            weaponQuery = ""
                            searchResults = []
                            searchHint = ""
                        }) {
                            Text("この名前で追加する")
                                .foregroundColor(.white)
                        }
                    }

                    if !searchResults.isEmpty {
                        // Show suggestions list
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(searchResults) { gun in
                                Button(action: {
                                    if !selectedWeapons.contains(gun.name) { selectedWeapons.append(gun.name) }
                                    weaponQuery = ""
                                    searchResults = []
                                }) {
                                    HStack(spacing: 10) {
                                        if let imageURLString = gun.imageURL, let url = URL(string: imageURLString) {
                                            AsyncImage(url: url) { image in
                                                image.resizable().scaledToFit().frame(width: 48, height: 32).cornerRadius(6)
                                            } placeholder: {
                                                Color.gray.frame(width: 48, height: 32).cornerRadius(6)
                                            }
                                        }
                                        Text(gun.name)
                                            .font(.subheadline)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                                .buttonStyle(.plain)
                                .padding(.vertical, 4)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
            }
            if let onDelete = onDelete {
                Section {
                    Button("削除", role: .destructive, action: onDelete)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundColor(.white)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("キャンセル", action: onCancel)
                    .foregroundColor(.white)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存", action: onSave)
                    .disabled(saveDisabled)
                    .foregroundColor(.white)
            }
        }
    }
}
