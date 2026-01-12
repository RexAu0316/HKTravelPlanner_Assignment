//
//  ContentView.swift
//  HKTravelMap
//
//  Created by Rex Au on 7/1/2026.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // Tab 1: Home
                HomeView()
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("主頁")
                    }
                    .tag(0)
                
                // Tab 2: Map
                MapView()
                    .tabItem {
                        Image(systemName: "map.fill")
                        Text("地圖")
                    }
                    .tag(1)
                
                // Tab 3: Transport
                TransportView()
                    .tabItem {
                        Image(systemName: "bus.fill")
                        Text("交通")
                    }
                    .tag(2)
                
                // Tab 4: Settings
                SettingsView()
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                        Text("設定")
                    }
                    .tag(3)
            }
            .accentColor(.hkBlue)
            .onAppear {
                // Custom tab bar appearance
                let appearance = UITabBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = UIColor.systemBackground
                
                // Apply the appearance
                UITabBar.appearance().standardAppearance = appearance
                if #available(iOS 15.0, *) {
                    UITabBar.appearance().scrollEdgeAppearance = appearance
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

#Preview {
    ContentView()
}
