//
//  ContentView.swift
//  ServivalGame
//
//  Created by 田中志門 on 6/1/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    init(selectedTab: Int = 0) {
        _selectedTab = State(initialValue: selectedTab)
    }
    

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label("ホーム", systemImage: "house.fill")
                }
                .tag(0)

            GearView()
                .tabItem {
                    Label("装備", systemImage: "backpack.fill")
                }
                .tag(1)
            
            JournalView()
                .tabItem {
                    Label("記録", systemImage: "book.fill")
                }
                .tag(2)
            
            FieldSearchView()
                .tabItem {
                    Label("フィールド", systemImage: "map.fill")
                }
                .tag(3)
        }
    }
}

#Preview {
    ContentView()
}
