
    //
    //  TransportationAPIViewController.swift
    //  HKTravelMap
    //
    //  Created by Rex Au on 12/1/2026.
    //

    import SwiftUI
    import Combine
    import CoreLocation

    /// 交通API數據顯示視圖控制器
    class TransportationAPIViewController: ObservableObject {
        static let shared = TransportationAPIViewController()
        
        private let transportManager = TransportationManager.shared
        private var cancellables = Set<AnyCancellable>()
        
        @Published var mtrStations: [MTRStation] = []
        @Published var busRoutes: [BusRoute] = []
        @Published var busStops: [BusStop] = []
        @Published var serviceStatus: [ServiceStatus] = []
        @Published var isLoading = false
        @Published var errorMessage: String?
        @Published var nearbyTransport: [TransportLocation] = []
        
        private init() {
            setupSubscribers()
            loadInitialData()
        }
        
        private func setupSubscribers() {
            // 監聽TransportationManager的數據更新
            transportManager.$mtrStations
                .assign(to: \.mtrStations, on: self)
                .store(in: &cancellables)
            
            transportManager.$busRoutes
                .assign(to: \.busRoutes, on: self)
                .store(in: &cancellables)
            
            transportManager.$busStops
                .assign(to: \.busStops, on: self)
                .store(in: &cancellables)
            
            transportManager.$serviceStatus
                .assign(to: \.serviceStatus, on: self)
                .store(in: &cancellables)
            
            transportManager.$isLoading
                .assign(to: \.isLoading, on: self)
                .store(in: &cancellables)
            
            transportManager.$error
                .map { $0?.localizedDescription }
                .assign(to: \.errorMessage, on: self)
                .store(in: &cancellables)
        }
        
        private func loadInitialData() {
            // 延遲加載以避免啟動時過載
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.refreshAllData()
            }
        }
        
        // MARK: - 公開方法
        
        /// 刷新所有交通數據
        func refreshAllData() {
            isLoading = true
            errorMessage = nil
            
            transportManager.fetchMTRStations()
            transportManager.fetchBusRoutes()
            transportManager.fetchServiceStatus()
            
            // 1秒後加載巴士站數據
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.transportManager.fetchBusStops()
            }
        }
        
        /// 刷新MTR數據
        func refreshMTRData() {
            transportManager.fetchMTRStations()
            transportManager.fetchServiceStatus()
        }
        
        /// 刷新巴士數據
        func refreshBusData() {
            transportManager.fetchBusRoutes()
            transportManager.fetchBusStops()
        }
        
        /// 獲取MTR車站的實時到站時間
        func fetchMTRArrivals(for station: MTRStation) {
            transportManager.fetchMTRRealTimeArrival(stationCode: station.stationCode, lineCode: station.lineCode)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    if case .failure(let error) = completion {
                        self.errorMessage = "無法獲取到站時間: \(error.localizedDescription)"
                    }
                } receiveValue: { arrivals in
                    // 這裡可以處理到站時間數據
                    print("獲取到 \(arrivals.count) 個到站時間")
                }
                .store(in: &cancellables)
        }
        
        /// 獲取巴士站的實時到站時間
        func fetchBusArrivals(for stop: BusStop, routeNumber: String) {
            transportManager.fetchBusRealTimeArrival(stopId: stop.stopId, routeNumber: routeNumber)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    if case .failure(let error) = completion {
                        self.errorMessage = "無法獲取巴士到站時間: \(error.localizedDescription)"
                    }
                } receiveValue: { arrivals in
                    // 這裡可以處理到站時間數據
                    print("獲取到 \(arrivals.count) 個巴士到站時間")
                }
                .store(in: &cancellables)
        }
        
        /// 獲取附近交通設施
        func fetchNearbyTransport(coordinate: CLLocationCoordinate2D, radius: Double = 0.5) {
            transportManager.fetchNearbyTransport(coordinate: coordinate, radius: radius)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    if case .failure(let error) = completion {
                        self.errorMessage = "無法獲取附近交通: \(error.localizedDescription)"
                    }
                } receiveValue: { locations in
                    self.nearbyTransport = locations
                }
                .store(in: &cancellables)
        }
        
        /// 規劃路線
        func planRoute(
            from origin: CLLocationCoordinate2D,
            to destination: CLLocationCoordinate2D,
            completion: @escaping (Result<[TransportationRoute], Error>) -> Void
        ) {
            transportManager.planRoute(origin: origin, destination: destination)
                .receive(on: DispatchQueue.main)
                .sink { result in
                    switch result {
                    case .finished:
                        break
                    case .failure(let error):
                        completion(.failure(error))
                    }
                } receiveValue: { routes in
                    completion(.success(routes))
                }
                .store(in: &cancellables)
        }
        
        // MARK: - 工具方法
        
        /// 搜索MTR車站
        func searchMTRStations(query: String) -> [MTRStation] {
            guard !query.isEmpty else { return mtrStations }
            
            return mtrStations.filter { station in
                station.chineseName.localizedCaseInsensitiveContains(query) ||
                station.englishName.localizedCaseInsensitiveContains(query) ||
                station.stationCode.localizedCaseInsensitiveContains(query)
            }
        }
        
        /// 搜索巴士路線
        func searchBusRoutes(query: String) -> [BusRoute] {
            guard !query.isEmpty else { return busRoutes }
            
            return busRoutes.filter { route in
                route.routeNumber.localizedCaseInsensitiveContains(query) ||
                route.chineseName.localizedCaseInsensitiveContains(query) ||
                route.englishName.localizedCaseInsensitiveContains(query) ||
                route.origin.localizedCaseInsensitiveContains(query) ||
                route.destination.localizedCaseInsensitiveContains(query)
            }
        }
        
        /// 獲取指定線路的MTR車站
        func getMTRStations(for lineCode: String) -> [MTRStation] {
            return mtrStations.filter { $0.lineCode == lineCode }
        }
        
        /// 獲取指定公司的巴士路線
        func getBusRoutes(for company: BusRoute.BusCompany) -> [BusRoute] {
            return busRoutes.filter { $0.company == company }
        }
        
        /// 獲取服務狀態消息
        func getServiceStatusMessages() -> [String] {
            return serviceStatus.map { status in
                "\(status.serviceType.rawValue): \(status.message)"
            }
        }
        
        /// 檢查是否有服務中斷
        func hasServiceDisruption() -> Bool {
            return serviceStatus.contains { $0.status != .normal }
        }
        
        /// 獲取服務中斷信息
        func getServiceDisruptions() -> [ServiceStatus] {
            return serviceStatus.filter { $0.status != .normal }
        }
    }
    
