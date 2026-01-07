//
//  Model.swift
//  HKTravelMap
//
//  Created by Rex Au on 7/1/2026.
//

import Foundation
import SwiftUI
import Combine
import CoreLocation

// MARK: - Data Models
struct Location: Identifiable, Codable, Equatable {
    let id = UUID()
    var name: String
    var address: String
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    var isFavorite: Bool = false
    var category: String = "Other"
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    static func == (lhs: Location, rhs: Location) -> Bool {
        lhs.id == rhs.id
    }
}

struct TravelRoute: Identifiable, Codable {
    let id = UUID()
    var startLocation: Location
    var endLocation: Location
    var departureTime: Date
    var estimatedArrivalTime: Date
    var duration: Int // minutes
    var transportationModes: [String]
    var steps: [RouteStep]
    var weatherImpact: String?
    var notes: String?
}

struct RouteStep: Identifiable, Codable {
    let id = UUID()
    var instruction: String
    var transportMode: String
    var duration: Int // minutes
    var distance: Double? // kilometers
    var lineNumber: String?
    var stopName: String?
}

struct WeatherData: Codable {
    var temperature: Double
    var feelsLike: Double
    var humidity: Int
    var condition: String
    var windSpeed: Double
    var rainfall: Double
    var updateTime: Date
    var icon: String?
    
    // 方便獲取圖標系統名稱
    var systemIconName: String {
        guard let icon = icon else { return "sun.max" }
        
        switch icon {
        case "01d", "01n": return "sun.max"
        case "02d", "02n": return "cloud.sun"
        case "03d", "03n": return "cloud"
        case "04d", "04n": return "smoke"
        case "09d", "09n": return "cloud.rain"
        case "10d", "10n": return "cloud.sun.rain"
        case "11d", "11n": return "cloud.bolt"
        case "13d", "13n": return "snow"
        case "50d", "50n": return "cloud.fog"
        default: return "sun.max"
        }
    }
}

// MARK: - Travel Data Manager
class TravelDataManager: ObservableObject {
    static let shared = TravelDataManager()
    
    @Published var currentWeather: WeatherData
    @Published var isLoadingWeather = false
    @Published var weatherError: String?
    
    @Published var locations: [Location] = [
        // Hong Kong Island
        Location(
            name: "Central MTR Station",
            address: "Central, Hong Kong Island",
            latitude: 22.2819,
            longitude: 114.1586,
            isFavorite: true,
            category: "Transport Hub"
        ),
        Location(
            name: "Times Square, Causeway Bay",
            address: "1 Matheson Street, Causeway Bay, Hong Kong",
            latitude: 22.2804,
            longitude: 114.1830,
            isFavorite: true,
            category: "Shopping"
        ),
        Location(
            name: "Hong Kong Convention Centre",
            address: "1 Expo Drive, Wan Chai, Hong Kong",
            latitude: 22.2815,
            longitude: 114.1741,
            category: "Entertainment"
        ),
        Location(
            name: "Victoria Peak Tram",
            address: "33 Garden Road, Central, Hong Kong",
            latitude: 22.2744,
            longitude: 114.1528,
            category: "Entertainment"
        ),
        Location(
            name: "Ocean Park",
            address: "Wong Chuk Hang, Hong Kong Island",
            latitude: 22.2456,
            longitude: 114.1744,
            category: "Entertainment"
        ),
        
        // Kowloon
        Location(
            name: "Tsim Sha Tsui MTR Station",
            address: "Tsim Sha Tsui, Kowloon",
            latitude: 22.2970,
            longitude: 114.1715,
            category: "Transport Hub"
        ),
        Location(
            name: "Langham Place, Mong Kok",
            address: "8 Argyle Street, Mong Kok, Kowloon",
            latitude: 22.3175,
            longitude: 114.1694,
            isFavorite: true,
            category: "Shopping"
        ),
        Location(
            name: "Star Ferry Pier, Tsim Sha Tsui",
            address: "Tsim Sha Tsui, Kowloon",
            latitude: 22.2935,
            longitude: 114.1689,
            category: "Transport Hub"
        ),
        Location(
            name: "Kowloon Park",
            address: "22 Austin Road, Tsim Sha Tsui, Kowloon",
            latitude: 22.3008,
            longitude: 114.1705,
            category: "Entertainment"
        ),
        
        // New Territories
        Location(
            name: "Shatin New Town Plaza",
            address: "18 Sha Tin Centre Street, Sha Tin, New Territories",
            latitude: 22.3792,
            longitude: 114.1869,
            category: "Shopping"
        ),
        Location(
            name: "Hong Kong Science Park",
            address: "Science Park East Avenue, Sha Tin, New Territories",
            latitude: 22.4264,
            longitude: 114.2125,
            category: "Entertainment"
        ),
        
        // Airport
        Location(
            name: "Hong Kong International Airport",
            address: "Chek Lap Kok, Lantau Island",
            latitude: 22.3080,
            longitude: 113.9185,
            category: "Transport Hub"
        ),
        
        // Dining Locations
        Location(
            name: "Maxim's Palace Chinese Restaurant",
            address: "2/F, City Hall Low Block, Central, Hong Kong",
            latitude: 22.2820,
            longitude: 114.1600,
            category: "Dining"
        ),
        Location(
            name: "Tim Ho Wan (Dim Sum)",
            address: "Shop 12A, Hong Kong Station, Central",
            latitude: 22.2847,
            longitude: 114.1592,
            isFavorite: true,
            category: "Dining"
        )
    ]
    
    let recentRoutes: [TravelRoute] = [
        TravelRoute(
            startLocation: Location(
                name: "Tsim Sha Tsui",
                address: "Tsim Sha Tsui MTR Station",
                category: "Transport Hub"
            ),
            endLocation: Location(
                name: "Central",
                address: "Central MTR Station",
                category: "Transport Hub"
            ),
            departureTime: Date().addingTimeInterval(-3600),
            estimatedArrivalTime: Date().addingTimeInterval(-3300),
            duration: 30,
            transportationModes: ["MTR", "Walk"],
            steps: [
                RouteStep(
                    instruction: "Take Tsuen Wan Line from Tsim Sha Tsui Station",
                    transportMode: "MTR",
                    duration: 8,
                    lineNumber: "Tsuen Wan Line",
                    stopName: "Tsim Sha Tsui Station"
                ),
                RouteStep(
                    instruction: "Walk to Exit A",
                    transportMode: "Walk",
                    duration: 5,
                    distance: 0.3
                )
            ],
            weatherImpact: "Good weather, recommended walking"
        ),
        TravelRoute(
            startLocation: Location(
                name: "Causeway Bay",
                address: "Times Square, Causeway Bay",
                category: "Shopping"
            ),
            endLocation: Location(
                name: "Mong Kok",
                address: "Langham Place, Mong Kok",
                category: "Shopping"
            ),
            departureTime: Date().addingTimeInterval(-7200),
            estimatedArrivalTime: Date().addingTimeInterval(-6600),
            duration: 45,
            transportationModes: ["MTR", "Walk"],
            steps: [
                RouteStep(
                    instruction: "Walk to Causeway Bay Station",
                    transportMode: "Walk",
                    duration: 8,
                    distance: 0.5
                ),
                RouteStep(
                    instruction: "Take Island Line to Admiralty",
                    transportMode: "MTR",
                    duration: 5,
                    lineNumber: "Island Line"
                ),
                RouteStep(
                    instruction: "Transfer to Tsuen Wan Line to Mong Kok",
                    transportMode: "MTR",
                    duration: 15,
                    lineNumber: "Tsuen Wan Line"
                )
            ],
            weatherImpact: "Light rain expected, bring umbrella"
        )
    ]
    
    private init() {
        // 初始化一個默認的天氣數據
        self.currentWeather = WeatherData(
            temperature: 25.0,
            feelsLike: 27.0,
            humidity: 70,
            condition: "加載中...",
            windSpeed: 12.0,
            rainfall: 0.0,
            updateTime: Date(),
            icon: nil
        )
        
        // 自動加載天氣數據
        self.fetchRealTimeWeather()
    }
    
    func updateFavoriteStatus(for locationId: UUID, isFavorite: Bool) {
        if let index = locations.firstIndex(where: { $0.id == locationId }) {
            locations[index].isFavorite = isFavorite
            objectWillChange.send()
        }
    }
    
    func fetchRealTimeWeather() {
        // This will be handled by the WeatherService
        isLoadingWeather = true
        weatherError = nil
        
        WeatherService.shared.fetchHongKongWeather { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoadingWeather = false
                
                switch result {
                case .success(let weatherData):
                    self?.currentWeather = weatherData
                case .failure(let error):
                    self?.weatherError = error.localizedDescription
                }
            }
        }
    }
    
    func getRoutes(from: Location, to: Location) -> [TravelRoute] {
        return [
            TravelRoute(
                startLocation: from,
                endLocation: to,
                departureTime: Date(),
                estimatedArrivalTime: Date().addingTimeInterval(2700),
                duration: 45,
                transportationModes: ["MTR", "Walk"],
                steps: [
                    RouteStep(
                        instruction: "Walk to MTR Station",
                        transportMode: "Walk",
                        duration: 8,
                        distance: 0.6
                    ),
                    RouteStep(
                        instruction: "Take Island Line to Central",
                        transportMode: "MTR",
                        duration: 15,
                        lineNumber: "Island Line"
                    )
                ],
                weatherImpact: "Light rain expected, bring umbrella"
            )
        ]
    }
    
    func getNearbyLocations(from coordinate: CLLocationCoordinate2D, radius: Double = 5.0) -> [Location] {
        let userLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        return locations.filter { location in
            let locationPoint = CLLocation(latitude: location.latitude, longitude: location.longitude)
            let distance = userLocation.distance(from: locationPoint) / 1000 // Convert to kilometers
            return distance <= radius
        }
    }
}

// MARK: - Custom Colors
extension Color {
    static let hkBlue = Color(red: 0.0, green: 0.29, blue: 0.55)
    static let hkRed = Color(red: 0.78, green: 0.06, blue: 0.18)
    static let accentOrange = Color(red: 1.0, green: 0.58, blue: 0.0)
    static let lightBackground = Color(red: 0.95, green: 0.95, blue: 0.97)
}
