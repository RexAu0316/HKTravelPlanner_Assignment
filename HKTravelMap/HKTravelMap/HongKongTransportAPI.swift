//
//  HongKongTransportAPI.swift
//  HKTravelMap
//
//  Created by Rex Au on 12/1/2026.
//

// HongKongTransportAPI.swift
import Foundation
import Combine
import CoreLocation

class HongKongTransportAPI {
    static let shared = HongKongTransportAPI()
    
    private let baseURL = "https://data.etabus.gov.hk"
    private let mtrBaseURL = "https://rt.data.gov.hk/v1/transport/mtr"
    private let hkoBaseURL = "https://data.weather.gov.hk/weatherAPI/opendata/opendata.php"
    
    private let session: URLSession
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - MTR API 方法
    
    /// 獲取MTR車站列表
    func fetchMTRStations() -> AnyPublisher<[MTRStation], TransportationError> {
        // 實際API端點
        let urlString = "\(mtrBaseURL)/getSchedule.php"
        
        // 由於實際API需要註冊，這裡返回模擬數據
        return Deferred {
            Future<[MTRStation], TransportationError> { promise in
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                    let mockStations = self.createMockMTRStations()
                    promise(.success(mockStations))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// 獲取MTR實時到站時間
    func fetchMTRRealTimeArrival(stationCode: String, lineCode: String) -> AnyPublisher<[RealTimeArrival], TransportationError> {
        // 實際API端點
        let urlString = "\(mtrBaseURL)/getSchedule.php?station=\(stationCode)&line=\(lineCode)"
        
        return Deferred {
            Future<[RealTimeArrival], TransportationError> { promise in
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
                    let mockArrivals = self.createMockMTRArrivals(stationCode: stationCode, lineCode: lineCode)
                    promise(.success(mockArrivals))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// 獲取MTR服務狀態
    func fetchMTRServiceStatus() -> AnyPublisher<[ServiceStatus], TransportationError> {
        let urlString = "\(mtrBaseURL)/getServiceStatus.php"
        
        return Deferred {
            Future<[ServiceStatus], TransportationError> { promise in
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
                    let mockStatus = self.createMockServiceStatus()
                    promise(.success(mockStatus))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - 巴士API方法
    
    /// 獲取巴士路線
    func fetchBusRoutes(company: BusRoute.BusCompany? = nil) -> AnyPublisher<[BusRoute], TransportationError> {
        // 實際API端點 (香港政府開放數據平台)
        let urlString = "\(baseURL)/v1/transport/kmb/route/"
        
        return Deferred {
            Future<[BusRoute], TransportationError> { promise in
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                    let mockRoutes = self.createMockBusRoutes()
                    promise(.success(mockRoutes))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// 獲取巴士站
    func fetchBusStops(routeNumber: String? = nil) -> AnyPublisher<[BusStop], TransportationError> {
        let urlString = "\(baseURL)/v1/transport/kmb/stop"
        if let route = routeNumber {
            let urlString = "\(urlString)/\(route)"
        }
        
        return Deferred {
            Future<[BusStop], TransportationError> { promise in
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                    let mockStops = self.createMockBusStops()
                    promise(.success(mockStops))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// 獲取巴士實時到站時間
    func fetchBusRealTimeArrival(stopId: String, routeNumber: String) -> AnyPublisher<[RealTimeArrival], TransportationError> {
        let urlString = "\(baseURL)/v1/transport/kmb/eta/\(stopId)/\(routeNumber)"
        
        return Deferred {
            Future<[RealTimeArrival], TransportationError> { promise in
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
                    let mockArrivals = self.createMockBusArrivals(stopId: stopId, routeNumber: routeNumber)
                    promise(.success(mockArrivals))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - 路線規劃API
    
    /// 規劃公共交通路線
    func planRoute(
        origin: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        departureTime: Date = Date(),
        transportModes: [RouteSegment.TransportMode] = [.mtr, .bus, .walk],
        maxWalkingDistance: Double = 2.0, // 公里
        maxTransfers: Int = 3
    ) -> AnyPublisher<[TransportationRoute], TransportationError> {
        
        return Deferred {
            Future<[TransportationRoute], TransportationError> { promise in
                DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                    let mockRoutes = self.createMockRoutes(
                        origin: origin,
                        destination: destination,
                        departureTime: departureTime,
                        transportModes: transportModes
                    )
                    promise(.success(mockRoutes))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// 獲取附近公共交通站點
    func fetchNearbyTransport(
        coordinate: CLLocationCoordinate2D,
        radius: Double = 0.5 // 公里
    ) -> AnyPublisher<[TransportLocation], TransportationError> {
        
        return Deferred {
            Future<[TransportLocation], TransportationError> { promise in
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
                    let mockLocations = self.createMockNearbyTransport(coordinate: coordinate, radius: radius)
                    promise(.success(mockLocations))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - 模擬數據生成
    
    private func createMockMTRStations() -> [MTRStation] {
        return [
            MTRStation(
                stationCode: "CEN",
                chineseName: "中環",
                englishName: "Central",
                lineCode: "IL",
                lineName: "港島線",
                latitude: 22.2819,
                longitude: 114.1586,
                district: "中西區"
            ),
            MTRStation(
                stationCode: "ADM",
                chineseName: "金鐘",
                englishName: "Admiralty",
                lineCode: "IL",
                lineName: "港島線",
                latitude: 22.2790,
                longitude: 114.1659,
                district: "中西區"
            ),
            MTRStation(
                stationCode: "TST",
                chineseName: "尖沙咀",
                englishName: "Tsim Sha Tsui",
                lineCode: "TWL",
                lineName: "荃灣線",
                latitude: 22.2970,
                longitude: 114.1715,
                district: "油尖旺區"
            ),
            MTRStation(
                stationCode: "MOK",
                chineseName: "旺角",
                englishName: "Mong Kok",
                lineCode: "TWL",
                lineName: "荃灣線",
                latitude: 22.3175,
                longitude: 114.1694,
                district: "油尖旺區"
            ),
            MTRStation(
                stationCode: "KOW",
                chineseName: "九龍塘",
                englishName: "Kowloon Tong",
                lineCode: "EAL",
                lineName: "東鐵線",
                latitude: 22.3371,
                longitude: 114.1755,
                district: "九龍城區"
            )
        ]
    }
    
    private func createMockBusRoutes() -> [BusRoute] {
        return [
            BusRoute(
                routeNumber: "101",
                chineseName: "堅尼地城 ↔ 觀塘（裕民坊）",
                englishName: "Kennedy Town ↔ Kwun Tong (Yue Man Square)",
                company: .kmb,
                serviceType: .normal,
                origin: "堅尼地城",
                destination: "觀塘（裕民坊）",
                fare: 10.4,
                journeyTime: 85,
                isCircular: false
            ),
            BusRoute(
                routeNumber: "968",
                chineseName: "元朗（西） ↔ 銅鑼灣（天后）",
                englishName: "Yuen Long (West) ↔ Causeway Bay (Tin Hau)",
                company: .kmb,
                serviceType: .express,
                origin: "元朗（西）",
                destination: "銅鑼灣（天后）",
                fare: 24.7,
                journeyTime: 95,
                isCircular: false
            ),
            BusRoute(
                routeNumber: "A21",
                chineseName: "紅磡站 ↔ 機場",
                englishName: "Hung Hom Station ↔ Airport",
                company: .ctb,
                serviceType: .special,
                origin: "紅磡站",
                destination: "機場",
                fare: 33.0,
                journeyTime: 75,
                isCircular: false
            )
        ]
    }
    
    private func createMockBusStops() -> [BusStop] {
        return [
            BusStop(
                stopId: "001234",
                chineseName: "中環（交易廣場）",
                englishName: "Central (Exchange Square)",
                latitude: 22.2833,
                longitude: 114.1589,
                district: "中西區",
                routes: ["101", "104", "111", "115"]
            ),
            BusStop(
                stopId: "002345",
                chineseName: "旺角中心",
                englishName: "Mong Kok Centre",
                latitude: 22.3190,
                longitude: 114.1690,
                district: "油尖旺區",
                routes: ["1", "1A", "2", "6"]
            )
        ]
    }
    
    private func createMockRoutes(
        origin: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        departureTime: Date,
        transportModes: [RouteSegment.TransportMode]
    ) -> [TransportationRoute] {
        
        let route1 = TransportationRoute(
            origin: "中環站",
            destination: "旺角站",
            totalDuration: 30,
            totalFare: 12.5,
            segments: [
                RouteSegment(
                    transportMode: .walk,
                    lineCode: nil,
                    routeNumber: nil,
                    originStop: "起點",
                    destinationStop: "中環站",
                    duration: 5,
                    fare: 0,
                    instructions: "步行到中環站",
                    distance: 0.3,
                    platform: nil,
                    isWalking: true
                ),
                RouteSegment(
                    transportMode: .mtr,
                    lineCode: "TWL",
                    routeNumber: nil,
                    originStop: "中環站",
                    destinationStop: "旺角站",
                    duration: 20,
                    fare: 12.5,
                    instructions: "乘坐荃灣線到旺角站",
                    distance: 8.5,
                    platform: "3號月台",
                    isWalking: false
                ),
                RouteSegment(
                    transportMode: .walk,
                    lineCode: nil,
                    routeNumber: nil,
                    originStop: "旺角站",
                    destinationStop: "目的地",
                    duration: 5,
                    fare: 0,
                    instructions: "步行到目的地",
                    distance: 0.2,
                    platform: nil,
                    isWalking: true
                )
            ],
            lastUpdated: Date()
        )
        
        let route2 = TransportationRoute(
            origin: "中環",
            destination: "旺角",
            totalDuration: 45,
            totalFare: 10.4,
            segments: [
                RouteSegment(
                    transportMode: .walk,
                    lineCode: nil,
                    routeNumber: nil,
                    originStop: "起點",
                    destinationStop: "中環（交易廣場）巴士站",
                    duration: 8,
                    fare: 0,
                    instructions: "步行到巴士站",
                    distance: 0.5,
                    platform: nil,
                    isWalking: true
                ),
                RouteSegment(
                    transportMode: .bus,
                    lineCode: nil,
                    routeNumber: "101",
                    originStop: "中環（交易廣場）",
                    destinationStop: "旺角中心",
                    duration: 32,
                    fare: 10.4,
                    instructions: "乘坐101號巴士到旺角中心",
                    distance: 9.2,
                    platform: nil,
                    isWalking: false
                ),
                RouteSegment(
                    transportMode: .walk,
                    lineCode: nil,
                    routeNumber: nil,
                    originStop: "旺角中心",
                    destinationStop: "目的地",
                    duration: 5,
                    fare: 0,
                    instructions: "步行到目的地",
                    distance: 0.3,
                    platform: nil,
                    isWalking: true
                )
            ],
            lastUpdated: Date()
        )
        
        return [route1, route2]
    }
    
    private func createMockMTRArrivals(stationCode: String, lineCode: String) -> [RealTimeArrival] {
        let now = Date()
        return [
            RealTimeArrival(
                stationId: stationCode,
                routeId: lineCode,
                destination: "中環",
                estimatedArrivalTime: now.addingTimeInterval(120),
                scheduledArrivalTime: now.addingTimeInterval(120),
                delayInSeconds: 0,
                platform: "1",
                isEstimated: true
            ),
            RealTimeArrival(
                stationId: stationCode,
                routeId: lineCode,
                destination: "荃灣",
                estimatedArrivalTime: now.addingTimeInterval(240),
                scheduledArrivalTime: now.addingTimeInterval(240),
                delayInSeconds: 15,
                platform: "2",
                isEstimated: true
            )
        ]
    }
    
    private func createMockBusArrivals(stopId: String, routeNumber: String) -> [RealTimeArrival] {
        let now = Date()
        return [
            RealTimeArrival(
                stationId: stopId,
                routeId: routeNumber,
                destination: "觀塘",
                estimatedArrivalTime: now.addingTimeInterval(180),
                scheduledArrivalTime: now.addingTimeInterval(180),
                delayInSeconds: 30,
                platform: "A",
                isEstimated: true
            ),
            RealTimeArrival(
                stationId: stopId,
                routeId: routeNumber,
                destination: "觀塘",
                estimatedArrivalTime: now.addingTimeInterval(420),
                scheduledArrivalTime: now.addingTimeInterval(420),
                delayInSeconds: 0,
                platform: "A",
                isEstimated: false
            )
        ]
    }
    
    private func createMockServiceStatus() -> [ServiceStatus] {
        return [
            ServiceStatus(
                serviceType: .mtr,
                status: .normal,
                message: "港鐵服務正常",
                affectedLines: [],
                startTime: Date().addingTimeInterval(-3600),
                expectedResumeTime: nil
            ),
            ServiceStatus(
                serviceType: .bus,
                status: .delay,
                message: "彌敦道交通擠塞，巴士服務可能延誤",
                affectedLines: ["1", "1A", "2", "6", "970X"],
                startTime: Date().addingTimeInterval(-1800),
                expectedResumeTime: Date().addingTimeInterval(3600)
            )
        ]
    }
    
    private func createMockNearbyTransport(coordinate: CLLocationCoordinate2D, radius: Double) -> [TransportLocation] {
        // 這裡創建模擬的附近交通位置
        return []
    }
}

// MARK: - 交通位置組合模型
struct TransportLocation: Identifiable, Codable {
    let id = UUID()
    let name: String
    let type: TransportType
    let latitude: Double
    let longitude: Double
    let distance: Double // 米
    let services: [String] // 服務列表（如路線號碼）
    
    // Computed property for coordinate
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    enum TransportType: String, Codable {
        case mtrStation = "MTR Station"
        case busStop = "Bus Stop"
        case minibusStop = "Minibus Stop"
        case tramStop = "Tram Stop"
        case ferryPier = "Ferry Pier"
        case taxiStand = "Taxi Stand"
    }
}
