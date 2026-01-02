//
//  ContentView.swift
//  HKTravelPlanner_Assignment
//
//  Created by Rex Au on 2/1/2026.
//

//
//  ContentView.swift
//  HKTravelPlanner_Assignment
//
//  Created by Rex Au on 31/12/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Home
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            // Tab 2: Favorites
            NavigationView {
                FavoritesView()
            }
            .tabItem {
                Image(systemName: "star.fill")
                Text("Favorites")
            }
            .tag(1)
            
            // Tab 3: Map
            NavigationView {
                MapView()
            }
            .tabItem {
                Image(systemName: "map.fill")
                Text("Map")
            }
            .tag(2)
            
            // Tab 4: Settings
            NavigationView {
                SettingsView()
            }
            .tabItem {
                Image(systemName: "gearshape.fill")
                Text("Settings")
            }
            .tag(3)
        }
        .accentColor(.hkBlue)
    }
}

#Preview {
    ContentView()
}
