//
//  TransportationManager.swift
//  HKTravelMap
//
//  Created by Rex Au on 12/1/2026.
//

// TransportationManager.swift
import Foundation
import Combine
import CoreLocation

class TransportationManager: ObservableObject {
    static let shared = TransportationManager()
    
    private let api = HongKongTransportAPI.shared
    
    // 發布的屬性
    @Published var mtrStations: [MTRStation] = []
    @Published var busRoutes: [BusRoute] = []
    @Published var busStops: [BusStop] = []
    @Published var serviceStatus: [ServiceStatus] = []
    @Published var isLoading = false
    @Published var error: TransportationError?
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // 初始化時加載基本數據
        loadInitialData()
    }
    
    // MARK: - 數據加載方法
    
    private func loadInitialData() {
        // 異步加載MTR車站和巴士路線
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.fetchMTRStations()
            self.fetchBusRoutes()
            self.fetchServiceStatus()
        }
    }
    
    func fetchMTRStations() {
        isLoading = true
        api.fetchMTRStations()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.error = error
                }
            } receiveValue: { [weak self] stations in
                self?.mtrStations = stations
            }
            .store(in: &cancellables)
    }
    
    func fetchBusRoutes(company: BusRoute.BusCompany? = nil) {
        isLoading = true
        api.fetchBusRoutes(company: company)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.error = error
                }
            } receiveValue: { [weak self] routes in
                self?.busRoutes = routes
            }
            .store(in: &cancellables)
    }
    
    func fetchBusStops(routeNumber: String? = nil) {
        isLoading = true
        api.fetchBusStops(routeNumber: routeNumber)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.error = error
                }
            } receiveValue: { [weak self] stops in
                self?.busStops = stops
            }
            .store(in: &cancellables)
    }
    
    func fetchMTRRealTimeArrival(stationCode: String, lineCode: String) -> AnyPublisher<[RealTimeArrival], TransportationError> {
        return api.fetchMTRRealTimeArrival(stationCode: stationCode, lineCode: lineCode)
    }
    
    func fetchBusRealTimeArrival(stopId: String, routeNumber: String) -> AnyPublisher<[RealTimeArrival], TransportationError> {
        return api.fetchBusRealTimeArrival(stopId: stopId, routeNumber: routeNumber)
    }
    
    func fetchServiceStatus() {
        api.fetchMTRServiceStatus()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.error = error
                }
            } receiveValue: { [weak self] status in
                self?.serviceStatus = status
            }
            .store(in: &cancellables)
    }
    
    func planRoute(
        origin: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        departureTime: Date = Date(),
        transportModes: [RouteSegment.TransportMode] = [.mtr, .bus, .walk],
        maxWalkingDistance: Double = 2.0,
        maxTransfers: Int = 3
    ) -> AnyPublisher<[TransportationRoute], TransportationError> {
        
        return api.planRoute(
            origin: origin,
            destination: destination,
            departureTime: departureTime,
            transportModes: transportModes,
            maxWalkingDistance: maxWalkingDistance,
            maxTransfers: maxTransfers
        )
    }
    
    func fetchNearbyTransport(
        coordinate: CLLocationCoordinate2D,
        radius: Double = 0.5
    ) -> AnyPublisher<[TransportLocation], TransportationError> {
        return api.fetchNearbyTransport(coordinate: coordinate, radius: radius)
    }
    
    // MARK: - 工具方法
    
    func findNearestMTRStation(from coordinate: CLLocationCoordinate2D) -> MTRStation? {
        guard !mtrStations.isEmpty else { return nil }
        
        let userLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        return mtrStations.min { station1, station2 in
            let location1 = CLLocation(latitude: station1.latitude, longitude: station1.longitude)
            let location2 = CLLocation(latitude: station2.latitude, longitude: station2.longitude)
            return userLocation.distance(from: location1) < userLocation.distance(from: location2)
        }
    }
    
    func findBusRoutesNearby(coordinate: CLLocationCoordinate2D, radius: Double = 0.5) -> [BusRoute] {
        guard !busStops.isEmpty else { return [] }
        
        let userLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        let nearbyStops = busStops.filter { stop in
            let stopLocation = CLLocation(latitude: stop.latitude, longitude: stop.longitude)
            let distance = userLocation.distance(from: stopLocation)
            return distance <= radius * 1000 // 轉換為米
        }
        
        // 收集附近巴士站的所有路線
        var routeNumbers = Set<String>()
        for stop in nearbyStops {
            routeNumbers.formUnion(stop.routes)
        }
        
        // 返回對應的路線
        return busRoutes.filter { routeNumbers.contains($0.routeNumber) }
    }
    
    // MARK: - 數據持久化
    
    func saveToCache() {
        // 保存到UserDefaults或文件系統
        let encoder = JSONEncoder()
        
        do {
            if let encoded = try? encoder.encode(mtrStations) {
                UserDefaults.standard.set(encoded, forKey: "cachedMTRStations")
            }
            
            if let encoded = try? encoder.encode(busRoutes) {
                UserDefaults.standard.set(encoded, forKey: "cachedBusRoutes")
            }
        }
    }
    
    func loadFromCache() {
        // 從緩存加載
        let decoder = JSONDecoder()
        
        if let data = UserDefaults.standard.data(forKey: "cachedMTRStations"),
           let stations = try? decoder.decode([MTRStation].self, from: data) {
            mtrStations = stations
        }
        
        if let data = UserDefaults.standard.data(forKey: "cachedBusRoutes"),
           let routes = try? decoder.decode([BusRoute].self, from: data) {
            busRoutes = routes
        }
    }
}
