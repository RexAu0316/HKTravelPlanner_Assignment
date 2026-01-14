//
//  HomeView.swift
//  HKTravelMap
//
//  Created by Rex Au on 7/1/2026.
//

import SwiftUI
import MapKit
import CoreLocation

struct HomeView: View {
    @State private var startLocation = ""
    @State private var endLocation = ""
    @State private var isSearching = false
    @State private var showRouteResults = false
    @State private var selectedDate = Date()
    @State private var showingLocationPicker = false
    @State private var showingDestinationPicker = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var showWelcomeGuide = false
    @State private var showFavoritesView = false
    @State private var showHistoryView = false
    @State private var selectedTab = 0
    @State private var showCurrentLocationOption = false
    @State private var showSavedRoutesView = false
    
    @AppStorage("userName") private var userName = "Guest"
    @AppStorage("isFirstLaunch") private var isFirstLaunch = true
    @AppStorage("saveHistory") private var saveHistory = true
    @AppStorage("autoUpdateWeather") private var autoUpdateWeather = true
    
    @ObservedObject var travelDataManager = TravelDataManager.shared
    @StateObject private var locationManager = LocationManager.shared
    
    var body: some View {
        HomeMainContainer(
            startLocation: $startLocation,
            endLocation: $endLocation,
            isSearching: $isSearching,
            showRouteResults: $showRouteResults,
            selectedDate: $selectedDate,
            showingLocationPicker: $showingLocationPicker,
            showingDestinationPicker: $showingDestinationPicker,
            showErrorAlert: $showErrorAlert,
            errorMessage: $errorMessage,
            showWelcomeGuide: $showWelcomeGuide,
            showFavoritesView: $showFavoritesView,
            showHistoryView: $showHistoryView,
            selectedTab: $selectedTab,
            showCurrentLocationOption: $showCurrentLocationOption,
            showSavedRoutesView: $showSavedRoutesView,
            userName: userName,
            saveHistory: saveHistory,
            autoUpdateWeather: autoUpdateWeather,
            travelDataManager: travelDataManager,
            locationManager: locationManager,
            performRoutePlanning: performRoutePlanning,
            setupInitialData: setupInitialData,
            showError: showError
        )
        .sheet(isPresented: $showRouteResults) {
            if !startLocation.isEmpty && !endLocation.isEmpty {
                RouteResultsView(routes: createMockRoutes())
            }
        }
        .sheet(isPresented: $showWelcomeGuide) {
            WelcomeGuideView()
        }
        .sheet(isPresented: $showFavoritesView) {
            FavoritesView()
        }
        .sheet(isPresented: $showSavedRoutesView) {
            SavedRoutesView()
        }


        .alert("提示", isPresented: $showErrorAlert) {
            Button("確定", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            setupInitialData()
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Helper Functions
    
    private func getGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let greeting: String
        
        switch hour {
        case 5..<12: greeting = "早晨"
        case 12..<18: greeting = "午安"
        case 18..<22: greeting = "晚上好"
        default: greeting = "你好"
        }
        
        return "\(greeting)，\(userName)！"
    }
    
    private func performRoutePlanning() {
        guard !startLocation.isEmpty, !endLocation.isEmpty else {
            showError(message: "請輸入起點和目的地")
            return
        }
        
        isSearching = true
        
        // 添加觸覺反饋
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // 模擬 API 調用延遲
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isSearching = false
            
            // 創建模擬路線
            let mockRoute = TravelRoute(
                startLocation: Location(
                    name: startLocation,
                    address: "自定義起點",
                    latitude: 0.0,
                    longitude: 0.0,
                    isFavorite: false,
                    category: "Custom"
                ),
                endLocation: Location(
                    name: endLocation,
                    address: "自定義目的地",
                    latitude: 0.0,
                    longitude: 0.0,
                    isFavorite: false,
                    category: "Custom"
                ),
                departureTime: selectedDate,
                estimatedArrivalTime: selectedDate.addingTimeInterval(TimeInterval(45 * 60)),
                duration: 45,
                transportationModes: ["MTR", "步行"],
                steps: [
                    RouteStep(
                        instruction: "從 \(startLocation) 出發",
                        transportMode: "Walk",
                        duration: 8,
                        distance: 0.5,
                        lineNumber: nil,
                        stopName: nil,
                        platform: nil
                    ),
                    RouteStep(
                        instruction: "乘坐港鐵前往 \(endLocation)",
                        transportMode: "MTR",
                        duration: 25,
                        distance: 8.5,
                        lineNumber: "港島線",
                        stopName: "金鐘站",
                        platform: "3號月台"
                    ),
                    RouteStep(
                        instruction: "步行到達 \(endLocation)",
                        transportMode: "Walk",
                        duration: 12,
                        distance: 0.8,
                        lineNumber: nil,
                        stopName: nil,
                        platform: nil
                    )
                ],
                weatherImpact: travelDataManager.currentWeather.condition.contains("雨") ? "有雨，建議帶傘" : "天氣晴朗，適合步行",
                notes: "建議使用八達通付款"
            )
            
            // 保存到最近搜索（如果啟用）
            if saveHistory {
                travelDataManager.addRecentRoute(mockRoute)
            }
            
            // 顯示結果
            showRouteResults = true
        }
    }
    
    private func createMockRoutes() -> [TravelRoute] {
        return [
            TravelRoute(
                startLocation: Location(
                    name: startLocation,
                    address: "自定義起點",
                    latitude: 0.0,
                    longitude: 0.0,
                    isFavorite: false,
                    category: "Custom"
                ),
                endLocation: Location(
                    name: endLocation,
                    address: "自定義目的地",
                    latitude: 0.0,
                    longitude: 0.0,
                    isFavorite: false,
                    category: "Custom"
                ),
                departureTime: selectedDate,
                estimatedArrivalTime: selectedDate.addingTimeInterval(TimeInterval(45 * 60)),
                duration: 45,
                transportationModes: ["MTR", "步行"],
                steps: [
                    RouteStep(
                        instruction: "從 \(startLocation) 出發",
                        transportMode: "Walk",
                        duration: 8,
                        distance: 0.5,
                        lineNumber: nil,
                        stopName: nil,
                        platform: nil
                    ),
                    RouteStep(
                        instruction: "乘坐港鐵前往 \(endLocation)",
                        transportMode: "MTR",
                        duration: 25,
                        distance: 8.5,
                        lineNumber: "港島線",
                        stopName: "金鐘站",
                        platform: "3號月台"
                    ),
                    RouteStep(
                        instruction: "步行到達 \(endLocation)",
                        transportMode: "Walk",
                        duration: 12,
                        distance: 0.8,
                        lineNumber: nil,
                        stopName: nil,
                        platform: nil
                    )
                ],
                weatherImpact: travelDataManager.currentWeather.condition.contains("雨") ? "有雨，建議帶傘" : "天氣晴朗，適合步行",
                notes: "建議使用八達通付款"
            )
        ]
    }
    
    private func showError(message: String) {
        errorMessage = message
        showErrorAlert = true
        
        // 添加錯誤震動反饋
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    private func setupInitialData() {
        // 檢查是否需要天氣數據
        if travelDataManager.currentWeather.condition == "加載中..." {
            travelDataManager.fetchRealTimeWeather()
        }
        
        // 設置自動天氣更新
        if autoUpdateWeather {
            setupWeatherAutoRefresh()
        }
        
        // 檢查位置權限
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestPermission()
        }
        
        // 首次啟動引導
        if isFirstLaunch {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showWelcomeGuide = true
            }
            isFirstLaunch = false
        }
    }
    
    private func setupWeatherAutoRefresh() {
        // 每30分鐘自動更新天氣
        Timer.scheduledTimer(withTimeInterval: 1800, repeats: true) { _ in
            travelDataManager.fetchRealTimeWeather()
        }
    }
}

// MARK: - Home Main Container
struct HomeMainContainer: View {
    @Binding var startLocation: String
    @Binding var endLocation: String
    @Binding var isSearching: Bool
    @Binding var showRouteResults: Bool
    @Binding var selectedDate: Date
    @Binding var showingLocationPicker: Bool
    @Binding var showingDestinationPicker: Bool
    @Binding var showErrorAlert: Bool
    @Binding var errorMessage: String
    @Binding var showWelcomeGuide: Bool
    @Binding var showFavoritesView: Bool
    @Binding var showHistoryView: Bool
    @Binding var selectedTab: Int
    @Binding var showCurrentLocationOption: Bool
    @Binding var showSavedRoutesView: Bool
    
    let userName: String
    let saveHistory: Bool
    let autoUpdateWeather: Bool
    let travelDataManager: TravelDataManager
    let locationManager: LocationManager
    
    let performRoutePlanning: () -> Void
    let setupInitialData: () -> Void
    let showError: (String) -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with Welcome
                    HeaderSection(userName: userName)
                    
                    // Weather Card
                    WeatherSection(
                        travelDataManager: travelDataManager,
                        isLoadingWeather: travelDataManager.isLoadingWeather,
                        weatherError: travelDataManager.weatherError
                    )
                    
                    // Search Card
                    SearchSection(
                        startLocation: $startLocation,
                        endLocation: $endLocation,
                        selectedDate: $selectedDate,
                        showingLocationPicker: $showingLocationPicker,
                        showingDestinationPicker: $showingDestinationPicker,
                        showCurrentLocationOption: $showCurrentLocationOption,
                        isSearching: $isSearching,
                        locationManager: locationManager,
                        travelDataManager: travelDataManager,
                        performRoutePlanning: performRoutePlanning,
                        showError: showError
                    )
                    
                    // Quick Actions
                    QuickActionsSection(
                        selectedTab: $selectedTab,
                        showFavoritesView: $showFavoritesView,
                        showHistoryView: $showHistoryView,
                        showSavedRoutesView: $showSavedRoutesView
                    )
                    
                    // Recent Searches
                    if !travelDataManager.recentRoutes.isEmpty && saveHistory {
                        RecentSearchesSection(
                            travelDataManager: travelDataManager,
                            showHistoryView: $showHistoryView,
                            onReplan: { route in
                                startLocation = route.startLocation.name
                                endLocation = route.endLocation.name
                                selectedDate = Date()
                                
                                // 添加觸覺反饋
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                
                                // 自動開始規劃路線
                                performRoutePlanning()
                            }
                        )
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.top, 20)
                .padding(.horizontal, 16)
            }
            .background(Color(.systemGroupedBackground))
        }
    }
}

// MARK: - Header Section
struct HeaderSection: View {
    let userName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(getGreeting())
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("香港智能旅遊規劃")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    // 暫時跳轉到設定頁面
                    // 這個功能需要通過其他方式實現
                }) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.hkBlue)
                }
            }
            
            Divider()
        }
    }
    
    private func getGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let greeting: String
        
        switch hour {
        case 5..<12: greeting = "早晨"
        case 12..<18: greeting = "午安"
        case 18..<22: greeting = "晚上好"
        default: greeting = "你好"
        }
        
        return "\(greeting)，\(userName)！"
    }
}

// MARK: - Weather Section
struct WeatherSection: View {
    @ObservedObject var travelDataManager: TravelDataManager
    let isLoadingWeather: Bool
    let weatherError: String?
    
    var body: some View {
        Group {
            if isLoadingWeather {
                WeatherLoadingView()
            } else if let error = weatherError {
                WeatherErrorView(error: error) {
                    travelDataManager.fetchRealTimeWeather()
                }
            } else {
                ModernWeatherCard(weather: travelDataManager.currentWeather)
            }
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Search Section
struct SearchSection: View {
    @Binding var startLocation: String
    @Binding var endLocation: String
    @Binding var selectedDate: Date
    @Binding var showingLocationPicker: Bool
    @Binding var showingDestinationPicker: Bool
    @Binding var showCurrentLocationOption: Bool
    @Binding var isSearching: Bool
    
    let locationManager: LocationManager
    let travelDataManager: TravelDataManager
    let performRoutePlanning: () -> Void
    let showError: (String) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Title
            HStack {
                Text("規劃路線")
                    .font(.headline)
                    .foregroundColor(.hkBlue)
                Spacer()
                Image(systemName: "route")
                    .foregroundColor(.hkBlue)
            }
            
            // Search Fields
            VStack(spacing: 16) {
                // Start Location
                StartLocationField(
                    startLocation: $startLocation,
                    showingLocationPicker: $showingLocationPicker,
                    showCurrentLocationOption: $showCurrentLocationOption,
                    locationManager: locationManager,
                    showError: showError
                )
                
                // Destination
                DestinationField(
                    endLocation: $endLocation,
                    showingDestinationPicker: $showingDestinationPicker
                )
                
                // Time Selection
                TimeSelectionField(selectedDate: $selectedDate)
            }
            
            // 當前位置選項
            CurrentLocationOptionView(
                showCurrentLocationOption: $showCurrentLocationOption,
                startLocation: $startLocation
            )
            
            // Search Button
            SearchButton(
                startLocation: startLocation,
                endLocation: endLocation,
                isSearching: isSearching,
                performRoutePlanning: performRoutePlanning
            )
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .sheet(isPresented: $showingLocationPicker) {
            LocationSearchView(selectedText: $startLocation)
        }
        .sheet(isPresented: $showingDestinationPicker) {
            LocationSearchView(selectedText: $endLocation)
        }
    }
}

struct StartLocationField: View {
    @Binding var startLocation: String
    @Binding var showingLocationPicker: Bool
    @Binding var showCurrentLocationOption: Bool
    let locationManager: LocationManager
    let showError: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.accentOrange)
                    .font(.caption)
                Text("起點位置")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                TextField("輸入起點位置", text: $startLocation)
                    .padding(.leading, 8)
                    .foregroundColor(.primary)
                
                // 當前位置按鈕
                Button(action: {
                    handleCurrentLocation()
                }) {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundColor(.accentOrange)
                        .padding(8)
                        .background(Color.accentOrange.opacity(0.1))
                        .cornerRadius(6)
                }
                
                // 地點選擇按鈕
                Button(action: {
                    showingLocationPicker = true
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .font(.caption)
                        .padding(8)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
    
    private func handleCurrentLocation() {
        if locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways {
            locationManager.requestCurrentLocation()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if locationManager.userLocation != nil {
                    startLocation = "當前位置"
                    showCurrentLocationOption = true
                } else {
                    showError("無法獲取當前位置")
                }
            }
        } else {
            locationManager.requestPermission()
            showError("請先允許位置權限")
        }
    }
}

struct DestinationField: View {
    @Binding var endLocation: String
    @Binding var showingDestinationPicker: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "flag.fill")
                    .foregroundColor(.hkRed)
                    .font(.caption)
                Text("目的地")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                TextField("輸入目的地", text: $endLocation)
                    .padding(.leading, 8)
                    .foregroundColor(.primary)
                
                // 地點選擇按鈕
                Button(action: {
                    showingDestinationPicker = true
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .font(.caption)
                        .padding(8)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
}

struct TimeSelectionField: View {
    @Binding var selectedDate: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.hkBlue)
                    .font(.caption)
                Text("出發時間")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            DatePicker("", selection: $selectedDate, displayedComponents: .hourAndMinute)
                .datePickerStyle(CompactDatePickerStyle())
                .labelsHidden()
                .accentColor(.hkBlue)
        }
        .padding(.vertical, 8)
    }
}

struct CurrentLocationOptionView: View {
    @Binding var showCurrentLocationOption: Bool
    @Binding var startLocation: String
    
    var body: some View {
        Group {
            if showCurrentLocationOption {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                    
                    Text("已設定起點為當前位置")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Button("清除") {
                        startLocation = ""
                        showCurrentLocationOption = false
                    }
                    .font(.caption2)
                    .foregroundColor(.red)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
}

struct SearchButton: View {
    let startLocation: String
    let endLocation: String
    let isSearching: Bool
    let performRoutePlanning: () -> Void
    
    var body: some View {
        Button(action: performRoutePlanning) {
            HStack {
                if isSearching {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                    Text("規劃路線")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.hkBlue, Color.hkBlue.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .font(.headline)
            .cornerRadius(12)
            .shadow(color: .hkBlue.opacity(0.3), radius: 5, x: 0, y: 3)
        }
        .disabled(startLocation.isEmpty || endLocation.isEmpty || isSearching)
        .opacity(startLocation.isEmpty || endLocation.isEmpty ? 0.6 : 1)
    }
}

// MARK: - Quick Actions Section
struct QuickActionsSection: View {
    @Binding var selectedTab: Int
    @Binding var showFavoritesView: Bool
    @Binding var showHistoryView: Bool
    @Binding var showSavedRoutesView: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("快速功能")
                .font(.headline)
                .foregroundColor(.hkBlue)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                                
                // CHANGED: QuickActionButton -> HomeQuickActionButton
                HomeQuickActionButton(
                    icon: "clock.arrow.circlepath",
                    title: "歷史記錄",
                    color: .green,
                    action: {
                        showHistoryView = true
                    }
                )
                HomeQuickActionButton(
                    icon: "bookmark.fill",
                    title: "保存路線",
                    color: .hkBlue,
                    action: {
                        showSavedRoutesView = true
                    }
                )

            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Recent Searches Section
struct RecentSearchesSection: View {
    @ObservedObject var travelDataManager: TravelDataManager
    @Binding var showHistoryView: Bool
    
    let onReplan: (TravelRoute) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("最近搜尋")
                    .font(.headline)
                    .foregroundColor(.hkBlue)
                
                Spacer()
                
                Button("查看全部") {
                    showHistoryView = true
                }
                .font(.caption)
                .foregroundColor(.hkBlue)
                
                // 清除歷史按鈕
                if !travelDataManager.recentRoutes.isEmpty {
                    Button("清除") {
                        travelDataManager.clearHistory()
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
            }
            
            if travelDataManager.recentRoutes.isEmpty {
                Text("暫無搜索記錄")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(travelDataManager.recentRoutes.prefix(2)) { route in
                    ModernRecentRouteCard(route: route) {
                        onReplan(route)
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Supporting Views
struct ModernWeatherCard: View {
    let weather: WeatherData
    
    var body: some View {
        HStack(spacing: 20) {
            // Weather Icon
            VStack {
                Image(systemName: weather.systemIconName)
                    .font(.system(size: 50))
                    .foregroundColor(weatherColor)
                    .frame(height: 60)
                
                Text(weather.condition)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            .frame(width: 80)
            
            // Temperature Info
            VStack(alignment: .leading, spacing: 4) {
                Text("香港天氣")
                    .font(.headline)
                    .foregroundColor(.hkBlue)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(Int(weather.temperature))")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                    Text("°C")
                        .font(.title2)
                }
                .foregroundColor(weatherColor)
                
                Text("體感溫度: \(Int(weather.feelsLike))°C")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Details
            VStack(alignment: .trailing, spacing: 8) {
                WeatherDetailRow(
                    icon: "humidity.fill",
                    value: "\(weather.humidity)%",
                    color: .blue
                )
                
                if weather.rainfall > 0 {
                    WeatherDetailRow(
                        icon: "drop.fill",
                        value: "\(String(format: "%.1f", weather.rainfall)) mm",
                        color: .blue
                    )
                }
                
                WeatherDetailRow(
                    icon: "wind",
                    value: "\(String(format: "%.1f", weather.windSpeed)) km/h",
                    color: .gray
                )
                
                Text("更新: \(formattedTime)")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [weatherColor.opacity(0.1), weatherColor.opacity(0.05)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(weatherColor.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(16)
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: weather.updateTime)
    }
    
    private var weatherColor: Color {
        if weather.condition.contains("雨") || weather.condition.contains("雷") {
            return .blue
        } else if weather.condition.contains("雲") || weather.condition.contains("陰") {
            return .gray
        } else if weather.condition.contains("霧") || weather.condition.contains("煙") {
            return .teal
        } else {
            return .orange
        }
    }
}

struct WeatherDetailRow: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            Text(value)
                .font(.caption)
                .foregroundColor(.primary)
        }
    }
}

struct ModernRecentRouteCard: View {
    let route: TravelRoute
    var onReplan: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 16) {
            // Route Icon
            ZStack {
                Circle()
                    .fill(Color.hkBlue.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                    .font(.title2)
                    .foregroundColor(.hkBlue)
            }
            
            // Route Details
            VStack(alignment: .leading, spacing: 6) {
                Text(route.startLocation.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    Text(route.endLocation.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack {
                    Label("\(route.duration)分鐘", systemImage: "clock")
                        .font(.caption2)
                        .foregroundColor(.accentOrange)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        ForEach(route.transportationModes, id: \.self) { mode in
                            Text(mode)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.hkBlue.opacity(0.1))
                                .foregroundColor(.hkBlue)
                                .cornerRadius(4)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Replan Button
            Button(action: {
                onReplan?()
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.callout)
                    .foregroundColor(.hkBlue)
                    .frame(width: 36, height: 36)
                    .background(Color.hkBlue.opacity(0.1))
                    .cornerRadius(18)
            }
        }
        .padding(16)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
        .onTapGesture {
            onReplan?()
        }
    }
}

struct WeatherLoadingView: View {
    var body: some View {
        HStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
            Text("獲取天氣數據中...")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct WeatherErrorView: View {
    let error: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundColor(.orange)
            
            Text("天氣數據暫時不可用")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(error)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            Button(action: retryAction) {
                Text("重試")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.hkBlue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(16)
    }
}

struct HomeQuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                isPressed = true
            }
            
            action()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    isPressed = false
                }
            }
        }) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                }
                .scaleEffect(isPressed ? 0.9 : 1.0)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}


// MARK: - Location Search View
struct LocationSearchView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var travelDataManager = TravelDataManager.shared
    @State private var searchText = ""
    @Binding var selectedText: String
    
    var filteredLocations: [Location] {
        if searchText.isEmpty {
            return travelDataManager.locations
        } else {
            return travelDataManager.locations.filter { location in
                location.name.localizedCaseInsensitiveContains(searchText) ||
                location.address.localizedCaseInsensitiveContains(searchText) ||
                location.category.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("搜尋地點...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                
                // Search Results
                List(filteredLocations) { location in
                    Button(action: {
                        selectedText = location.name
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: locationIcon(for: location.category))
                                    .foregroundColor(categoryColor(for: location.category))
                                    .font(.caption)
                                
                                Text(location.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                            
                            Text(location.address)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                            
                            if !location.category.isEmpty {
                                Text(location.category)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(categoryColor(for: location.category).opacity(0.1))
                                    .foregroundColor(categoryColor(for: location.category))
                                    .cornerRadius(4)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("選擇地點")
            .navigationBarItems(trailing: Button("取消") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func locationIcon(for category: String) -> String {
        switch category {
        case "Transport Hub": return "train.side.front.car"
        case "Shopping": return "bag.fill"
        case "Dining": return "fork.knife"
        case "Entertainment": return "film.fill"
        default: return "mappin"
        }
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

// MARK: - Welcome Guide View
struct WelcomeGuideView: View {
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("userName") private var userName = "Guest"
    @State private var currentPage = 0
    
    let guidePages = [
        GuidePage(
            title: "歡迎使用香港智能旅遊規劃",
            description: "這款應用程式將幫助您更輕鬆地規劃香港的旅行路線",
            icon: "map.fill",
            color: .hkBlue
        ),
        GuidePage(
            title: "實時天氣資訊",
            description: "獲取最新的天氣情況，為您的行程做好準備",
            icon: "cloud.sun.fill",
            color: .blue
        ),
        GuidePage(
            title: "智能路線規劃",
            description: "根據天氣、交通狀況為您推薦最佳路線",
            icon: "arrow.triangle.turn.up.right.circle.fill",
            color: .green
        ),
        GuidePage(
            title: "開始使用",
            description: "請輸入您的名字以個性化體驗",
            icon: "person.fill",
            color: .orange
        )
    ]
    
    var body: some View {
        VStack(spacing: 30) {
            TabView(selection: $currentPage) {
                ForEach(0..<guidePages.count, id: \.self) { index in
                    VStack(spacing: 20) {
                        Image(systemName: guidePages[index].icon)
                            .font(.system(size: 80))
                            .foregroundColor(guidePages[index].color)
                        
                        Text(guidePages[index].title)
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text(guidePages[index].description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        if index == guidePages.count - 1 {
                            TextField("請輸入您的名字", text: $userName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.horizontal, 40)
                                .padding(.top, 20)
                        }
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle())
            
            HStack {
                if currentPage > 0 {
                    Button("上一頁") {
                        withAnimation {
                            currentPage -= 1
                        }
                    }
                    .foregroundColor(.hkBlue)
                }
                
                Spacer()
                
                if currentPage < guidePages.count - 1 {
                    Button("下一頁") {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                    .foregroundColor(.hkBlue)
                } else {
                    Button("開始使用") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.hkBlue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal, 40)
        }
        .padding(.vertical, 40)
    }
}

struct GuidePage {
    let title: String
    let description: String
    let icon: String
    let color: Color
}

// MARK: - Favorites View
// 在 HomeView.swift 中，修改 FavoritesView 結構體：

struct FavoritesView: View {
    @ObservedObject var travelDataManager = TravelDataManager.shared
    @Environment(\.presentationMode) var presentationMode
    @State private var showingClearAlert = false
    
    var favoriteLocations: [Location] {
        travelDataManager.getFavoriteLocations()
    }
    
    var body: some View {
        NavigationView {
            Group {
                if favoriteLocations.isEmpty {
                    EmptyFavoritesView()
                } else {
                    List {
                        ForEach(favoriteLocations) { location in
                            FavoriteLocationRow(
                                location: location,
                                isFavorite: true,
                                onToggleFavorite: {
                                    travelDataManager.updateFavoriteStatus(
                                        for: location.id,
                                        isFavorite: false
                                    )
                                }
                            )
                        }
                        .onDelete { indexSet in
                            deleteFavorites(at: indexSet)
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("收藏地點")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("完成") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: !favoriteLocations.isEmpty ?
                    Button(action: {
                        showingClearAlert = true
                    }) {
                        Text("清除")
                            .foregroundColor(.red)
                    } : nil
            )
            .alert("清除收藏", isPresented: $showingClearAlert) {
                Button("取消", role: .cancel) { }
                Button("清除", role: .destructive) {
                    travelDataManager.clearFavorites()
                }
            } message: {
                Text("確定要清除所有收藏地點嗎？此操作無法撤銷。")
            }
        }
    }
    
    private func deleteFavorites(at offsets: IndexSet) {
        for index in offsets {
            let location = favoriteLocations[index]
            travelDataManager.updateFavoriteStatus(for: location.id, isFavorite: false)
        }
    }
}

// 添加空狀態視圖
struct EmptyFavoritesView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("尚未收藏任何地點")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("在地圖或搜索結果中點擊星號圖標來收藏地點")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxHeight: .infinity)
        .padding()
    }
}

// 修改 FavoriteLocationRow，添加更多功能
struct FavoriteLocationRow: View {
    let location: Location
    let isFavorite: Bool
    let onToggleFavorite: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // 地點圖標
            Image(systemName: locationIcon(for: location.category))
                .foregroundColor(categoryColor(for: location.category))
                .font(.title3)
                .frame(width: 32)
            
            // 地點信息
            VStack(alignment: .leading, spacing: 4) {
                Text(location.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(location.address)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // 收藏按鈕
            Button(action: onToggleFavorite) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .foregroundColor(isFavorite ? .yellow : .gray)
                    .font(.title3)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.vertical, 8)
        .contextMenu {
            Button(action: {
                onToggleFavorite()
            }) {
                Label(isFavorite ? "取消收藏" : "加入收藏",
                      systemImage: isFavorite ? "star.slash" : "star")
            }
            
            Button(action: {
                // 分享地點
                shareLocation(location)
            }) {
                Label("分享", systemImage: "square.and.arrow.up")
            }
        }
    }
    
    private func shareLocation(_ location: Location) {
        let text = "地點: \(location.name)\n地址: \(location.address)\n"
        let activityViewController = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityViewController, animated: true)
        }
    }
    
    private func locationIcon(for category: String) -> String {
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
    
    private func locationIcon(for category: String) -> String {
        switch category {
        case "Transport Hub": return "train.side.front.car"
        case "Shopping": return "bag.fill"
        case "Dining": return "fork.knife"
        case "Entertainment": return "film.fill"
        default: return "mappin"
        }
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



#Preview {
    HomeView()
}
