// JournalStore.swift
// 共通の記録（エントリー）配列を管理し、UserDefaultsに永続化するObservableObject

import Foundation
import Combine

enum GameResult: String, Codable, CaseIterable, Identifiable {
    case win = "勝利"
    case lose = "敗北"
    case draw = "引き分け"
    case unknown = "未記録"
    var id: String { self.rawValue }
}

struct JournalEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    let fieldName: String
    let gameContent: String
    let weapons: [String]
    let result: GameResult
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
