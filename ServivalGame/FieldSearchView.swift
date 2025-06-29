import SwiftUI
import MapKit
import CoreLocation

struct FieldSearchView: View {
    @State private var sheetOffset: CGFloat = UIScreen.main.bounds.height * 0.35
    @GestureState private var dragOffset = CGFloat.zero
    @State private var searchText = ""
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 35.681236, longitude: 139.767125), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)) // Default to Tokyo
    @StateObject private var locationManager = LocationManager()

    @State private var showFilterSheet = false
    @State private var isIndoor: Bool? = nil // nil=all, true=indoor, false=outdoor
    @State private var ageLimit: Int? = nil // nil=all, 10=10禁, 18=18禁

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                Map(coordinateRegion: $region, showsUserLocation: true)
                    .ignoresSafeArea(edges: .bottom)
                
                VStack(spacing: 16) {
                    Button(action: {
                        if let location = locationManager.lastLocation {
                            region.center = location.coordinate
                        }
                    }) {
                        Image(systemName: "location.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.blue)
                            .frame(width: 44, height: 44)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 4, y: 2)
                    }
                    Button(action: { showFilterSheet = true }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 24))
                            .foregroundColor(.primary)
                            .frame(width: 44, height: 44)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 4, y: 2)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.top, 10)
                .padding(.trailing, 10)
                .frame(maxWidth: .infinity, alignment: .topTrailing)
                
                GeometryReader { geometry in
                    let minHeight = geometry.size.height * 0.8
                    let maxHeight = geometry.size.height * 0.15
                    let maxSheetOffset = minHeight
                    
                    VStack {
                        Capsule()
                            .frame(width: 40, height: 6)
                            .foregroundColor(Color(.systemGray4))
                            .padding(.top, 8)
                            .padding(.bottom, 4)
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            TextField("フィールド名や場所で検索", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding(8)
                        }
                        .padding(.horizontal)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .padding(.bottom, 8)

                        // Placeholder for search results
                        if !searchText.isEmpty {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 12) {
                                    ForEach(0..<5) { i in
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(.systemGray5))
                                            .frame(height: 44)
                                            .overlay(
                                                Text("サンプル結果 \(i+1): \(searchText) - \(isIndoor == true ? "室内" : isIndoor == false ? "屋外" : "全て") / \(ageLimit == 10 ? "10禁" : ageLimit == 18 ? "18禁" : "全年齢")")
                                                    .foregroundColor(.primary)
                                                    .padding(.leading, 16), alignment: .leading
                                            )
                                    }
                                }
                                .padding(.horizontal)
                            }
                        } else {
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .offset(y: min(max(sheetOffset + dragOffset, maxHeight), maxSheetOffset))
                    .animation(.interactiveSpring(), value: sheetOffset + dragOffset)
                    .gesture(
                        DragGesture()
                            .updating($dragOffset) { value, state, _ in
                                state = value.translation.height
                            }
                            .onEnded { value in
                                let newOffset = sheetOffset + value.translation.height
                                let clamped = min(max(newOffset, maxHeight), maxSheetOffset)
                                withAnimation(.interactiveSpring()) {
                                    sheetOffset = clamped
                                }
                            }
                    )
                }
                .ignoresSafeArea(edges: .bottom)
            }
            .navigationTitle("フィールドを検索")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showFilterSheet) {
                NavigationView {
                    Form {
                        Section(header: Text("種類")) {
                            Picker("", selection: $isIndoor) {
                                Text("すべて").tag(nil as Bool?)
                                Text("室内").tag(true as Bool?)
                                Text("屋外").tag(false as Bool?)
                            }
                            .pickerStyle(.segmented)
                        }
                        Section(header: Text("年齢制限")) {
                            Picker("", selection: $ageLimit) {
                                Text("すべて").tag(nil as Int?)
                                Text("10禁").tag(10 as Int?)
                                Text("18禁").tag(18 as Int?)
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                    .navigationTitle("絞り込み")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("閉じる") { showFilterSheet = false }
                        }
                    }
                }
            }
        }
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var lastLocation: CLLocation?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.last
    }
}

#Preview {
    ContentView(selectedTab: 2)
}
