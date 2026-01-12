    //
    //  MapView.swift
    //  HKTravelMap
    //
    //  Created by Rex Au on 7/1/2026.
    //  Redesigned: Enhanced Apple Maps-style UI
    //

    import SwiftUI
    import MapKit
    import CoreLocation

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
        
        // Bottom sheet states
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
                    // Search Bar at Top
                    ModernSearchBar(
                        text: $searchText,
                        onSearch: performSearch,
                        onClear: {
                            searchText = ""
                            searchResults = []
                            showSearchResults = false
                        }
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 60)
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
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
                ModernBottomSheet(
                    position: $bottomSheetPosition,
                    offset: $offset,
                    lastOffset: $lastOffset,
                    selectedLocation: $selectedLocation,
                    showLocationDetail: $showLocationDetail,
                    searchText: $searchText,
                    showSearchResults: $showSearchResults,
                    searchResults: $searchResults,
                    onSearch: performSearch,
                    onClearSearch: {
                        searchText = ""
                        searchResults = []
                        showSearchResults = false
                    },
                    onSelectLocation: selectSearchResult,
                    onDirections: {
                        if let location = selectedLocation {
                            showLocationDetail = false
                            showTransportOptions = true
                        }
                    },
                    onCloseDetail: {
                        selectedLocation = nil
                        showLocationDetail = false
                    }
                )
                
                // MARK: - Transport Options Sheet
                .sheet(isPresented: $showTransportOptions) {
                    if let location = selectedLocation {
                        ModernTransportOptionsView(
                            location: location,
                            userLocation: locationManager.userLocation?.coordinate
                        )
                    }
                }
                
                // MARK: - Filter Sheet
                .sheet(isPresented: $showingFilters) {
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
            .onChange(of: selectedLocation) { location in
                if location != nil {
                    showLocationDetail = true
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
                        
                        if !searchResults.isEmpty && bottomSheetPosition == .collapsed {
                            withAnimation {
                                bottomSheetPosition = .middle
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
                
                // Create a new location object
                selectedLocation = Location(
                    name: mapItem.name ?? "未知地點",
                    address: mapItem.placemark.title ?? "",
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    category: "搜索結果"
                )
                
                showSearchResults = false
                showLocationDetail = true
                
                bottomSheetPosition = .top
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

    // MARK: - Modern Bottom Sheet
    struct ModernBottomSheet: View {
        @Binding var position: BottomSheetPosition
        @Binding var offset: CGFloat
        @Binding var lastOffset: CGFloat
        @Binding var selectedLocation: Location?
        @Binding var showLocationDetail: Bool
        @Binding var searchText: String
        @Binding var showSearchResults: Bool
        @Binding var searchResults: [MKMapItem]
        
        let onSearch: () -> Void
        let onClearSearch: () -> Void
        let onSelectLocation: (MKMapItem) -> Void
        let onDirections: () -> Void
        let onCloseDetail: () -> Void
        
        @GestureState private var gestureOffset: CGFloat = 0
        @State private var contentHeight: CGFloat = 300
        
        var body: some View {
            VStack(spacing: 0) {
                // Drag Indicator
                Capsule()
                    .fill(Color(.systemGray4))
                    .frame(width: 40, height: 5)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                
                // Content
                if showLocationDetail, let location = selectedLocation {
                    ModernLocationDetailView(
                        location: location,
                        onDirections: onDirections,
                        onClose: onCloseDetail
                    )
                    .background(
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    contentHeight = geometry.size.height
                                }
                        }
                    )
                } else if showSearchResults {
                    ModernSearchResultsView(
                        results: searchResults,
                        onSelect: onSelectLocation
                    )
                } else {
                    ModernQuickActionsView()
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 30)
            .frame(maxWidth: .infinity)
            .background(
                VisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
                    .cornerRadius(20, corners: [.topLeft, .topRight])
            )
            .offset(y: offset)
            .gesture(
                DragGesture()
                    .updating($gestureOffset) { value, out, _ in
                        out = value.translation.height
                    }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            if value.translation.height > 100 {
                                if position == .top {
                                    position = .middle
                                    offset = position.offset
                                } else if position == .middle {
                                    position = .collapsed
                                    offset = position.offset
                                }
                            } else if value.translation.height < -100 {
                                if position == .collapsed {
                                    position = .middle
                                    offset = position.offset
                                } else if position == .middle {
                                    position = .top
                                    offset = position.offset
                                }
                            } else {
                                offset = position.offset
                            }
                            lastOffset = offset
                        }
                    }
            )
            .onChange(of: position) { newPosition in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    offset = newPosition.offset
                    lastOffset = offset
                }
            }
            .onAppear {
                offset = position.offset
                lastOffset = offset
            }
        }
    }

    // MARK: - Bottom Sheet Position
    enum BottomSheetPosition: CaseIterable {
        case collapsed
        case middle
        case top
        
        var offset: CGFloat {
            switch self {
            case .collapsed:
                return UIScreen.main.bounds.height - 120
            case .middle:
                return UIScreen.main.bounds.height / 2
            case .top:
                return UIScreen.main.bounds.height * 0.1
            }
        }
    }

    // MARK: - Modern Search Bar
    struct ModernSearchBar: View {
        @Binding var text: String
        let onSearch: () -> Void
        let onClear: () -> Void
        
        @FocusState private var isFocused: Bool
        
        var body: some View {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .font(.system(size: 18))
                
                TextField("搜尋地點或地址", text: $text)
                    .focused($isFocused)
                    .font(.system(size: 16))
                    .submitLabel(.search)
                    .onSubmit {
                        onSearch()
                        isFocused = false
                    }
                
                if !text.isEmpty {
                    Button(action: {
                        text = ""
                        onClear()
                        isFocused = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 18))
                    }
                    .transition(.scale)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            )
            .animation(.easeInOut(duration: 0.2), value: text.isEmpty)
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
            ZStack {
                // Outer pulse animation when selected
                if isSelected {
                    Circle()
                        .fill(Color.hkBlue.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .scaleEffect(1.5)
                        .animation(
                            Animation.easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true),
                            value: isSelected
                        )
                }
                
                // Main marker
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
                    
                    // Label (only shows when selected)
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
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
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
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Quick actions grid
                    VStack(alignment: .leading, spacing: 12) {
                        Text("快速搜尋")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(quickActions, id: \.1) { icon, title, color in
                                ModernQuickActionButton(icon: icon, title: title, color: color)
                            }
                        }
                    }
                    
                    // Suggested places
                    VStack(alignment: .leading, spacing: 12) {
                        Text("推薦地點")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 12) {
                            ForEach(0..<3) { index in
                                SuggestedPlaceRow(index: index)
                            }
                        }
                    }
                    
                    // Recent searches
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("最近搜尋")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Button("查看全部") { }
                                .font(.caption)
                                .foregroundColor(.hkBlue)
                        }
                        
                        VStack(spacing: 0) {
                            ForEach(0..<3) { index in
                                RecentSearchRow(index: index)
                            }
                        }
                    }
                }
                .padding(.vertical, 16)
            }
        }
    }

    struct ModernQuickActionButton: View {
        let icon: String
        let title: String
        let color: Color
        
        var body: some View {
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

    struct SuggestedPlaceRow: View {
        let index: Int
        
        let places = [
            ("香港迪士尼樂園", "大嶼山", "theme.park"),
            ("太平山頂", "中西區", "mountain"),
            ("廟街夜市", "油麻地", "nightlife")
        ]
        
        var body: some View {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.hkBlue.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: getIcon(for: index))
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
            .onTapGesture {
                // Handle tap
            }
        }
        
        private func getIcon(for index: Int) -> String {
            switch index {
            case 0: return "sparkles"
            case 1: return "mountain.2"
            case 2: return "sparkles.square.filled.on.square"
            default: return "mappin"
            }
        }
    }

    struct RecentSearchRow: View {
        let index: Int
        
        let searches = [
            ("中環站", "香港中西區"),
            ("旺角朗豪坊", "九龍旺角"),
            ("銅鑼灣時代廣場", "香港島銅鑼灣")
        ]
        
        var body: some View {
            HStack(spacing: 12) {
                Image(systemName: "clock")
                    .font(.callout)
                    .foregroundColor(.gray)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(searches[index].0)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Text(searches[index].1)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "arrow.up.left")
                        .font(.caption)
                        .foregroundColor(.hkBlue)
                }
            }
            .padding(.vertical, 12)
            
            if index < 2 {
                Divider()
                    .padding(.leading, 36)
            }
        }
    }

    // MARK: - Modern Search Results View
    struct ModernSearchResultsView: View {
        let results: [MKMapItem]
        let onSelect: (MKMapItem) -> Void
        
        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("搜尋結果 (\(results.count))")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(.bottom, 16)
                    
                    LazyVStack(spacing: 0) {
                        ForEach(results, id: \.self) { mapItem in
                            ModernSearchResultRow(mapItem: mapItem)
                                .onTapGesture {
                                    onSelect(mapItem)
                                }
                            
                            if mapItem != results.last {
                                Divider()
                                    .padding(.leading, 48)
                            }
                        }
                    }
                }
                .padding(.vertical, 16)
            }
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
                    
                    // Share Button
                    Button(action: {
                        shareLocation(location)
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title3)
                            .frame(width: 44, height: 44)
                            .background(Color(.systemGray6))
                            .foregroundColor(.hkBlue)
                            .cornerRadius(10)
                    }
                }
                
                // Additional Info
                VStack(spacing: 0) {
                    Divider()
                    
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 18))
                                .foregroundColor(.hkBlue)
                            
                            Text("查看照片")
                                .font(.body)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 12)
                    }
                    
                    Divider()
                    
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "info.circle")
                                .font(.system(size: 18))
                                .foregroundColor(.hkBlue)
                            
                            Text("詳細資訊")
                                .font(.body)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 12)
                    }
                }
            }
            .padding(.vertical, 16)
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
        
        private func shareLocation(_ location: Location) {
            let coordinate = location.coordinate
            let mapsURL = URL(string: "http://maps.apple.com/?ll=\(coordinate.latitude),\(coordinate.longitude)&q=\(location.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")!
            
            let activityVC = UIActivityViewController(
                activityItems: [location.name, location.address, mapsURL],
                applicationActivities: nil
            )
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(activityVC, animated: true)
            }
        }
    }

    // MARK: - Modern Transport Options View
    struct ModernTransportOptionsView: View {
        let location: Location
        let userLocation: CLLocationCoordinate2D?
        @Environment(\.presentationMode) var presentationMode
        @State private var selectedMode = "Driving"
        @State private var showNavigationAlert = false
        @State private var navigationAlertMessage = ""
        @State private var isNavigating = false
        
        let transportModes = [
            ("car.fill", "駕車", Color.blue, "Driving"),
            ("bus.fill", "公共交通", Color.green, "Transit"),
            ("figure.walk", "步行", Color.orange, "Walking"),
            ("tram.fill", "輕鐵/電車", Color.purple, "Rail")
        ]
        
        var body: some View {
            NavigationView {
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
                                TransportModeButton(
                                    icon: icon,
                                    title: title,
                                    color: color,
                                    isSelected: selectedMode == mode,
                                    action: {
                                        selectedMode = mode
                                    }
                                )
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
                                    steps: getSteps(for: selectedMode),
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
                        HStack {
                            if isNavigating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding(.trailing, 8)
                            }
                            
                            Text(isNavigating ? "準備中..." : "開始導航")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
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
                    .disabled(isNavigating)
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    leading: Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.hkBlue)
                )
                .alert("導航提示", isPresented: $showNavigationAlert) {
                    Button("確定", role: .cancel) { }
                    if !navigationAlertMessage.isEmpty {
                        Button("打開 Apple 地圖") {
                            openInAppleMaps()
                        }
                    }
                } message: {
                    Text(navigationAlertMessage)
                }
            }
        }
        
        private func startNavigation(mode: String) {
            isNavigating = true
            
            // Simulate navigation preparation
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isNavigating = false
                
                let destinationName = location.name
                let destinationAddress = location.address
                
                // Check if we can open navigation
                if let userCoordinate = userLocation {
                    // Open in Apple Maps with current location as starting point
                    openNavigationInMaps(from: userCoordinate, to: location.coordinate, mode: mode)
                } else {
                    // Just open destination in Apple Maps
                    openDestinationInMaps(mode: mode)
                }
            }
        }
        
        private func openNavigationInMaps(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D, mode: String) {
            let fromPlacemark = MKPlacemark(coordinate: from)
            let toPlacemark = MKPlacemark(coordinate: to)
            
            let fromMapItem = MKMapItem(placemark: fromPlacemark)
            fromMapItem.name = "我的位置"
            
            let toMapItem = MKMapItem(placemark: toPlacemark)
            toMapItem.name = location.name
            
            let launchOptions: [String: Any] = [
                MKLaunchOptionsDirectionsModeKey: getAppleMapsMode(for: mode),
                MKLaunchOptionsShowsTrafficKey: true
            ]
            
            MKMapItem.openMaps(with: [fromMapItem, toMapItem], launchOptions: launchOptions) { success, error in
                if !success {
                    navigationAlertMessage = "無法開啟導航：\(error?.localizedDescription ?? "未知錯誤")"
                    showNavigationAlert = true
                } else {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        
        private func openDestinationInMaps(mode: String) {
            let placemark = MKPlacemark(coordinate: location.coordinate)
            let mapItem = MKMapItem(placemark: placemark)
            mapItem.name = location.name
            
            let launchOptions: [String: Any] = [
                MKLaunchOptionsDirectionsModeKey: getAppleMapsMode(for: mode),
                MKLaunchOptionsShowsTrafficKey: true
            ]
            
            mapItem.openInMaps(launchOptions: launchOptions) { success, error in
                if !success {
                    navigationAlertMessage = "無法開啟導航：\(error?.localizedDescription ?? "未知錯誤")"
                    showNavigationAlert = true
                } else {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        
        private func openInAppleMaps() {
            let placemark = MKPlacemark(coordinate: location.coordinate)
            let mapItem = MKMapItem(placemark: placemark)
            mapItem.name = location.name
            
            mapItem.openInMaps()
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
        
        private func getSteps(for mode: String) -> [String] {
            switch mode {
            case "Driving":
                return ["起點出發", "沿主要道路行駛", "到達目的地"]
            case "Transit":
                return ["步行至車站", "乘坐公共交通", "步行至目的地"]
            case "Walking":
                return ["開始步行", "繼續前行", "到達目的地"]
            case "Rail":
                return ["步行至車站", "乘坐軌道交通", "步行至目的地"]
            default:
                return []
            }
        }
    }

    struct TransportModeButton: View {
        let icon: String
        let title: String
        let color: Color
        let isSelected: Bool
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(isSelected ? color : Color(.systemGray6))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: icon)
                            .font(.system(size: 20))
                            .foregroundColor(isSelected ? .white : color)
                    }
                    
                    Text(title)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? color : .primary)
                }
                .frame(width: 70)
            }
        }
    }

    struct ModernRouteOptionCard: View {
        let mode: String
        let duration: Int
        let distance: Double
        let isRecommended: Bool
        let steps: [String]
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
                
                // Route steps
                VStack(spacing: 12) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        HStack(spacing: 12) {
                            // Step indicator
                            ZStack {
                                Circle()
                                    .fill(getStepColor(for: index))
                                    .frame(width: 24, height: 24)
                                
                                if index == 0 {
                                    Image(systemName: "play.fill")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                } else if index == steps.count - 1 {
                                    Image(systemName: "flag.fill")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                } else {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 8, height: 8)
                                }
                            }
                            
                            // Step description
                            Text(steps[index])
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            // Time indicator
                            Text("\(duration * (index + 1) / steps.count)分鐘")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Additional info
                HStack {
                    Label("預計到達 \(getArrivalTime())", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: onNavigate) {
                        Text("使用此路線")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.hkBlue)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
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
        
        private func getStepColor(for index: Int) -> Color {
            if index == 0 {
                return .green
            } else if index == steps.count - 1 {
                return .red
            } else {
                return .hkBlue
            }
        }
        
        private func getArrivalTime() -> String {
            let arrival = Calendar.current.date(byAdding: .minute, value: duration, to: Date()) ?? Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: arrival)
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
            NavigationView {
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
                            // Apply filters
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
                .navigationBarItems(
                    trailing: Button("完成") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.hkBlue)
                )
            }
        }
    }

    // MARK: - Visual Effect View
    struct VisualEffectView: UIViewRepresentable {
        var effect: UIVisualEffect?
        
        func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView {
            UIVisualEffectView()
        }
        
        func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) {
            uiView.effect = effect
        }
    }

    // MARK: - Rounded Corner Extension
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

    #Preview {
        MapView()
    }
