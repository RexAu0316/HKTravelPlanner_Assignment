//
//  Models.swift
//  HKTravelPlanner_Assignment
//
//  Created by Rex Au on 2/1/2026.
//

//
//  Models.swift
//  HKTravelPlanner_Assignment
//
//  Created by Rex Au on 31/12/2025.
//

import Foundation
import SwiftUI

// MARK: - Data Models
struct Location: Identifiable, Codable, Equatable {
    let id = UUID()
    var name: String
    var address: String
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    var isFavorite: Bool = false
    var category: String = "Other"
    
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
    var humidity: Int
    var condition: String
    var windSpeed: Double
    var rainfall: Double
    var updateTime: Date
}

// MARK: - Sample Data
class SampleData {
    static let shared = SampleData()
    
    let locations: [Location] = [
        Location(
            name: "Times Square, Causeway Bay",
            address: "1 Matheson Street, Causeway Bay, Hong Kong",
            latitude: 22.2804,
            longitude: 114.1830,
            category: "Shopping"
        ),
        Location(
            name: "Central MTR Station",
            address: "Central, Hong Kong",
            latitude: 22.2819,
            longitude: 114.1586,
            category: "Transport Hub"
        ),
        Location(
            name: "Hong Kong Convention Centre",
            address: "1 Expo Drive, Wan Chai, Hong Kong",
            latitude: 22.2815,
            longitude: 114.1741,
            category: "Entertainment"
        ),
        Location(
            name: "Langham Place, Mong Kok",
            address: "8 Argyle Street, Mong Kok, Hong Kong",
            latitude: 22.3175,
            longitude: 114.1694,
            isFavorite: true,
            category: "Shopping"
        ),
        Location(
            name: "Star Ferry Pier, Tsim Sha Tsui",
            address: "Tsim Sha Tsui, Hong Kong",
            latitude: 22.2935,
            longitude: 114.1689,
            category: "Transport Hub"
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
        )
    ]
    
    let currentWeather = WeatherData(
        temperature: 25.5,
        humidity: 70,
        condition: "Cloudy",
        windSpeed: 12.0,
        rainfall: 0.0,
        updateTime: Date()
    )
    
    func getRoutes(from: Location, to: Location) -> [TravelRoute] {
        // Simulate route planning
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
            ),
            TravelRoute(
                startLocation: from,
                endLocation: to,
                departureTime: Date(),
                estimatedArrivalTime: Date().addingTimeInterval(3600),
                duration: 60,
                transportationModes: ["Bus", "Walk"],
                steps: [
                    RouteStep(
                        instruction: "Walk to Bus Stop",
                        transportMode: "Walk",
                        duration: 5,
                        distance: 0.4
                    ),
                    RouteStep(
                        instruction: "Take Bus 101",
                        transportMode: "Bus",
                        duration: 40,
                        lineNumber: "101"
                    )
                ],
                weatherImpact: "Heavy traffic, longer travel time expected"
            )
        ]
    }
}

// MARK: - Custom Colors
extension Color {
    static let hkBlue = Color(red: 0.0, green: 0.29, blue: 0.55)
    static let hkRed = Color(red: 0.78, green: 0.06, blue: 0.18)
    static let accentOrange = Color(red: 1.0, green: 0.58, blue: 0.0)
    static let lightBackground = Color(red: 0.95, green: 0.95, blue: 0.97)
}
