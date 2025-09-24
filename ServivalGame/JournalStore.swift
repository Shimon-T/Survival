// JournalStore.swift
// 共通の記録（エントリー）配列を管理し、UserDefaultsに永続化するObservableObject

import Foundation
import Combine

struct JournalEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    let fieldName: String
    let gameContent: String
    let weapons: [String]
}

class JournalStore: ObservableObject {
    @Published var entries: [JournalEntry] = [] {
        didSet {
            saveEntries()
        }
    }
    private let userDefaultsKey = "JournalEntries"
    
    init() {
        loadEntries()
    }
    
    private func saveEntries() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    private func loadEntries() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode([JournalEntry].self, from: data) else {
            self.entries = []
            return
        }
        self.entries = decoded
    }
    
    func add(_ entry: JournalEntry) {
        entries.append(entry)
    }
    func remove(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        if entries.isEmpty {
            UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        }
    }
}

