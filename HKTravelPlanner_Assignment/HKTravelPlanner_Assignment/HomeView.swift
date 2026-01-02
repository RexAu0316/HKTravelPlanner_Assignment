//
//  HomeView.swift
//  HKTravelPlanner_Assignment
//
//  Created by [Your Name] on [Date].
//

import SwiftUI

struct HomeView: View {
    @State private var startLocation = ""
    @State private var endLocation = ""
    @State private var isSearching = false
    @State private var showRouteResults = false
    @State private var selectedDate = Date()
    
    let sampleData = SampleData.shared
    let weather = SampleData.shared.currentWeather
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Welcome Title
                VStack(alignment: .leading, spacing: 8) {
                    Text("Hong Kong Travel Planner")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.hkBlue)
                    
                    Text("Plan Your Hong Kong Journey")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                // Weather Card
                WeatherCardView(weather: weather)
                    .padding(.horizontal)
                
                // Search Card
                VStack(spacing: 16) {
                    // Start Location
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Start Location", systemImage: "location.fill")
                            .font(.headline)
                            .foregroundColor(.hkBlue)
                        
                        HStack {
                            TextField("Enter start location or use current", text: $startLocation)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            
                            Button(action: {
                                startLocation = "Current Location"
                            }) {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.accentOrange)
                            }
                        }
                    }
                    
                    // Destination
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Destination", systemImage: "flag.fill")
                            .font(.headline)
                            .foregroundColor(.hkRed)
                        
                        TextField("Enter destination", text: $endLocation)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    // Time Selection
                    DatePicker("Departure Time", selection: $selectedDate, displayedComponents: .hourAndMinute)
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
                                Text("Plan Route")
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
                if !sampleData.recentRoutes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recent Searches")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.hkBlue)
                            
                            Spacer()
                            
                            Button("View All") {
                                // Navigate to history
                            }
                            .font(.subheadline)
                            .foregroundColor(.accentOrange)
                        }
                        
                        ForEach(sampleData.recentRoutes.prefix(2)) { route in
                            RecentRouteCard(route: route)
                        }
                    }
                    .padding()
                }
                
                // Quick Access
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Access")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.hkBlue)
                    
                    HStack(spacing: 15) {
                        QuickAccessButton(
                            icon: "star.fill",
                            title: "Favorites",
                            color: .yellow
                        ) {
                            // Navigate to favorites
                        }
                        
                        QuickAccessButton(
                            icon: "clock.fill",
                            title: "History",
                            color: .green
                        ) {
                            // Navigate to history
                        }
                        
                        QuickAccessButton(
                            icon: "map.fill",
                            title: "Explore HK",
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
            if let start = sampleData.locations.first, let end = sampleData.locations.last {
                RouteResultsView(routes: sampleData.getRoutes(from: start, to: end))
            }
        }
    }
}

// MARK: - Weather Card Component
struct WeatherCardView: View {
    let weather: WeatherData
    
    var body: some View {
        HStack(spacing: 15) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hong Kong Weather")
                    .font(.headline)
                    .foregroundColor(.hkBlue)
                
                Text(weather.condition)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("\(Int(weather.temperature))°C")
                    .font(.title3)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Label("\(weather.humidity)%", systemImage: "humidity.fill")
                    .font(.subheadline)
                    .foregroundColor(.blue)
                
                Label("\(Int(weather.windSpeed)) km/h", systemImage: "wind")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text("Updated: \(formattedTime)")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.blue.opacity(0.05)],
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
}

// MARK: - Recent Route Card
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
                    Label("\(route.duration) minutes", systemImage: "clock")
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

// MARK: - Quick Access Button
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
