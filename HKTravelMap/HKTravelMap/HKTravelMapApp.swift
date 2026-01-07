//
//  HKTravelMapApp.swift
//  HKTravelMap
//
//  Created by Rex Au on 7/1/2026.
//

import SwiftUI

@main
struct HKTravelMapApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()  // CHANGE THIS LINE
                .onAppear {
                    // Start loading weather when app launches
                    TravelDataManager.shared.fetchRealTimeWeather()
                }
        }
    }
}

// ADD THIS STRUCT
struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("首頁")
                }
            
            MapView()
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("地圖")
                }
            
            FavoritesView()
                .tabItem {
                    Image(systemName: "star.fill")
                    Text("收藏")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("設定")
                }
        }
    }
}
