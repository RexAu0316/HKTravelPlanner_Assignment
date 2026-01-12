//
//  MapView.swift
//  HKTravelMap
//
//  Created by Rex Au on 7/1/2026.
//

import SwiftUI
import MapKit
import CoreLocation

// MARK: - Main Map View
struct MapView: View {
    @StateObject private var locationManager = LocationManager.shared
    @ObservedObject var travelDataManager = TravelDataManager.shared
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 22.3193, longitude: 114.1694),
        span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
    )
    
    @State private var selectedLocation: Location?
    @State private var searchText = ""
    @State private var showSearchResults = false
    @State private var searchResults: [MKMapItem] = []
    @State private var isHybridMap = false
    @State private var userTrackingMode: MapUserTrackingMode = .none
    @State private var showLocationDetail = false
    @State private var showTransportOptions = false
    @State private var showingFilters = false
    
    @State private var bottomSheetPosition: BottomSheetPosition = .middle
    @State private var offset: CGFloat = 0
    @State private var lastOffset: CGFloat = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // MARK: - Main Map
            Map(
                coordinateRegion: $region,
                interactionModes: .all,
                showsUserLocation: true,
                userTrackingMode: $userTrackingMode,
                annotationItems: travelDataManager.locations
            ) { location in
                MapAnnotation(coordinate: location.coordinate) {
                    ModernMapMarker(location: location, isSelected: selectedLocation?.id == location.id)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedLocation = location
                                showLocationDetail = true
                                centerOnLocation(location.coordinate, zoom: true)
                                
                                if bottomSheetPosition != .top {
                                    withAnimation {
                                        bottomSheetPosition = .top
                                    }
                                }
                            }
                        }
                }
            }
            .mapStyle(isHybridMap ? .hybrid(elevation: .realistic) : .standard(elevation: .realistic))
            .ignoresSafeArea()
            
            // MARK: - Top Controls
            VStack {
                // Search Bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                        .font(.system(size: 18))
                    
                    TextField("搜尋地點或地址", text: $searchText)
                        .font(.system(size: 16))
                        .submitLabel(.search)
                        .onSubmit {
                            performSearch()
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            searchResults = []
                            showSearchResults = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                                .font(.system(size: 18))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                )
                .padding(.horizontal, 16)
                .padding(.top, 60)
                
                Spacer()
            }
            
            // MARK: - Bottom Right Controls
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        // Location tracking button
                        ModernMapControlButton(
                            icon: userTrackingMode == .follow ? "location.fill" : "location",
                            label: userTrackingMode == .follow ? "追蹤中" : "我的位置",
                            isActive: userTrackingMode == .follow,
                            action: {
                                withAnimation {
                                    userTrackingMode = userTrackingMode == .follow ? .none : .follow
                                    if userTrackingMode == .follow {
                                        locateUserNow()
                                    }
                                }
                            }
                        )
                        
                        // Map type toggle
                        ModernMapControlButton(
                            icon: isHybridMap ? "map.fill" : "map",
                            label: isHybridMap ? "混合地圖" : "標準地圖",
                            isActive: isHybridMap,
                            action: {
                                withAnimation {
                                    isHybridMap.toggle()
                                }
                            }
                        )
                        
                        // Filter button
                        ModernMapControlButton(
                            icon: "line.3.horizontal.decrease.circle",
                            label: "篩選",
                            isActive: showingFilters,
                            action: {
                                showingFilters.toggle()
                            }
                        )
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 16)
                }
            }
            
            // MARK: - Modern Bottom Sheet
            if showSearchResults {
                ModernSearchResultsView(
                    results: searchResults,
                    onSelect: selectSearchResult
                )
                .background(Color(.systemBackground))
                .clipShape(RoundedCornersShape(radius: 20, corners: [.topLeft, .topRight]))
                .offset(y: offset)
            } else if showLocationDetail, let location = selectedLocation {
                ModernLocationDetailView(
                    location: location,
                    onDirections: {
                        showLocationDetail = false
                        showTransportOptions = true
                    },
                    onClose: {
                        selectedLocation = nil
                        showLocationDetail = false
                    }
                )
                .background(Color(.systemBackground))
                .clipShape(RoundedCornersShape(radius: 20, corners: [.topLeft, .topRight]))
                .offset(y: offset)
            } else {
                ModernQuickActionsView()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedCornersShape(radius: 20, corners: [.topLeft, .topRight]))
                    .offset(y: offset)
            }
        }
        .sheet(isPresented: $showTransportOptions) {
            if let location = selectedLocation {
                NavigationView {
                    ModernTransportOptionsView(
                        location: location,
                        userLocation: locationManager.userLocation?.coordinate
                    )
                }
            }
        }
        .sheet(isPresented: $showingFilters) {
            NavigationView {
                MapFilterView()
            }
        }
        .onAppear {
            locateUserOnAppear()
        }
        .onChange(of: searchText) { text in
            if text.isEmpty {
                searchResults = []
                showSearchResults = false
            } else if text.count > 2 {
                performSearch()
            }
        }
    }
    
    // MARK: - Search Functions
    private func performSearch() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = region
        request.resultTypes = [.pointOfInterest, .address]
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            DispatchQueue.main.async {
                if let response = response {
                    searchResults = Array(response.mapItems.prefix(15))
                    showSearchResults = !searchResults.isEmpty
                }
            }
        }
    }
    
    private func selectSearchResult(_ mapItem: MKMapItem) {
        let coordinate = mapItem.placemark.coordinate
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            centerOnLocation(coordinate, zoom: true)
            
            selectedLocation = Location(
                name: mapItem.name ?? "未知地點",
                address: mapItem.placemark.title ?? "",
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                category: "搜索結果"
            )
            
            showSearchResults = false
            showLocationDetail = true
        }
    }
    
    // MARK: - Location Functions
    private func locateUserOnAppear() {
        guard CLLocationManager.locationServicesEnabled() else { return }
        
        let status = locationManager.authorizationStatus
        
        switch status {
        case .notDetermined:
            locationManager.requestPermission()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if let userLocation = locationManager.userLocation {
                    centerOnLocation(userLocation.coordinate)
                }
            }
        default:
            break
        }
    }
    
    private func locateUserNow() {
        let status = locationManager.authorizationStatus
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
            
            if let userLocation = locationManager.userLocation {
                withAnimation(.easeInOut(duration: 0.5)) {
                    userTrackingMode = .follow
                    centerOnLocation(userLocation.coordinate, zoom: true)
                }
            }
        default:
            break
        }
    }
    
    private func centerOnLocation(_ coordinate: CLLocationCoordinate2D, zoom: Bool = false) {
        withAnimation(.easeInOut(duration: 0.5)) {
            region.center = coordinate
            if zoom {
                region.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            }
        }
    }
}

// MARK: - Rounded Corners Shape
struct RoundedCornersShape: Shape {
    var radius: CGFloat = 20
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

// MARK: - Modern Map Control Button
struct ModernMapControlButton: View {
    let icon: String
    let label: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isActive ? .white : .hkBlue)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(isActive ? Color.hkBlue : Color.white)
                            .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
                    )
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.primary)
            }
        }
    }
}

// MARK: - Modern Map Marker
struct ModernMapMarker: View {
    let location: Location
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(isSelected ? Color.hkBlue : (location.isFavorite ? Color.yellow : Color.red))
                    .frame(width: isSelected ? 44 : 36, height: isSelected ? 44 : 36)
                
                Image(systemName: location.isFavorite ? "star.fill" : "mappin.fill")
                    .font(.system(size: isSelected ? 20 : 16, weight: .bold))
                    .foregroundColor(.white)
            }
            .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
            
            if isSelected {
                Text(location.name)
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    )
                    .offset(y: 4)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Modern Quick Actions View
struct ModernQuickActionsView: View {
    let quickActions = [
        ("location.fill", "我的位置", Color.blue),
        ("star.fill", "收藏夾", Color.yellow),
        ("clock.fill", "最近搜尋", Color.green),
        ("bus.fill", "附近交通", Color.purple),
        ("bed.double.fill", "酒店", Color.orange),
        ("fork.knife", "餐廳", Color.pink),
        ("cart.fill", "購物", Color.blue),
        ("leaf.fill", "公園", Color.green)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 12)
            
            VStack(spacing: 24) {
                // Quick actions grid
                VStack(alignment: .leading, spacing: 12) {
                    Text("快速搜尋")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 16)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(quickActions, id: \.1) { icon, title, color in
                            Button(action: {}) {
                                VStack(spacing: 8) {
                                    ZStack {
                                        Circle()
                                            .fill(color.opacity(0.1))
                                            .frame(width: 44, height: 44)
                                        
                                        Image(systemName: icon)
                                            .font(.system(size: 18))
                                            .foregroundColor(color)
                                    }
                                    
                                    Text(title)
                                        .font(.caption2)
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                // Suggested places
                VStack(alignment: .leading, spacing: 12) {
                    Text("推薦地點")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 16)
                    
                    VStack(spacing: 12) {
                        SuggestedPlaceRow(index: 0)
                        SuggestedPlaceRow(index: 1)
                        SuggestedPlaceRow(index: 2)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 20)
        }
    }
}

struct SuggestedPlaceRow: View {
    let index: Int
    
    let places = [
        ("香港迪士尼樂園", "大嶼山"),
        ("太平山頂", "中西區"),
        ("廟街夜市", "油麻地")
    ]
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.hkBlue.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: iconForIndex(index))
                    .font(.title3)
                    .foregroundColor(.hkBlue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(places[index].0)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(places[index].1)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {}
    }
    
    private func iconForIndex(_ index: Int) -> String {
        switch index {
        case 0: return "sparkles"
        case 1: return "mountain.2"
        case 2: return "sparkles.square.filled.on.square"
        default: return "mappin"
        }
    }
}

// MARK: - Modern Search Results View
struct ModernSearchResultsView: View {
    let results: [MKMapItem]
    let onSelect: (MKMapItem) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 12)
            
            Text("搜尋結果 (\(results.count))")
                .font(.headline)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(results, id: \.self) { mapItem in
                        ModernSearchResultRow(mapItem: mapItem)
                            .onTapGesture {
                                onSelect(mapItem)
                            }
                        
                        if mapItem != results.last {
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                }
            }
        }
        .padding(.bottom, 30)
    }
}

struct ModernSearchResultRow: View {
    let mapItem: MKMapItem
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
                    .frame(width: 40, height: 40)
                
                Image(systemName: iconForPlacemark(mapItem.placemark))
                    .font(.system(size: 18))
                    .foregroundColor(.hkBlue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(mapItem.name ?? "未知地點")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(mapItem.placemark.title ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private func iconForPlacemark(_ placemark: MKPlacemark) -> String {
        let name = mapItem.name?.lowercased() ?? ""
        
        if name.contains("restaurant") || name.contains("cafe") || name.contains("food") {
            return "fork.knife"
        } else if name.contains("shop") || name.contains("store") || name.contains("mall") {
            return "bag"
        } else if name.contains("hotel") || name.contains("motel") {
            return "bed.double"
        } else if name.contains("theater") || name.contains("cinema") {
            return "film"
        } else if name.contains("park") || name.contains("garden") {
            return "leaf"
        } else if name.contains("hospital") || name.contains("clinic") {
            return "cross"
        } else if name.contains("station") || name.contains("mtr") || name.contains("train") {
            return "tram"
        } else if name.contains("bus") || name.contains("transit") {
            return "bus"
        }
        
        return "mappin"
    }
}

// MARK: - Modern Location Detail View
struct ModernLocationDetailView: View {
    let location: Location
    let onDirections: () -> Void
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 12)
            
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: location.isFavorite ? "star.circle.fill" : "mappin.circle.fill")
                                .font(.title2)
                                .foregroundColor(location.isFavorite ? .yellow : .red)
                            
                            Text(location.name)
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        
                        Text(location.address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 16)
                
                // Category Tag
                if !location.category.isEmpty {
                    HStack {
                        Text(location.category)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(categoryColor.opacity(0.1))
                            .foregroundColor(categoryColor)
                            .cornerRadius(8)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                }
                
                // Quick Actions
                HStack(spacing: 12) {
                    // Directions Button
                    Button(action: onDirections) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                            Text("路線")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.hkBlue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(color: .hkBlue.opacity(0.3), radius: 3, x: 0, y: 2)
                    }
                    
                    // Favorite Button
                    Button(action: {
                        TravelDataManager.shared.updateFavoriteStatus(for: location.id, isFavorite: !location.isFavorite)
                    }) {
                        Image(systemName: location.isFavorite ? "star.fill" : "star")
                            .font(.title3)
                            .frame(width: 44, height: 44)
                            .background(Color(.systemGray6))
                            .foregroundColor(location.isFavorite ? .yellow : .gray)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.bottom, 30)
    }
    
    private var categoryColor: Color {
        switch location.category {
        case "Transport Hub": return .blue
        case "Shopping": return .pink
        case "Dining": return .orange
        case "Entertainment": return .purple
        default: return .gray
        }
    }
}

// MARK: - Modern Transport Options View
struct ModernTransportOptionsView: View {
    let location: Location
    let userLocation: CLLocationCoordinate2D?
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedMode = "Driving"
    
    let transportModes = [
        ("car.fill", "駕車", Color.blue, "Driving"),
        ("bus.fill", "公共交通", Color.green, "Transit"),
        ("figure.walk", "步行", Color.orange, "Walking"),
        ("tram.fill", "輕鐵/電車", Color.purple, "Rail")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text(location.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(location.address)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            // Transport Mode Selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(transportModes, id: \.3) { icon, title, color, mode in
                        Button(action: {
                            selectedMode = mode
                        }) {
                            VStack(spacing: 6) {
                                ZStack {
                                    Circle()
                                        .fill(selectedMode == mode ? color : Color(.systemGray6))
                                        .frame(width: 50, height: 50)
                                    
                                    Image(systemName: icon)
                                        .font(.system(size: 20))
                                        .foregroundColor(selectedMode == mode ? .white : color)
                                }
                                
                                Text(title)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(selectedMode == mode ? color : .primary)
                            }
                            .frame(width: 70)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 16)
            
            Divider()
            
            // Routes List
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(0..<3) { index in
                        ModernRouteOptionCard(
                            mode: selectedMode,
                            duration: 15 + index * 5,
                            distance: 3.2 + Double(index) * 1.5,
                            isRecommended: index == 0,
                            onNavigate: {
                                startNavigation(mode: selectedMode)
                            }
                        )
                    }
                }
                .padding()
            }
            
            // Navigation Button
            Button(action: {
                startNavigation(mode: selectedMode)
            }) {
                Text("開始導航")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.hkBlue, Color.hkBlue.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: .hkBlue.opacity(0.3), radius: 5, x: 0, y: 3)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationBarTitle("路線規劃", displayMode: .inline)
        .navigationBarItems(leading: Button("取消") {
            presentationMode.wrappedValue.dismiss()
        })
    }
    
    private func startNavigation(mode: String) {
        guard let userCoordinate = userLocation else { return }
        
        let fromPlacemark = MKPlacemark(coordinate: userCoordinate)
        let toPlacemark = MKPlacemark(coordinate: location.coordinate)
        
        let fromMapItem = MKMapItem(placemark: fromPlacemark)
        fromMapItem.name = "我的位置"
        
        let toMapItem = MKMapItem(placemark: toPlacemark)
        toMapItem.name = location.name
        
        let launchOptions: [String: Any] = [
            MKLaunchOptionsDirectionsModeKey: getAppleMapsMode(for: mode),
            MKLaunchOptionsShowsTrafficKey: true
        ]
        
        MKMapItem.openMaps(with: [fromMapItem, toMapItem], launchOptions: launchOptions)
        presentationMode.wrappedValue.dismiss()
    }
    
    private func getAppleMapsMode(for mode: String) -> String {
        switch mode {
        case "Driving":
            return MKLaunchOptionsDirectionsModeDriving
        case "Transit", "Rail":
            return MKLaunchOptionsDirectionsModeTransit
        case "Walking":
            return MKLaunchOptionsDirectionsModeWalking
        default:
            return MKLaunchOptionsDirectionsModeDriving
        }
    }
}

struct ModernRouteOptionCard: View {
    let mode: String
    let duration: Int
    let distance: Double
    let isRecommended: Bool
    let onNavigate: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(getModeTitle())
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if isRecommended {
                        Text("最快速")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(duration)分鐘")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.hkBlue)
                    
                    Text("\(String(format: "%.1f", distance))公里")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Navigation Button
            Button(action: onNavigate) {
                Text("使用此路線")
                    .font(.caption)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.hkBlue)
                    .foregroundColor(.white)
                    .cornerRadius(6)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private func getModeTitle() -> String {
        switch mode {
        case "Driving": return "駕車路線"
        case "Transit": return "公共交通"
        case "Walking": return "步行路線"
        case "Rail": return "軌道交通"
        default: return "路線"
        }
    }
}

// MARK: - Map Filter View
struct MapFilterView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedCategories: Set<String> = ["Transport Hub", "Shopping", "Dining"]
    @State private var showFavoritesOnly = false
    @State private var searchRadius: Double = 5.0
    
    let categories = ["Transport Hub", "Shopping", "Dining", "Entertainment", "Park", "Hotel"]
    
    var body: some View {
        List {
            Section(header: Text("類別篩選")) {
                ForEach(categories, id: \.self) { category in
                    HStack {
                        Text(category)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if selectedCategories.contains(category) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.hkBlue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedCategories.contains(category) {
                            selectedCategories.remove(category)
                        } else {
                            selectedCategories.insert(category)
                        }
                    }
                }
            }
            
            Section(header: Text("其他篩選")) {
                Toggle("只顯示收藏地點", isOn: $showFavoritesOnly)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("搜尋範圍: \(String(format: "%.1f", searchRadius))公里")
                        .font(.subheadline)
                    
                    Slider(value: $searchRadius, in: 1...20, step: 0.5)
                }
                .padding(.vertical, 8)
            }
            
            Section {
                Button("重置篩選") {
                    selectedCategories = Set(categories)
                    showFavoritesOnly = false
                    searchRadius = 5.0
                }
                .foregroundColor(.hkBlue)
                
                Button("應用篩選") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.hkBlue)
                .cornerRadius(10)
                .listRowInsets(EdgeInsets())
                .padding(.vertical, 8)
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("地圖篩選")
        .navigationBarItems(trailing: Button("完成") {
            presentationMode.wrappedValue.dismiss()
        })
    }
}

// MARK: - Bottom Sheet Position
enum BottomSheetPosition {
    case collapsed
    case middle
    case top
}

// MARK: - Preview
#Preview {
    MapView()
}
