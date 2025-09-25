import SwiftUI

struct TodayView: View {
    @State private var userName: String = "User"
    @State private var playCount: Int = 0
    @State private var userIcon: String = "person.circle.fill"
    @State private var isShowingMyCardDetail = false

    var body: some View {
        VStack {
            mainContent
        }
        .sheet(isPresented: $isShowingMyCardDetail) {
            MyCardDetailView(
                userName: $userName,
                userIcon: $userIcon,
                playCount: $playCount,
                isPresented: $isShowingMyCardDetail
            )
        }
    }

    var mainContent: some View {
        MyCardView(
            userName: userName,
            userIcon: userIcon,
            playCount: playCount,
            onTap: {
                isShowingMyCardDetail = true
            }
        )
    }
}

struct MyCardView: View {
    let userName: String
    let userIcon: String
    let playCount: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: userIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 48, height: 48)
                    .foregroundColor(.blue)
                VStack(alignment: .leading, spacing: 4) {
                    Text(userName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Play Count: \(playCount)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MyCardDetailView: View {
    @Binding var userName: String
    @Binding var userIcon: String
    @Binding var playCount: Int
    @Binding var isPresented: Bool

    @State private var editedUserName: String = ""
    @State private var selectedIcon: String = ""
    @State private var editedPlayCount: String = ""

    private let availableIcons = [
        "person.circle.fill",
        "star.circle.fill",
        "heart.circle.fill",
        "bolt.circle.fill",
        "leaf.circle.fill"
    ]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("User Info")) {
                    TextField("User Name", text: $editedUserName)
                    Picker("Icon", selection: $selectedIcon) {
                        ForEach(availableIcons, id: \.self) { icon in
                            HStack {
                                Image(systemName: icon)
                                    .foregroundColor(.blue)
                                Text(icon)
                            }
                            .tag(icon)
                        }
                    }
                    TextField("Play Count", text: $editedPlayCount)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("My Card Detail")
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                },
                trailing: Button("Save") {
                    userName = editedUserName.trimmingCharacters(in: .whitespaces)
                    userIcon = selectedIcon
                    if let count = Int(editedPlayCount) {
                        playCount = count
                    }
                    isPresented = false
                }
                .disabled(editedUserName.trimmingCharacters(in: .whitespaces).isEmpty)
            )
            .onAppear {
                editedUserName = userName
                selectedIcon = userIcon
                editedPlayCount = String(playCount)
            }
        }
    }
}
