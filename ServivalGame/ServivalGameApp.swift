//
//  ServivalGameApp.swift
//  ServivalGame
//
//  Created by 田中志門 on 6/1/25.
//

import SwiftUI

@main
struct ServivalGameApp: App {
    @StateObject private var journalStore = JournalStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(journalStore)
        }
    }
}
