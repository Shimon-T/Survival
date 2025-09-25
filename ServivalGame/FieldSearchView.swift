import SwiftUI
import MapKit
import CoreLocation
import Combine

struct Field: Identifiable, Decodable {
    let id: String
    let name: String
    let area: String
    let city: String
    let type: String
    let age: String
    let imageURL: String
    let latitude: Double
    let longitude: Double
}

struct FieldAnnotation: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let name: String
    let address: String
}

enum SheetState { case min, mid, max, other }

struct FieldSearchView: View {
    @State private var locationManager = CLLocationManager()
    @State private var locationDelegate: LocationDelegate? = nil
    @State private var coordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude: 35.6809591,
            longitude: 139.7673068
        ),
        latitudinalMeters: 10000,
        longitudinalMeters: 10000
    )
    @State private var userTrackingMode: MapUserTrackingMode = .follow
    @State private var lastKnownLocation: CLLocationCoordinate2D? = nil
    
    @State private var sheetOffset: CGFloat = 0
    @GestureState private var dragOffset: CGFloat = 0
    
    @State private var searchText: String = ""
    @State private var searchResults: [Field] = []
    @State private var allFields: [Field] = []
    
    @State private var searchCancellable: AnyCancellable? = nil
    
    @State private var isSearching: Bool = false
    
    @FocusState private var isSearchFieldFocused: Bool
    
    
    @State private var fieldAnnotations: [FieldAnnotation] = []
    
    @State private var selectedField: Field? = nil
    
    var body: some View {
        GeometryReader { geometry in
            let screenHeight = geometry.size.height
            let minHeight: CGFloat = 160
            let midHeight: CGFloat = screenHeight / 2
            let maxHeight: CGFloat = screenHeight * 0.95
            let currentOffset = sheetOffset + dragOffset
            let clampedOffset = max(minHeight, min(maxHeight, currentOffset))
            let sheetState: SheetState = {
                if abs(clampedOffset - minHeight) < 1 {
                    return .min
                } else if abs(clampedOffset - midHeight) < 1 {
                    return .mid
                } else if abs(clampedOffset - maxHeight) < 1 {
                    return .max
                } else {
                    return .other
                }
            }()

            ZStack(alignment: .topTrailing) {
                ZStack(alignment: .bottomTrailing) {
                    Map(
                        coordinateRegion: $coordinateRegion,
                        interactionModes: .all,
                        showsUserLocation: true,
                        userTrackingMode: $userTrackingMode,
                        annotationItems: fieldAnnotations
                    ) { annotation in
                        MapAnnotation(coordinate: annotation.coordinate) {
                            Button(action: {
                                if let field = (allFields + searchResults).first(where: { $0.id == annotation.id }) {
                                    selectedField = field
                                }
                            }) {
                                Image(systemName: "mappin")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 32, height: 32)
                                    .foregroundColor(.red)
                                    .shadow(radius: 4)
                                    .alignmentGuide(.top) { d in d[.bottom] }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .edgesIgnoringSafeArea(.all)
                    
                    VStack(spacing: 16) {
                        Capsule()
                            .frame(width: 40, height: 5)
                            .foregroundColor(Color.gray.opacity(0.5))
                            .padding(.top, 8)
                        
                        HStack {
                            TextField("フィールド検索", text: $searchText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .focused($isSearchFieldFocused)
                                .onSubmit {
                                    print("[DEBUG] onSubmit fired, searchText=\(searchText)")
                                    performFieldSearch()
                                }
                                .onChange(of: searchText) { newValue in
                                    if newValue.isEmpty {
                                        searchResults = []
                                        loadAllFields()
                                    }
                                }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .zIndex(1)
                        
                        ScrollView {
                            if isSearching {
                                VStack {
                                    Spacer(minLength: 32)
                                    HStack { Spacer(); ProgressView(); Spacer() }
                                    Spacer()
                                }
                            } else {
                                let filteredResults = searchResults
                                LazyVStack(alignment: .leading, spacing: 0) {
                                    ForEach(filteredResults) { field in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(field.name)
                                                    .font(.headline)
                                                    .bold()
                                                Text("\(field.area)・\(field.city)")
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                                Text(field.type)
                                                    .font(.caption)
                                                    .foregroundColor(.accentColor)
                                            }
                                            Spacer()
                                        }
                                        .padding()
                                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(.systemBackground)))
                                        .shadow(radius: 2, y: 1)
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 4)
                                        .onTapGesture {
                                            let address = field.area + field.city
                                            let geocoder = CLGeocoder()
                                            isSearching = true
                                            geocoder.geocodeAddressString(address) { placemarks, error in
                                                isSearching = false
                                                if let location = placemarks?.first?.location {
                                                    withAnimation {
                                                        sheetOffset = midHeight
                                                    }
                                                    withAnimation {
                                                        if sheetState == .mid {
                                                            let shift = coordinateRegion.span.latitudeDelta * 0.2
                                                            let newCenter = CLLocationCoordinate2D(latitude: location.coordinate.latitude - shift, longitude: location.coordinate.longitude)
                                                            coordinateRegion = MKCoordinateRegion(center: newCenter, span: coordinateRegion.span)
                                                        } else {
                                                            coordinateRegion = MKCoordinateRegion(center: location.coordinate, span: coordinateRegion.span)
                                                        }
                                                    }
                                                } else {
                                                    print("[DEBUG] Failed to geocode \(address): \(error?.localizedDescription ?? "nil")")
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        Spacer()
                    }
                    .frame(width: geometry.size.width, height: maxHeight, alignment: .top)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                    .offset(y: screenHeight - clampedOffset)
                    .animation(.interactiveSpring(), value: clampedOffset)
                    .gesture(
                        DragGesture()
                            .updating($dragOffset) { value, state, _ in
                                let newOffset = sheetOffset + value.translation.height * -1
                                state = max(minHeight, min(maxHeight, newOffset)) - sheetOffset
                            }
                            .onEnded { value in
                                let newOffset = sheetOffset + value.translation.height * -1
                                let positions = [minHeight, midHeight, maxHeight]
                                let nearest = positions.min(by: { abs($0 - newOffset) < abs($1 - newOffset) }) ?? midHeight
                                withAnimation {
                                    sheetOffset = nearest
                                }
                            }
                    )
                    .onAppear {
                        sheetOffset = minHeight
                        if isSearchFieldFocused {
                            sheetOffset = maxHeight
                        }
                    }
                    .onChange(of: isSearchFieldFocused) { focused in
                        if focused {
                            withAnimation {
                                sheetOffset = maxHeight
                            }
                        }
                    }
                }
                
                if sheetState != .max {
                    Button {
                        if let location = lastKnownLocation {
                            withAnimation {
                                if sheetState == .mid {
                                    let shift = coordinateRegion.span.latitudeDelta * 0.2
                                    let newCenter = CLLocationCoordinate2D(latitude: location.latitude - shift, longitude: location.longitude)
                                    coordinateRegion = MKCoordinateRegion(center: newCenter, span: coordinateRegion.span)
                                } else {
                                    coordinateRegion = MKCoordinateRegion(center: location, span: coordinateRegion.span)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "location.fill")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue.opacity(0.8))
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding(.top, 32)
                    .padding(.trailing, 16)
                }
            }
        }
        .onAppear{
            let delegate = LocationDelegate { location in
                lastKnownLocation = location.coordinate
            }
            locationDelegate = delegate
            locationManager.delegate = delegate
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
            loadAllFields()
        }
        .sheet(item: $selectedField) { field in
            VStack(spacing: 16) {
                if let url = URL(string: field.imageURL) {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fit).frame(maxWidth: 200)
                    } placeholder: {
                        Color.gray.frame(width: 200, height: 120)
                    }
                }
                Text(field.name)
                    .font(.title2)
                    .bold()
                Text("\(field.area)・\(field.city)")
                    .font(.body)
                Text("種類: \(field.type)  年齢: \(field.age)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Button("閉じる") {
                    selectedField = nil
                }
            }
            .padding()
            .presentationDetents([.fraction(0.35), .medium, .large])
        }
    }
    
    private func performFieldSearch() {
        print("[DEBUG] performFieldSearch (local mode), searchText=\(searchText)")
        guard !searchText.isEmpty else {
            searchResults = []
            loadAllFields()
            return
        }

        isSearching = true
        DispatchQueue.global().async {
            guard let url = Bundle.main.url(forResource: "fields", withExtension: "json"),
                  let data = try? Data(contentsOf: url),
                  let fields = try? JSONDecoder().decode([Field].self, from: data) else {
                DispatchQueue.main.async {
                    print("[ERROR] Failed to search local fields.json")
                    searchResults = []
                    loadAllFields()
                    isSearching = false
                }
                return
            }

            let query = searchText.lowercased()
            let results = fields.filter { field in
                field.name.lowercased().contains(query) ||
                field.area.lowercased().contains(query) ||
                field.city.lowercased().contains(query) ||
                field.type.lowercased().contains(query)
            }

            DispatchQueue.main.async {
                isSearching = false
                searchResults = results
                updateAnnotations(for: results)
            }
        }
    }
    
    private func loadAllFields() {
        guard let url = Bundle.main.url(forResource: "fields", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let results = try? JSONDecoder().decode([Field].self, from: data) else {
            print("[ERROR] Failed to load local fields.json")
            return
        }

        DispatchQueue.main.async {
            allFields = results
            if searchText.isEmpty {
                updateAnnotations(for: results)
            }
        }
    }
    
    private func updateAnnotations(for fields: [Field]) {
        fieldAnnotations = fields.map { field in
            FieldAnnotation(
                id: field.id,
                coordinate: CLLocationCoordinate2D(latitude: field.latitude, longitude: field.longitude),
                name: field.name,
                address: field.city
            )
        }
    }
}

private class LocationDelegate: NSObject, CLLocationManagerDelegate {
    var onUpdate: (CLLocation) -> Void
    
    init(onUpdate: @escaping (CLLocation) -> Void) {
        self.onUpdate = onUpdate
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            DispatchQueue.main.async {
                self.onUpdate(location)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

fileprivate extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

fileprivate struct RoundedCorner: Shape {

    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
