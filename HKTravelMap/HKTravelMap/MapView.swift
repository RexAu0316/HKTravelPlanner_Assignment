//
//  MapView.swift (精簡版本)
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
    @ObservedObject var transportAPI = TransportationAPIViewController.shared
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 22.3193, longitude: 114.1694),
        span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
    )
    
    @State private var selectedLocation: Location?
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var userTrackingMode: MapUserTrackingMode = .follow
    @State private var showLocationDetail = false
    @State private var showTransportOptions = false
    @State private var showNearbyTransport = false
    @State private var showRoutePlanning = false
    @State private var mapAnnotations: [CustomAnnotation] = []
    
    // 底部視圖狀態
    @State private var bottomSheetPosition: BottomSheetPosition = .middle
    @State private var dragOffset: CGFloat = 0
    @State private var lastDragValue: CGFloat = 0
    
    // 路線規劃狀態
    @State private var routeStartLocation = ""
    @State private var routeEndLocation = ""
    @State private var routeStartCoordinate: CLLocationCoordinate2D?
    @State private var routeEndCoordinate: CLLocationCoordinate2D?
    @State private var isPlanningRoute = false
    @State private var showRouteResults = false
    
    // 地圖類型
    @State private var mapType: MapType = .standard
    
    enum MapType {
        case standard
        case hybrid
        case satellite
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // MARK: - Main Map
            mapContent
                .mapStyle(mapStyle)
                .mapControls {
                    MapCompass()
                    MapScaleView()
                   // MapUserLocationButton()
                }
                .ignoresSafeArea()
            
            // MARK: - Top Search Bar
            VStack(spacing: 12) {
                // Enhanced Search Bar
                EnhancedSearchBar(
                    searchText: $searchText,
                    onSearch: performSearch,
                    onClear: {
                        searchText = ""
                        searchResults = []
                    },
                    onLocationTap: {
                        locateUserNow()
                    }
                )
                .padding(.horizontal, 16)
                .padding(.top, 10)
                
                Spacer()
            }
            
            // MARK: - Floating Action Buttons
            VStack(spacing: 16) {
                Spacer()
                
                HStack {
                    Spacer()
                    // Right Side Map Controls
                    VStack(spacing: 12) {
                        // Map Type
                        FloatingActionButton(
                            icon: mapTypeIcon,
                            color: .blue,
                            action: {
                                cycleMapType()
                            }
                        )
                        
                        // Filter
                        FloatingActionButton(
                            icon: "line.3.horizontal.decrease.circle",
                            color: .gray,
                            action: {
                                // 簡單的過濾功能
                                showFavoritesOnly()
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 50)
            }
            
            // MARK: - Bottom Sheet Content
            BottomSheet(
                position: $bottomSheetPosition,
                dragOffset: $dragOffset,
                lastDragValue: $lastDragValue,
                onPositionChange: { newPosition in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        bottomSheetPosition = newPosition
                    }
                }
            ) {
                // 動態內容
                Group {
                    if !searchResults.isEmpty {
                        SearchResultsView(
                            results: searchResults,
                            onSelect: selectSearchResult,
                            onClear: {
                                searchResults = []
                                searchText = ""
                            }
                        )
                    } else if showLocationDetail, let location = selectedLocation {
                        LocationDetailView(
                            location: location,
                            onDirections: {
                                showLocationDetail = false
                                showTransportOptions = true
                            },
                            onSave: {
                                travelDataManager.updateFavoriteStatus(for: location.id, isFavorite: !location.isFavorite)
                            },
                            onClose: {
                                selectedLocation = nil
                                showLocationDetail = false
                                withAnimation {
                                    bottomSheetPosition = .middle
                                }
                            }
                        )
                    } else if showNearbyTransport {
                        NearbyTransportView(
                            transports: transportAPI.nearbyTransport,
                            onSelect: { transport in
                                let coordinate = transport.coordinate
                                centerOnLocation(coordinate, zoom: true)
                                showNearbyTransport = false
                            },
                            onClose: {
                                showNearbyTransport = false
                                withAnimation {
                                    bottomSheetPosition = .middle
                                }
                            }
                        )
                    } else if showRoutePlanning {
                        RoutePlanningView(
                            startLocation: $routeStartLocation,
                            endLocation: $routeEndLocation,
                            isPlanning: $isPlanningRoute,
                            onPlanRoute: planRoute,
                            onClose: {
                                showRoutePlanning = false
                                withAnimation {
                                    bottomSheetPosition = .middle
                                }
                            }
                        )
                    } else {
                        QuickAccessView(
                            onSelectCategory: { category in
                                filterLocations(by: category)
                            },
                            onShowFavorites: {
                                filterLocations(by: "favorites")
                            }
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $showTransportOptions) {
            if let location = selectedLocation {
                TransportOptionsView(
                    location: location,
                    userLocation: locationManager.userLocation?.coordinate,
                    onStartNavigation: { mode in
                        startNavigation(to: location.coordinate, mode: mode)
                    }
                )
            }
        }
        .sheet(isPresented: $showRouteResults) {
            RouteResultsPlaceholderView()
        }
        .onAppear {
            locateUserOnAppear()
            setupMapAnnotations()
        }
        .onChange(of: searchText) { text in
            if text.isEmpty {
                searchResults = []
            } else if text.count > 2 {
                performSearch()
            }
        }
    }
    
    // MARK: - Map Content
    private var mapContent: some View {
        Map(coordinateRegion: $region,
            interactionModes: .all,
            showsUserLocation: true,
            userTrackingMode: $userTrackingMode,
            annotationItems: travelDataManager.locations
        ) { location in
            MapAnnotation(coordinate: location.coordinate) {
                ModernMapMarker(
                    location: location,
                    isSelected: selectedLocation?.id == location.id,
                    category: location.category
                )
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
    }
    
    // MARK: - Computed Properties
    
    private var mapStyle: MapStyle {
        switch mapType {
        case .standard:
            return .standard(elevation: .realistic)
        case .hybrid:
            return .hybrid(elevation: .realistic)
        case .satellite:
            return .imagery(elevation: .realistic)
        }
    }
    
    private var mapTypeIcon: String {
        switch mapType {
        case .standard: return "map"
        case .hybrid: return "square.3.layers.3d"
        case .satellite: return "globe"
        }
    }
    
    // MARK: - Core Functions
    
    private func setupMapAnnotations() {
        mapAnnotations = travelDataManager.locations.map { location in
            CustomAnnotation(
                coordinate: location.coordinate,
                title: location.name,
                subtitle: location.category,
                color: categoryColor(for: location.category)
            )
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
        
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
            
            if let userLocation = locationManager.userLocation {
                withAnimation(.easeInOut(duration: 0.5)) {
                    userTrackingMode = .follow
                    centerOnLocation(userLocation.coordinate, zoom: true)
                }
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
                    searchResults = Array(response.mapItems.prefix(10))
                    if !searchResults.isEmpty {
                        withAnimation {
                            bottomSheetPosition = .top
                        }
                    }
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
            
            searchResults = []
            searchText = ""
            showLocationDetail = true
            bottomSheetPosition = .top
        }
    }
    
    // MARK: - Filter Functions
    
    private func filterLocations(by category: String) {
        if category == "favorites" {
            travelDataManager.locations = travelDataManager.locations.filter { $0.isFavorite }
        } else {
            travelDataManager.locations = travelDataManager.locations.filter { $0.category == category }
        }
        setupMapAnnotations()
    }
    
    private func showFavoritesOnly() {
        filterLocations(by: "favorites")
    }
    
    // MARK: - Route Planning
    
    private func planRoute() {
        guard !routeStartLocation.isEmpty && !routeEndLocation.isEmpty else { return }
        
        isPlanningRoute = true
        
        // 模擬路線規劃
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isPlanningRoute = false
            showRouteResults = true
            showRoutePlanning = false
            bottomSheetPosition = .middle
        }
    }
    
    // MARK: - Navigation
    
    private func startNavigation(to coordinate: CLLocationCoordinate2D, mode: String) {
        guard let userCoordinate = locationManager.userLocation?.coordinate else { return }
        
        let fromPlacemark = MKPlacemark(coordinate: userCoordinate)
        let toPlacemark = MKPlacemark(coordinate: coordinate)
        
        let fromMapItem = MKMapItem(placemark: fromPlacemark)
        fromMapItem.name = "我的位置"
        
        let toMapItem = MKMapItem(placemark: toPlacemark)
        toMapItem.name = selectedLocation?.name ?? "目的地"
        
        let launchOptions: [String: Any] = [
            MKLaunchOptionsDirectionsModeKey: getAppleMapsMode(for: mode)
        ]
        
        MKMapItem.openMaps(with: [fromMapItem, toMapItem], launchOptions: launchOptions)
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
    
    // MARK: - Transport Functions
    
    private func fetchNearbyTransport() {
        if let userLocation = locationManager.userLocation?.coordinate {
            transportAPI.fetchNearbyTransport(coordinate: userLocation, radius: 1.0)
        }
    }
    
    private func cycleMapType() {
        switch mapType {
        case .standard:
            mapType = .hybrid
        case .hybrid:
            mapType = .satellite
        case .satellite:
            mapType = .standard
        }
    }
    
    private func categoryColor(for category: String) -> Color {
        switch category {
        case "Transport Hub": return .blue
        case "Shopping": return .pink
        case "Dining": return .orange
        case "Entertainment": return .purple
        case "Park": return .green
        case "Hotel": return .teal
        default: return .gray
        }
    }
}

// MARK: - Supporting Views

struct EnhancedSearchBar: View {
    @Binding var searchText: String
    let onSearch: () -> Void
    let onClear: () -> Void
    let onLocationTap: () -> Void
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .font(.system(size: 18))
            
            TextField("搜尋地點、地址或類別", text: $searchText)
                .font(.system(size: 16))
                .submitLabel(.search)
                .focused($isFocused)
                .onSubmit(onSearch)
            
            if !searchText.isEmpty {
                Button(action: onClear) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 18))
                }
            }
            
            Button(action: onLocationTap) {
                Image(systemName: "location.fill")
                    .foregroundColor(.hkBlue)
                    .font(.system(size: 18))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
    }
}

struct FloatingActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(color)
                        .shadow(color: color.opacity(0.3), radius: 5, x: 0, y: 3)
                )
        }
    }
}

struct ModernMapMarker: View {
    let location: Location
    let isSelected: Bool
    let category: String
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(categoryColor(for: category).opacity(0.2))
                        .frame(width: 60, height: 60)
                        .scaleEffect(1.2)
                }
                
                Circle()
                    .fill(isSelected ? categoryColor(for: category) : (location.isFavorite ? Color.yellow : categoryColor(for: category)))
                    .frame(width: isSelected ? 44 : 36, height: isSelected ? 44 : 36)
                    .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
                
                Image(systemName: iconForCategory(category))
                    .font(.system(size: isSelected ? 20 : 16, weight: .bold))
                    .foregroundColor(.white)
                
                if location.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.yellow)
                        .offset(x: 12, y: -12)
                }
            }
            
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
    
    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "Transport Hub": return "train.side.front.car"
        case "Shopping": return "bag.fill"
        case "Dining": return "fork.knife"
        case "Entertainment": return "film.fill"
        case "Park": return "leaf.fill"
        case "Hotel": return "bed.double.fill"
        default: return "mappin"
        }
    }
    
    private func categoryColor(for category: String) -> Color {
        switch category {
        case "Transport Hub": return .blue
        case "Shopping": return .pink
        case "Dining": return .orange
        case "Entertainment": return .purple
        case "Park": return .green
        case "Hotel": return .teal
        default: return .gray
        }
    }
}

// MARK: - Bottom Sheet System

struct BottomSheet<Content: View>: View {
    @Binding var position: BottomSheetPosition
    @Binding var dragOffset: CGFloat
    @Binding var lastDragValue: CGFloat
    let onPositionChange: (BottomSheetPosition) -> Void
    let content: () -> Content
    
    private let topPosition: CGFloat = 60
    private let middlePosition: CGFloat = UIScreen.main.bounds.height * 0.5
    private let bottomPosition: CGFloat = UIScreen.main.bounds.height - 170
    
    var currentPosition: CGFloat {
        switch position {
        case .top: return topPosition
        case .middle: return middlePosition
        case .bottom: return bottomPosition
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Capsule()
                    .fill(Color(.systemGray4))
                    .frame(width: 40, height: 5)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let translation = value.translation.height
                                dragOffset = translation + lastDragValue
                            }
                            .onEnded { value in
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    let newPosition = currentPosition + dragOffset
                                    let screenHeight = geometry.size.height
                                    
                                    if newPosition < screenHeight * 0.3 {
                                        position = .top
                                    } else if newPosition < screenHeight * 0.7 {
                                        position = .middle
                                    } else {
                                        position = .bottom
                                    }
                                    
                                    dragOffset = 0
                                    lastDragValue = 0
                                    onPositionChange(position)
                                }
                            }
                    )
                
                content()
                    .frame(maxWidth: .infinity)
                    .frame(height: geometry.size.height - 100)
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .frame(height: geometry.size.height)
            .background(
                Rectangle()
                    .fill(Color(.systemBackground))
                    .cornerRadius(20, corners: [.topLeft, .topRight])
                    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: -5)
            )
            .offset(y: max(currentPosition + dragOffset, topPosition))
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

enum BottomSheetPosition {
    case top
    case middle
    case bottom
}

// MARK: - Bottom Sheet Content Views

struct SearchResultsView: View {
    let results: [MKMapItem]
    let onSelect: (MKMapItem) -> Void
    let onClear: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("搜尋結果")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(results.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                
                Button("清除") {
                    onClear()
                }
                .font(.caption)
                .foregroundColor(.hkBlue)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(results, id: \.self) { mapItem in
                        SearchResultRow(mapItem: mapItem)
                            .onTapGesture {
                                onSelect(mapItem)
                            }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.top, 8)
    }
}

struct SearchResultRow: View {
    let mapItem: MKMapItem
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: iconForPlacemark(mapItem.placemark))
                .font(.title3)
                .foregroundColor(.hkBlue)
                .frame(width: 36)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(mapItem.name ?? "未知地點")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(mapItem.placemark.title ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
    }
    
    private func iconForPlacemark(_ placemark: MKPlacemark) -> String {
        let name = mapItem.name?.lowercased() ?? ""
        
        if name.contains("restaurant") || name.contains("cafe") || name.contains("food") {
            return "fork.knife"
        } else if name.contains("shop") || name.contains("store") || name.contains("mall") {
            return "bag"
        } else if name.contains("hotel") || name.contains("motel") {
            return "bed.double"
        } else if name.contains("park") || name.contains("garden") {
            return "leaf"
        } else if name.contains("station") || name.contains("mtr") || name.contains("train") {
            return "train.side.front.car"
        }
        
        return "mappin"
    }
}

struct LocationDetailView: View {
    let location: Location
    let onDirections: () -> Void
    let onSave: () -> Void
    let onClose: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                Image(systemName: location.isFavorite ? "star.circle.fill" : "mappin.circle.fill")
                    .font(.title)
                    .foregroundColor(location.isFavorite ? .yellow : categoryColor(for: location.category))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(location.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
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
            
            if !location.category.isEmpty {
                HStack {
                    Text(location.category)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(categoryColor(for: location.category).opacity(0.1))
                        .foregroundColor(categoryColor(for: location.category))
                        .cornerRadius(8)
                    
                    Spacer()
                    
                    Text("約 1.2 公里")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(spacing: 12) {
                Button(action: onDirections) {
                    Label("路線", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.hkBlue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Button(action: onSave) {
                    VStack(spacing: 4) {
                        Image(systemName: location.isFavorite ? "star.fill" : "star")
                            .font(.title3)
                        Text(location.isFavorite ? "已收藏" : "收藏")
                            .font(.caption2)
                    }
                    .frame(width: 80)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .foregroundColor(location.isFavorite ? .yellow : .gray)
                    .cornerRadius(12)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 30)
    }
    
    private func categoryColor(for category: String) -> Color {
        switch category {
        case "Transport Hub": return .blue
        case "Shopping": return .pink
        case "Dining": return .orange
        case "Entertainment": return .purple
        default: return .gray
        }
    }
}

struct NearbyTransportView: View {
    let transports: [TransportLocation]
    let onSelect: (TransportLocation) -> Void
    let onClose: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("附近交通設施")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("關閉") {
                    onClose()
                }
                .font(.caption)
                .foregroundColor(.hkBlue)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            
            if transports.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "bus")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("附近沒有交通設施")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("請移動到其他位置")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(transports) { transport in
                            TransportRow(transport: transport)
                                .onTapGesture {
                                    onSelect(transport)
                                }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .padding(.top, 8)
    }
}

struct TransportRow: View {
    let transport: TransportLocation
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: transportTypeIcon(for: transport.type))
                .font(.title3)
                .foregroundColor(transportTypeColor(for: transport.type))
                .frame(width: 36)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(transport.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(transport.type.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("步行 \(Int((transport.distance ?? 0) / 80))分鐘")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
    }
    
    private func transportTypeColor(for type: TransportLocation.TransportType) -> Color {
        switch type {
        case .mtrStation: return .red
        case .busStop: return .green
        case .minibusStop: return .orange
        case .tramStop: return .blue
        case .ferryPier: return .purple
        case .taxiStand: return .yellow
        }
    }
    
    private func transportTypeIcon(for type: TransportLocation.TransportType) -> String {
        switch type {
        case .mtrStation: return "train.side.front.car"
        case .busStop: return "bus"
        case .minibusStop: return "bus.doubledecker"
        case .tramStop: return "tram"
        case .ferryPier: return "ferry"
        case .taxiStand: return "car"
        }
    }
}

struct RoutePlanningView: View {
    @Binding var startLocation: String
    @Binding var endLocation: String
    @Binding var isPlanning: Bool
    let onPlanRoute: () -> Void
    let onClose: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("路線規劃")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("關閉") {
                    onClose()
                }
                .font(.caption)
                .foregroundColor(.hkBlue)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Label("出發地點", systemImage: "mappin.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
                
                TextField("輸入出發地點", text: $startLocation)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Label("目的地", systemImage: "flag.circle.fill")
                    .font(.caption)
                    .foregroundColor(.red)
                
                TextField("輸入目的地", text: $endLocation)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            
            Button(action: onPlanRoute) {
                if isPlanning {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("開始規劃")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.hkBlue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .disabled(startLocation.isEmpty || endLocation.isEmpty || isPlanning)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 30)
    }
}

struct QuickAccessView: View {
    let onSelectCategory: (String) -> Void
    let onShowFavorites: () -> Void
    
    let categories = [
        ("train.side.front.car", "交通樞紐", "Transport Hub", Color.blue),
        ("fork.knife", "餐飲", "Dining", Color.orange),
        ("cart.fill", "超市", "Supermarket", Color.green)
    ]
    
    @State private var selectedCategory: String? = nil
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                
                // Categories Grid
                VStack(alignment: .leading, spacing: 16) {
                    Text("類別選擇")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(categories, id: \.2) { icon, title, category, color in
                            CategoryCard(
                                icon: icon,
                                title: title,
                                color: color,
                                isSelected: selectedCategory == category,
                                action: {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedCategory = category
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        onSelectCategory(category)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
            

                
                // Popular Destinations
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("熱門目的地")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button("查看全部") {
                            // Show all popular destinations
                        }
                        .font(.caption)
                        .foregroundColor(.hkBlue)
                    }
                    .padding(.horizontal, 20)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            PopularDestinationCard(
                                name: "太平山頂",
                                category: "景點",
                                imageName: "mountain.2.fill",
                                rating: 4.8,
                                distance: "3.2km"
                            )
                            
                            PopularDestinationCard(
                                name: "維多利亞港",
                                category: "景點",
                                imageName: "water.waves",
                                rating: 4.9,
                                distance: "2.5km"
                            )
                            
                            PopularDestinationCard(
                                name: "廟街夜市",
                                category: "夜市",
                                imageName: "cart.fill",
                                rating: 4.5,
                                distance: "4.1km"
                            )
                            
                            PopularDestinationCard(
                                name: "海洋公園",
                                category: "主題公園",
                                imageName: "fish.fill",
                                rating: 4.7,
                                distance: "8.2km"
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 4)
                    }
                }
                
                // Recent Searches
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("最近搜尋")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button("清除") {
                            // Clear recent searches
                        }
                        .font(.caption)
                        .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 20)
                    
                    VStack(spacing: 12) {
                        RecentSearchItem(name: "中環地鐵站", time: "剛剛", icon: "train.side.front.car")
                        RecentSearchItem(name: "銅鑼灣購物中心", time: "10分鐘前", icon: "bag.fill")
                        RecentSearchItem(name: "蘭桂坊酒吧", time: "1小時前", icon: "wineglass.fill")
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.vertical, 24)
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct CategoryCard: View {
    let icon: String
    let title: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? color : color.opacity(0.1))
                        .frame(width: 56, height: 56)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? color : Color.clear, lineWidth: 2)
                        )
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isSelected ? .white : color)
                }
                .scaleEffect(isSelected ? 1.1 : 1.0)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? color : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.1))
                    .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct PopularDestinationCard: View {
    let name: String
    let category: String
    let imageName: String
    let rating: Double
    let distance: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image/Icon Placeholder
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.hkBlue.opacity(0.1))
                    .frame(width: 160, height: 120)
                    .overlay(
                        Image(systemName: imageName)
                            .font(.system(size: 40))
                            .foregroundColor(.hkBlue.opacity(0.3))
                    )
                
                // Rating Badge
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                    
                    Text(String(format: "%.1f", rating))
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.black.opacity(0.7))
                .cornerRadius(8)
                .padding(8)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack {
                    Text(category)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        
                        Text(distance)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Button(action: {
                // Navigate to this destination
            }) {
                Text("查看")
                    .font(.caption)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Color.hkBlue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .frame(width: 160)
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct RecentSearchItem: View {
    let name: String
    let time: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundColor(.hkBlue)
                .frame(width: 32, height: 32)
                .background(Color.hkBlue.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct CategoryButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.hkBlue)
                    .frame(width: 40, height: 40)
                    .background(Color.hkBlue.opacity(0.1))
                    .cornerRadius(20)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

struct MapQuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}

struct TransportOptionsView: View {
    let location: Location
    let userLocation: CLLocationCoordinate2D?
    let onStartNavigation: (String) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedMode = "Driving"
    
    let transportModes = [
        ("car.fill", "駕車", Color.blue, "Driving"),
        ("bus.fill", "公共交通", Color.green, "Transit"),
        ("figure.walk", "步行", Color.orange, "Walking")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
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
            
            Button(action: {
                onStartNavigation(selectedMode)
            }) {
                Text("開始導航")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.hkBlue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationBarTitle("路線規劃", displayMode: .inline)
        .navigationBarItems(leading: Button("取消") {
            presentationMode.wrappedValue.dismiss()
        })
    }
}

struct RouteResultsPlaceholderView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                    .padding()
                
                Text("路線規劃完成")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("路線已成功規劃並顯示在地圖上")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                Button("關閉") {
                    presentationMode.wrappedValue.dismiss()
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.hkBlue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding()
            }
            .padding()
            .navigationTitle("路線結果")
            .navigationBarItems(trailing: Button("關閉") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// MARK: - Custom Types

struct CustomAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String
    let subtitle: String
    let color: Color
}

// MARK: - Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
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

// MARK: - Preview
#Preview {
    MapView()
}
