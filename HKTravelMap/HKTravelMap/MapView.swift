//
//  MapView.swift
//  HKTravelMap
//
//  Created by Rex Au on 7/1/2026.
//

import SwiftUI
import MapKit
import CoreLocation
import Combine

struct MapView: View {
    @ObservedObject var travelDataManager = TravelDataManager.shared
    @StateObject private var locationManager = LocationManager()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 22.3193, longitude: 114.1694),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var selectedLocation: Location?
    @State private var searchText = ""
    @State private var showSearchResults = false
    @State private var searchResults: [MKMapItem] = []
    @State private var showLocationAlert = false
    @State private var locationAlertMessage = ""
    @State private var isLocationAvailable = false
    
    var body: some View {
        ZStack {
            // Main Map View
            Map(
                coordinateRegion: $region,
                interactionModes: .all,
                showsUserLocation: true,
                userTrackingMode: .constant(isLocationAvailable ? .follow : .none)
            )
            .mapStyle(.standard)
            .edgesIgnoringSafeArea(.top)
            
            // Overlay UI Elements
            VStack(spacing: 0) {
                // Top Search Bar
                VStack(spacing: 0) {
                    HStack {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                                .padding(.leading, 8)
                            
                            TextField("搜尋地點或地址", text: $searchText)
                                .padding(.vertical, 10)
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
                                        .padding(.trailing, 8)
                                }
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                        
                        Button(action: {
                            performSearch()
                        }) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.title2)
                                .foregroundColor(.hkBlue)
                        }
                        .disabled(searchText.isEmpty)
                    }
                    .padding(.horizontal)
                    .padding(.top, 60)
                }
                .background(
                    LinearGradient(
                        colors: [Color.black.opacity(0.2), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .edgesIgnoringSafeArea(.top)
                )
                
                Spacer()
                
                // Bottom Controls
                VStack(spacing: 20) {
                    // Location Details Sheet
                    if let location = selectedLocation {
                        LocationDetailSheet(location: location) {
                            selectedLocation = nil
                        }
                        .transition(.move(edge: .bottom))
                    }
                    
                    // Control Buttons
                    HStack {
                        Spacer()
                        
                        VStack(spacing: 15) {
                            // Current Location Button
                            Button(action: {
                                centerOnUserLocation()
                            }) {
                                Image(systemName: locationManager.isLocationAuthorized ? "location.fill" : "location.slash.fill")
                                    .font(.title2)
                                    .frame(width: 50, height: 50)
                                    .background(Color.white)
                                    .foregroundColor(locationManager.isLocationAuthorized ? .hkBlue : .gray)
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                            }
                            
                            // Map Type Toggle
                            Button(action: {
                                // Toggle map style (not fully implemented in iOS 15-16 Map)
                            }) {
                                Image(systemName: "map")
                                    .font(.title2)
                                    .frame(width: 50, height: 50)
                                    .background(Color.white)
                                    .foregroundColor(.hkBlue)
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                            }
                            
                            // Nearby Places
                            Button(action: {
                                showNearbyPlaces()
                            }) {
                                Image(systemName: "mappin.and.ellipse")
                                    .font(.title2)
                                    .frame(width: 50, height: 50)
                                    .background(Color.white)
                                    .foregroundColor(.hkRed)
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                            }
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .navigationTitle("地圖")
        .navigationBarHidden(true)
        .onAppear {
            locationManager.requestPermission()
        }
        .onReceive(locationManager.$userLocation) { newLocation in
            if let location = newLocation, !isLocationAvailable {
                // First time getting location
                withAnimation {
                    region.center = location.coordinate
                    region.span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                    isLocationAvailable = true
                }
            }
        }
        .onReceive(locationManager.$locationError) { error in
            if let error = error {
                showLocationAlert = true
                locationAlertMessage = error
            }
        }
        .alert("位置服務", isPresented: $showLocationAlert) {
            Button("OK") {}
        } message: {
            Text(locationAlertMessage)
        }
    }
    
    private func centerOnUserLocation() {
        if let userLocation = locationManager.userLocation {
            withAnimation {
                region.center = userLocation.coordinate
                region.span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            }
        } else if !locationManager.isLocationAuthorized {
            locationAlertMessage = "位置服務未啟用。請前往設定 > 隱私權 > 定位服務中啟用。"
            showLocationAlert = true
        } else {
            locationAlertMessage = "正在取得位置資訊..."
            showLocationAlert = true
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = region
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            DispatchQueue.main.async {
                if let response = response {
                    searchResults = response.mapItems
                    showSearchResults = true
                    
                    // Move map to first result
                    if let firstResult = response.mapItems.first {
                        withAnimation {
                            region.center = firstResult.placemark.coordinate
                            region.span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                        }
                    }
                } else if let error = error {
                    locationAlertMessage = "搜尋失敗: \(error.localizedDescription)"
                    showLocationAlert = true
                }
            }
        }
    }
    
    private func showNearbyPlaces() {
        if let userLocation = locationManager.userLocation {
            withAnimation {
                region.center = userLocation.coordinate
                region.span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            }
        } else {
            centerOnUserLocation()
        }
    }
}

// MARK: - Location Manager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    @Published var userLocation: CLLocation?
    @Published var isLocationAuthorized = false
    @Published var locationError: String?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestPermission() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()  // ← This only requests permission
        case .authorizedWhenInUse, .authorizedAlways:
            isLocationAuthorized = true
            locationManager.startUpdatingLocation()  // ← This starts tracking
        case .denied, .restricted:
            isLocationAuthorized = false
            locationError = "位置服務已停用。請前往設定啟用。"
        @unknown default:
            break
        }
    }
    
    func startUpdating() {
        if isLocationAuthorized {
            locationManager.startUpdatingLocation()
        }
    }
    
    func stopUpdating() {
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.userLocation = location
            self.locationError = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.isLocationAuthorized = true
                self.locationError = nil
                self.locationManager.startUpdatingLocation()
            case .denied, .restricted:
                self.isLocationAuthorized = false
                self.locationError = "位置服務已停用。請前往設定啟用。"
                self.stopUpdating()
            case .notDetermined:
                self.isLocationAuthorized = false
            @unknown default:
                break
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.locationError = "取得位置失敗: \(error.localizedDescription)"
        }
    }
}

// MARK: - Other supporting views (unchanged)

struct MapMarker: View {
    let location: Location
    @Binding var selectedLocation: Location?
    
    var body: some View {
        Button(action: {
            withAnimation {
                selectedLocation = location
            }
        }) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 36, height: 36)
                        .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                    
                    Image(systemName: location.isFavorite ? "star.fill" : "mappin.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(location.isFavorite ? .yellow : .hkRed)
                }
                
                Text(location.name.components(separatedBy: ",").first ?? "")
                    .font(.system(size: 10, weight: .medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(4)
                    .offset(y: 5)
            }
        }
    }
}

struct LocationDetailSheet: View {
    let location: Location
    let onClose: () -> Void
    
    @State private var isFavorite: Bool
    @State private var showDirections = false
    
    init(location: Location, onClose: @escaping () -> Void) {
        self.location = location
        self.onClose = onClose
        _isFavorite = State(initialValue: location.isFavorite)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(location.name)
                        .font(.headline)
                        .lineLimit(2)
                    
                    Text(location.address)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            
            // Category
            if !location.category.isEmpty && location.category != "Search Result" {
                HStack {
                    Image(systemName: iconForCategory(location.category))
                        .font(.caption)
                        .foregroundColor(colorForCategory(location.category))
                    
                    Text(location.category)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                Button(action: {
                    openInMaps()
                }) {
                    HStack {
                        Image(systemName: "arrow.triangle.turn.up.right.diamond")
                        Text("導航")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.hkBlue)
                    .foregroundColor(.white)
                    .font(.subheadline)
                    .cornerRadius(10)
                }
                
                Button(action: {
                    toggleFavorite()
                }) {
                    HStack {
                        Image(systemName: isFavorite ? "star.fill" : "star")
                        Text(isFavorite ? "已收藏" : "收藏")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(isFavorite ? Color.yellow.opacity(0.2) : Color(.systemGray5))
                    .foregroundColor(isFavorite ? .yellow : .primary)
                    .font(.subheadline)
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: -5)
        .padding(.horizontal)
        .padding(.bottom, 10)
    }
    
    private func openInMaps() {
        let coordinate = CLLocationCoordinate2D(
            latitude: location.latitude,
            longitude: location.longitude
        )
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = location.name
        
        let launchOptions = [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ]
        mapItem.openInMaps(launchOptions: launchOptions)
    }
    
    private func toggleFavorite() {
        isFavorite.toggle()
        TravelDataManager.shared.updateFavoriteStatus(for: location.id, isFavorite: isFavorite)
    }
    
    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "Transport Hub": return "train.side.front.car"
        case "Shopping": return "bag.fill"
        case "Dining": return "fork.knife"
        case "Entertainment": return "film.fill"
        default: return "mappin.circle.fill"
        }
    }
    
    private func colorForCategory(_ category: String) -> Color {
        switch category {
        case "Transport Hub": return .blue
        case "Shopping": return .pink
        case "Dining": return .orange
        case "Entertainment": return .purple
        default: return .gray
        }
    }
}

#Preview {
    NavigationView {
        MapView()
    }
}
