//
//  HomeView.swift
//  HKTravelMap
//
//  Created by Rex Au on 7/1/2026.
//

import SwiftUI

struct HomeView: View {
    @State private var startLocation = ""
    @State private var endLocation = ""
    @State private var isSearching = false
    @State private var showRouteResults = false
    @State private var selectedDate = Date()
    @State private var showingLocationPicker = false
    @State private var showingDestinationPicker = false
    
    @ObservedObject var travelDataManager = TravelDataManager.shared
    @StateObject private var locationManager = LocationManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with Welcome
                headerSection
                
                // Weather Card
                weatherSection
                
                // Search Card
                searchSection
                
                // Quick Actions
                quickActionsSection
                
                // Recent Searches
                if !travelDataManager.recentRoutes.isEmpty {
                    recentSearchesSection
                }
                
                Spacer(minLength: 20)
            }
            .padding(.top, 20)
            .padding(.horizontal, 16)
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showRouteResults) {
            if let start = travelDataManager.locations.first, let end = travelDataManager.locations.last {
                RouteResultsView(routes: travelDataManager.getRoutes(from: start, to: end))
            }
        }
        .onAppear {
            if travelDataManager.currentWeather.condition == "加載中..." {
                travelDataManager.fetchRealTimeWeather()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
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
                    // Profile action
                }) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.hkBlue)
                }
            }
            
            Divider()
        }
    }
    
    // MARK: - Weather Section
    private var weatherSection: some View {
        Group {
            if travelDataManager.isLoadingWeather {
                WeatherLoadingView()
            } else if let error = travelDataManager.weatherError {
                WeatherErrorView(error: error) {
                    travelDataManager.fetchRealTimeWeather()
                }
            } else {
                ModernWeatherCard(weather: travelDataManager.currentWeather)
            }
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - Search Section
    private var searchSection: some View {
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
                LocationField(
                    icon: "location.fill",
                    iconColor: .accentOrange,
                    title: "起點位置",
                    placeholder: "輸入起點",
                    text: $startLocation,
                    showPicker: $showingLocationPicker,
                    isCurrentLocation: startLocation == "當前位置"
                )
                
                // Destination
                LocationField(
                    icon: "flag.fill",
                    iconColor: .hkRed,
                    title: "目的地",
                    placeholder: "輸入目的地",
                    text: $endLocation,
                    showPicker: $showingDestinationPicker,
                    isCurrentLocation: false
                )
                
                // Time Selection
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
            
            // Search Button
            Button(action: {
                isSearching = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isSearching = false
                    showRouteResults = true
                }
            }) {
                HStack {
                    if isSearching {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "magnifyingglass")
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
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
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
                QuickActionButton(
                    icon: "map.fill",
                    title: "附近景點",
                    color: .blue,
                    action: { }
                )
                
                QuickActionButton(
                    icon: "star.fill",
                    title: "收藏地點",
                    color: .yellow,
                    action: { }
                )
                
                QuickActionButton(
                    icon: "clock.arrow.circlepath",
                    title: "歷史記錄",
                    color: .green,
                    action: { }
                )
                
                QuickActionButton(
                    icon: "exclamationmark.triangle.fill",
                    title: "交通狀況",
                    color: .orange,
                    action: { }
                )
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Recent Searches Section
    private var recentSearchesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("最近搜尋")
                    .font(.headline)
                    .foregroundColor(.hkBlue)
                
                Spacer()
                
                Button("查看全部") {
                    // Navigate to history
                }
                .font(.caption)
                .foregroundColor(.hkBlue)
            }
            
            ForEach(travelDataManager.recentRoutes.prefix(2)) { route in
                ModernRecentRouteCard(route: route)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    private func getGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "早晨！"
        case 12..<18: return "午安！"
        case 18..<22: return "晚上好！"
        default: return "你好！"
        }
    }
}

// MARK: - Modern Weather Card
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

// MARK: - Weather Detail Row
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

// MARK: - Location Field Component
struct LocationField: View {
    let icon: String
    let iconColor: Color
    let title: String
    let placeholder: String
    @Binding var text: String
    @Binding var showPicker: Bool
    let isCurrentLocation: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                TextField(placeholder, text: $text)
                    .padding(.leading, 8)
                    .foregroundColor(.primary)
                
                if isCurrentLocation {
                    Image(systemName: "location.fill")
                        .foregroundColor(.accentOrange)
                        .padding(.trailing, 8)
                } else {
                    Button(action: {
                        showPicker = true
                    }) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .font(.caption)
                            .padding(.trailing, 8)
                    }
                }
            }
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
}

// MARK: - Modern Recent Route Card
struct ModernRecentRouteCard: View {
    let route: TravelRoute
    
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
                
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    Text(route.endLocation.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
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
                // Replan this route
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
    }
}

// MARK: - Weather Loading View
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

// MARK: - Weather Error View
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

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
    }
}

#Preview {
    HomeView()
}
