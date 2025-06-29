//
//  SettingView.swift
//  ServivalGame
//
//  Created by 田中志門 on 6/1/25.
//


import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("アカウント")) {
                    Text("ログイン情報やプロフィールの設定はここに表示されます。")
                }

                Section(header: Text("アプリ情報")) {
                    Text("beta 1.0")
                }
            }
            .navigationTitle("設定")
        }
    }
}
