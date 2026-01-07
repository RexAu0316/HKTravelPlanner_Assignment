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
            ContentView()
                .onAppear {
                    // Start loading weather when app launches
                    TravelDataManager.shared.fetchRealTimeWeather()
                }
        }
    }
}
