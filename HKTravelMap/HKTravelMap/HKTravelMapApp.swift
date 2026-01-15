//
//  HKTravelMapApp.swift
//  HKTravelMap
//
//  Created by Rex Au on 7/1/2026.
//

// HKTravelMapApp.swift - 更新版
import SwiftUI

@main
struct HKTravelMapApp: App {
    @AppStorage("isDarkMode") private var isDarkMode = false
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(isDarkMode ? .dark : .light)
                .onAppear {
                    // 啟動時加載天氣
                    TravelDataManager.shared.fetchRealTimeWeather()
                    
                    // 啟動時加載交通數據（延遲1秒以避免影響啟動速度）
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        TransportationManager.shared.loadFromCache()
                    }
                }
        }
    }
}
