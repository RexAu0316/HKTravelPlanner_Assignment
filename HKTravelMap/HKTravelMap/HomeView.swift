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
    
    @ObservedObject var travelDataManager = TravelDataManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Welcome Title
                VStack(alignment: .leading, spacing: 8) {
                    Text("香港智能旅遊規劃")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.hkBlue)
                    
                    Text("即時天氣與交通資訊")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                // Weather Card
                weatherSection
                
                // Search Card
                VStack(spacing: 16) {
                    // Start Location
                    VStack(alignment: .leading, spacing: 8) {
                        Label("起點位置", systemImage: "location.fill")
                            .font(.headline)
                            .foregroundColor(.hkBlue)
                        
                        HStack {
                            TextField("輸入起點或使用當前位置", text: $startLocation)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            
                            Button(action: {
                                startLocation = "當前位置"
                            }) {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.accentOrange)
                            }
                        }
                    }
                    
                    // Destination
                    VStack(alignment: .leading, spacing: 8) {
                        Label("目的地", systemImage: "flag.fill")
                            .font(.headline)
                            .foregroundColor(.hkRed)
                        
                        TextField("輸入目的地", text: $endLocation)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    // Time Selection
                    DatePicker("出發時間", selection: $selectedDate, displayedComponents: .hourAndMinute)
                        .font(.headline)
                        .foregroundColor(.hkBlue)
                    
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
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.hkBlue)
                        .foregroundColor(.white)
                        .font(.headline)
                        .cornerRadius(12)
                    }
                    .disabled(startLocation.isEmpty || endLocation.isEmpty || isSearching)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                
                // Recent Searches
                if !travelDataManager.recentRoutes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("最近搜尋")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.hkBlue)
                            
                            Spacer()
                            
                            Button("查看全部") {
                                // Navigate to history
                            }
                            .font(.subheadline)
                            .foregroundColor(.accentOrange)
                        }
                        
                        ForEach(travelDataManager.recentRoutes.prefix(2)) { route in
                            RecentRouteCard(route: route)
                        }
                    }
                    .padding()
                }
                
                // Quick Access
                VStack(alignment: .leading, spacing: 12) {
                    Text("快速訪問")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.hkBlue)
                    
                    HStack(spacing: 15) {
                        QuickAccessButton(
                            icon: "star.fill",
                            title: "收藏夾",
                            color: .yellow
                        ) {
                            // Navigate to favorites
                        }
                        
                        QuickAccessButton(
                            icon: "clock.fill",
                            title: "歷史記錄",
                            color: .green
                        ) {
                            // Navigate to history
                        }
                        
                        QuickAccessButton(
                            icon: "map.fill",
                            title: "探索香港",
                            color: .purple
                        ) {
                            // Navigate to map
                        }
                    }
                }
                .padding()
            }
            .padding(.vertical)
        }
        .background(Color.lightBackground)
        .sheet(isPresented: $showRouteResults) {
            if let start = travelDataManager.locations.first, let end = travelDataManager.locations.last {
                RouteResultsView(routes: travelDataManager.getRoutes(from: start, to: end))
            }
        }
        .onAppear {
            // Load weather when view appears
            if travelDataManager.currentWeather.condition == "加載中..." {
                travelDataManager.fetchRealTimeWeather()
            }
        }
    }
    
    private var weatherSection: some View {
        Group {
            if travelDataManager.isLoadingWeather {
                WeatherLoadingView()
                    .padding(.horizontal)
            } else if let error = travelDataManager.weatherError {
                WeatherErrorView(error: error) {
                    travelDataManager.fetchRealTimeWeather()
                }
                .padding(.horizontal)
            } else {
                WeatherCardView(weather: travelDataManager.currentWeather)
                    .padding(.horizontal)
            }
        }
    }
}

// 加載視圖
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
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

// 錯誤視圖
struct WeatherErrorView: View {
    let error: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title)
                .foregroundColor(.orange)
            
            Text("天氣數據暫時不可用")
                .font(.headline)
            
            Text(error)
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Button("重試", action: retryAction)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.hkBlue)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(16)
    }
}

struct WeatherCardView: View {
    let weather: WeatherData
    
    var body: some View {
        HStack(spacing: 15) {
            // 天氣圖標
            VStack {
                Image(systemName: weather.systemIconName)
                    .font(.system(size: 50))
                    .foregroundColor(weatherColor)
                
                Text(weather.condition)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(width: 80)
            
            // 溫度資訊
            VStack(alignment: .leading, spacing: 4) {
                Text("香港天氣")
                    .font(.headline)
                    .foregroundColor(.hkBlue)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(Int(weather.temperature))")
                        .font(.system(size: 40, weight: .bold))
                    Text("°C")
                        .font(.title2)
                }
                
                Text("體感溫度: \(Int(weather.feelsLike))°C")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // 詳細資訊
            VStack(alignment: .trailing, spacing: 6) {
                HStack {
                    Image(systemName: "humidity.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                    Text("\(weather.humidity)%")
                        .font(.caption)
                }
                                
                if weather.rainfall > 0 {
                    HStack {
                        Image(systemName: "drop.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                        Text("\(String(format: "%.1f", weather.rainfall)) mm")
                            .font(.caption)
                    }
                }
                
                Text("更新: \(formattedTime)")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [weatherColor.opacity(0.2), weatherColor.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
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

struct RecentRouteCard: View {
    let route: TravelRoute
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(route.startLocation.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(route.endLocation.name)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Label("\(route.duration) 分鐘", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.accentOrange)
                    
                    Spacer()
                    
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
            
            Spacer()
            
            Button(action: {
                // Replan this route
            }) {
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(.hkBlue)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

struct QuickAccessButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        }
    }
}

#Preview {
    HomeView()
}
