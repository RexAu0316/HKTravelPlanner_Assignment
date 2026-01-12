//
//  TransportationModels.swift
//  HKTravelMap
//
//  Created by Rex Au on 12/1/2026.
//

// TransportationModels.swift
import Foundation
import CoreLocation

// MARK: - MTR 車站模型
struct MTRStation: Identifiable, Codable, Equatable {
    let id = UUID()
    let stationCode: String
    let chineseName: String
    let englishName: String
    let lineCode: String
    let lineName: String
    let latitude: Double
    let longitude: Double
    let district: String
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    static func == (lhs: MTRStation, rhs: MTRStation) -> Bool {
        lhs.stationCode == rhs.stationCode
    }
}

// MARK: - 巴士路線模型
struct BusRoute: Identifiable, Codable, Equatable {
    let id = UUID()
    let routeNumber: String
    let chineseName: String
    let englishName: String
    let company: BusCompany
    let serviceType: BusServiceType
    let origin: String
    let destination: String
    let fare: Double?
    let journeyTime: Int? // 分鐘
    let isCircular: Bool
    
    enum BusCompany: String, Codable {
        case kmb = "KMB"
        case ctb = "CTB"
        case nwfb = "NWFB"
        case lwb = "LWB"
        case nlb = "NLB"
        case gmb = "GMB"
    }
    
    enum BusServiceType: String, Codable {
        case normal = "Normal"
        case express = "Express"
        case overnight = "Overnight"
        case special = "Special"
    }
}

// MARK: - 巴士站模型
struct BusStop: Identifiable, Codable, Equatable {
    let id = UUID()
    let stopId: String
    let chineseName: String
    let englishName: String
    let latitude: Double
    let longitude: Double
    let district: String
    let routes: [String] // 路線編號列表
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - 實時到站時間
struct RealTimeArrival: Identifiable, Codable {
    let id = UUID()
    let stationId: String
    let routeId: String
    let destination: String
    let estimatedArrivalTime: Date
    let scheduledArrivalTime: Date
    let delayInSeconds: Int
    let platform: String?
    let isEstimated: Bool
}

// MARK: - 路線規劃結果
struct TransportationRoute: Identifiable, Codable {
    let id = UUID()
    let origin: String
    let destination: String
    let totalDuration: Int // 分鐘
    let totalFare: Double
    let segments: [RouteSegment]
    let lastUpdated: Date
}

struct RouteSegment: Identifiable, Codable {
    let id = UUID()
    let transportMode: TransportMode
    let lineCode: String?
    let routeNumber: String?
    let originStop: String
    let destinationStop: String
    let duration: Int // 分鐘
    let fare: Double
    let instructions: String
    let distance: Double? // 公里
    let platform: String?
    let isWalking: Bool
    
    enum TransportMode: String, Codable {
        case mtr = "MTR"
        case bus = "Bus"
        case minibus = "Minibus"
        case tram = "Tram"
        case ferry = "Ferry"
        case taxi = "Taxi"
        case walk = "Walk"
        case lightRail = "Light Rail"
    }
}

// MARK: - 服務狀態
struct ServiceStatus: Identifiable, Codable {
    let id = UUID()
    let serviceType: ServiceType
    let status: Status
    let message: String
    let affectedLines: [String]
    let startTime: Date
    let expectedResumeTime: Date?
    
    enum ServiceType: String, Codable {
        case mtr = "MTR"
        case bus = "Bus"
        case tram = "Tram"
        case ferry = "Ferry"
        case all = "All"
    }
    
    enum Status: String, Codable {
        case normal = "Normal"
        case delay = "Delay"
        case suspended = "Suspended"
        case diverted = "Diverted"
        case special = "Special"
    }
}

// MARK: - API錯誤類型
enum TransportationError: Error, LocalizedError {
    case networkError(Error)
    case invalidResponse
    case invalidData
    case rateLimited
    case serviceUnavailable
    case noRouteFound
    
    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "網絡錯誤: \(error.localizedDescription)"
        case .invalidResponse:
            return "服務器返回無效響應"
        case .invalidData:
            return "數據格式錯誤"
        case .rateLimited:
            return "請求過於頻繁，請稍後再試"
        case .serviceUnavailable:
            return "服務暫時不可用"
        case .noRouteFound:
            return "未找到可行路線"
        }
    }
}
