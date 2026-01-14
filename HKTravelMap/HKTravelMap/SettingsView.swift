//
//  SettingsView.swift
//  HKTravelMap
//
//  Created by Rex Au on 7/1/2026.
//

import SwiftUI

struct SettingsView: View {
    @State private var isDarkMode = false
    @State private var notificationsEnabled = true
    @State private var locationAccess = true
    @AppStorage("saveHistory") private var saveHistory = true
    @State private var autoUpdate = true
    @State private var selectedLanguage = "English"
    @State private var selectedMapProvider = "Apple Maps"
    
    let languages = ["English", "Traditional Chinese", "Simplified Chinese"]
    let mapProviders = ["Apple Maps", "Google Maps"]
    
    @ObservedObject var travelDataManager = TravelDataManager.shared
    @State private var showingClearHistoryAlert = false
    @State private var showingClearFavoritesAlert = false
    
    var body: some View {
        List {
            // User Info Section
            Section {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.hkBlue)
                        .padding(.trailing, 10)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Guest User")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Text("Not logged in")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Button("Login / Register") {
                            // Login action
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.hkBlue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.top, 4)
                    }
                }
                .padding(.vertical, 8)
            }
            
            // App Settings Section
            Section(header: Text("App Settings")) {
                HStack {
                    Image(systemName: "moon.fill")
                        .foregroundColor(.purple)
                        .frame(width: 30)
                    Toggle("Dark Mode", isOn: $isDarkMode)
                }
                
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.blue)
                        .frame(width: 30)
                    Toggle("Location Access", isOn: $locationAccess)
                }
                
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.orange)
                        .frame(width: 30)
                    Toggle("Save History", isOn: $saveHistory)
                        .onChange(of: saveHistory) { newValue in
                            travelDataManager.setSaveHistory(newValue)
                        }
                }
            }
            
            // Preferences Section
            Section(header: Text("Preferences")) {
                HStack {
                    Image(systemName: "globe")
                        .foregroundColor(.blue)
                        .frame(width: 30)
                    Text("Language")
                    Spacer()
                    Picker("", selection: $selectedLanguage) {
                        ForEach(languages, id: \.self) { language in
                            Text(language).tag(language)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                HStack {
                    Image(systemName: "map.fill")
                        .foregroundColor(.green)
                        .frame(width: 30)
                    Text("Map Provider")
                    Spacer()
                    Picker("", selection: $selectedMapProvider) {
                        ForEach(mapProviders, id: \.self) { provider in
                            Text(provider).tag(provider)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                NavigationLink(destination: TransportPreferenceView()) {
                    HStack {
                        Image(systemName: "bus.fill")
                            .foregroundColor(.hkBlue)
                            .frame(width: 30)
                        Text("Transport Preferences")
                    }
                }
            }
            
            // Personal Data Section
            Section(header: Text("Personal Data")) {
                Button(action: {
                    showingClearHistoryAlert = true
                }) {
                    HStack {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.red)
                            .frame(width: 30)
                        Text("Clear History")
                        Spacer()
                        Text("\(travelDataManager.recentRoutes.count) items")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .foregroundColor(.red)
                }
                
                Button(action: {
                    showingClearFavoritesAlert = true
                }) {
                    HStack {
                        Image(systemName: "star.slash.fill")
                            .foregroundColor(.red)
                            .frame(width: 30)
                        Text("Clear Favorites")
                        Spacer()
                        Text("\(travelDataManager.getFavoriteLocations().count) items")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .foregroundColor(.red)
                }
            }
            
            // Account Actions Section
            Section {
                Button(action: {
                    // Logout action
                }) {
                    HStack {
                        Spacer()
                        Text("Logout")
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
                
                Button(action: {
                    // Delete account action
                }) {
                    HStack {
                        Spacer()
                        Text("Delete Account")
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Settings")
        .alert("Clear History", isPresented: $showingClearHistoryAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                travelDataManager.clearHistory()
            }
        } message: {
            Text("Are you sure you want to clear all history? This action cannot be undone.")
        }
        .alert("Clear Favorites", isPresented: $showingClearFavoritesAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                travelDataManager.clearFavorites()
            }
        } message: {
            Text("Are you sure you want to clear all favorites? This action cannot be undone.")
        }
    }
}

// MARK: - Subpages (保持原樣不變)
struct TransportPreferenceView: View {
    @State private var preferredModes: [String: Bool] = [
        "MTR": true,
        "Bus": true,
        "Minibus": false,
        "Tram": false,
        "Ferry": true,
        "Taxi": true,
        "Walk": true
    ]
    
    var body: some View {
        List {
            Section(header: Text("Preferred Transport Modes")) {
                ForEach(preferredModes.keys.sorted(), id: \.self) { mode in
                    Toggle(isOn: Binding(
                        get: { preferredModes[mode] ?? false },
                        set: { preferredModes[mode] = $0 }
                    )) {
                        HStack {
                            Image(systemName: iconForTransport(mode))
                                .foregroundColor(colorForTransport(mode))
                                .frame(width: 30)
                            Text(mode)
                        }
                    }
                }
            }
            
            Section(header: Text("Other Settings")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Maximum Walking Distance")
                    HStack {
                        Slider(value: .constant(1.0), in: 0.1...5.0, step: 0.1)
                        Text("1.0 km")
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 8)
                
                Toggle("Avoid Stairs/Elevators", isOn: .constant(false))
                Toggle("Prefer Covered Walkways", isOn: .constant(true))
            }
        }
        .navigationTitle("Transport Preferences")
        .listStyle(InsetGroupedListStyle())
    }
    
    private func iconForTransport(_ mode: String) -> String {
        switch mode {
        case "MTR": return "train.side.front.car"
        case "Bus": return "bus"
        case "Minibus": return "bus.doubledecker"
        case "Tram": return "tram"
        case "Ferry": return "ferry"
        case "Taxi": return "car"
        case "Walk": return "figure.walk"
        default: return "questionmark"
        }
    }
    
    private func colorForTransport(_ mode: String) -> Color {
        switch mode {
        case "MTR": return .red
        case "Bus": return .green
        case "Minibus": return .orange
        case "Tram": return .blue
        case "Ferry": return .purple
        case "Taxi": return .yellow
        case "Walk": return .gray
        default: return .black
        }
    }
}

struct NotificationSettingsView: View {
    @State private var routeNotifications = true
    @State private var weatherAlerts = true
    @State private var trafficAlerts = true
    @State private var promotionNotifications = false
    
    var body: some View {
        List {
            Section(header: Text("Notification Types")) {
                Toggle("Route Updates", isOn: $routeNotifications)
                Toggle("Weather Alerts", isOn: $weatherAlerts)
                Toggle("Traffic Alerts", isOn: $trafficAlerts)
                Toggle("Promotions", isOn: $promotionNotifications)
            }
            
            Section(header: Text("Notification Times")) {
                DatePicker("Daily Reminder", selection: .constant(Date()), displayedComponents: .hourAndMinute)
                Toggle("Silence Outside Hours", isOn: .constant(true))
            }
            
            Section(header: Text("Emergency Alerts")) {
                Toggle("Extreme Weather", isOn: .constant(true))
                Toggle("Major Traffic Disruption", isOn: .constant(true))
            }
        }
        .navigationTitle("Notification Settings")
        .listStyle(InsetGroupedListStyle())
    }
}

struct DataUsageView: View {
    var body: some View {
        List {
            Section(header: Text("Data Usage")) {
                HStack {
                    Text("Map Data")
                    Spacer()
                    Text("245 MB")
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text("Route Data")
                    Spacer()
                    Text("156 MB")
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text("Cache Data")
                    Spacer()
                    Text("89 MB")
                        .foregroundColor(.gray)
                }
            }
            
            Section(header: Text("Data Settings")) {
                Toggle("Wi-Fi Only Downloads", isOn: .constant(true))
                Toggle("Auto Delete Old Data", isOn: .constant(false))
            }
            
            Section {
                Button("Clear All Data") {
                    // Clear data action
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Data Usage")
        .listStyle(InsetGroupedListStyle())
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Terms of Service")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Last Updated: December 31, 2025")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Group {
                    Text("1. Acceptance of Terms")
                        .font(.headline)
                    Text("By downloading, installing, or using the Hong Kong Travel Planner app, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the app.")
                    
                    Text("2. Service Description")
                        .font(.headline)
                    Text("This app provides travel planning services in Hong Kong, including but not limited to route planning, transportation information, weather information, etc. We strive to provide accurate information but cannot guarantee real-time accuracy.")
                    
                    Text("3. User Responsibility")
                        .font(.headline)
                    Text("You are responsible for any damages or losses resulting from your use of this app. When using the app, please comply with all applicable laws and regulations.")
                    
                    Text("4. Privacy Policy")
                        .font(.headline)
                    Text("Your privacy is important to us. Please review our Privacy Policy to understand how we collect, use, and protect your personal information.")
                    
                    Text("5. Service Changes")
                        .font(.headline)
                    Text("We reserve the right to modify or terminate the service at any time without notice. We are not liable for any modifications, price changes, suspension, or termination of service.")
                }
                .padding(.bottom, 8)
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Last Updated: December 31, 2025")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text("We value your privacy. This Privacy Policy explains how Hong Kong Travel Planner collects, uses, and protects your personal information.")
                    .font(.headline)
                
                Group {
                    Text("Information We Collect")
                        .font(.headline)
                    Text("We may collect the following information:\n• Location data (for route planning)\n• Search history\n• Device information\n• Usage statistics")
                    
                    Text("How We Use Information")
                        .font(.headline)
                    Text("We use collected information to:\n• Provide and improve services\n• Personalize user experience\n• Analyze usage patterns\n• Send important notifications")
                    
                    Text("Data Security")
                        .font(.headline)
                    Text("We take reasonable security measures to protect your personal information, but cannot guarantee absolute security.")
                    
                    Text("Third-Party Services")
                        .font(.headline)
                    Text("We may use third-party services (such as map services, weather APIs) to provide functionality. These services have their own privacy policies.")
                    
                    Text("Contact Us")
                        .font(.headline)
                    Text("If you have any questions about our Privacy Policy, contact us at: privacy@hktravelplanner.com")
                }
                .padding(.bottom, 8)
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
    }
}

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // App Icon
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [.hkBlue, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "map.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                    )
                
                VStack(spacing: 8) {
                    Text("Hong Kong Travel Planner")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Version 1.0.0")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text("Smart travel planning for Hong Kong residents and visitors")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Features")
                        .font(.headline)
                    
                    FeatureRow(
                        icon: "map.fill",
                        title: "Smart Route Planning",
                        description: "Combines real-time traffic, weather, and preferences"
                    )
                    
                    FeatureRow(
                        icon: "cloud.sun.fill",
                        title: "Real-time Weather",
                        description: "Adjusts routes based on weather conditions"
                    )
                    
                    FeatureRow(
                        icon: "clock.fill",
                        title: "Multiple Transport Modes",
                        description: "MTR, Bus, Minibus, Ferry, and more"
                    )
                    
                    FeatureRow(
                        icon: "star.fill",
                        title: "Personalized Favorites",
                        description: "Save frequently used locations and routes"
                    )
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Development Team")
                        .font(.headline)
                    
                    Text("This app is developed by students at Hong Kong Institute of Higher Education (THEi) as part of the VT6002CEM Mobile App Development coursework.")
                        .font(.body)
                }
                .padding()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Special Thanks")
                        .font(.headline)
                    
                    Text("• Hong Kong Observatory - Weather data API\n• MTR Corporation - Transportation data\n• Transport Department - Public transport information")
                        .font(.body)
                }
                .padding()
                
                Text("© 2025-2026 Hong Kong Travel Planner. All rights reserved.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top)
            }
            .padding(.vertical)
        }
        .navigationTitle("About App")
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.hkBlue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationView {
        SettingsView()
    }
}
