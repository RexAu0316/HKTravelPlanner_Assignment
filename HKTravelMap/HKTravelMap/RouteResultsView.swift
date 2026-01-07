//
//  RouteResultsView.swift
//  HKTravelPlanner
//
//  Created by Rex Au on 7/1/2026.
//

import SwiftUI

struct RouteResultsView: View {
    let routes: [TravelRoute]
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Route Summary
                if let firstRoute = routes.first {
                    RouteSummaryView(route: firstRoute)
                        .padding()
                        .background(Color.hkBlue.opacity(0.1))
                }
                
                // Routes List
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(routes) { route in
                            RouteCard(route: route)
                        }
                        
                        // Additional Options
                        VStack(spacing: 12) {
                            Text("更多選項")
                                .font(.headline)
                                .foregroundColor(.hkBlue)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack(spacing: 15) {
                                RouteOptionButton(
                                    icon: "clock.badge.exclamationmark",
                                    title: "時間選項",
                                    color: .orange
                                ) {
                                    // Time options
                                }
                                
                                RouteOptionButton(
                                    icon: "dollarsign.circle",
                                    title: "價格比較",
                                    color: .green
                                ) {
                                    // Price comparison
                                }
                                
                                RouteOptionButton(
                                    icon: "leaf",
                                    title: "環保路線",
                                    color: .green
                                ) {
                                    // Eco-friendly route
                                }
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
                        .padding(.horizontal)
                        
                        // Weather Impact
                        if let weatherImpact = routes.first?.weatherImpact {
                            WeatherImpactView(impact: weatherImpact)
                                .padding(.horizontal)
                        }
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            Button(action: {
                                // Start navigation
                            }) {
                                HStack {
                                    Image(systemName: "play.fill")
                                    Text("開始導航")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.hkBlue)
                                .foregroundColor(.white)
                                .font(.headline)
                                .cornerRadius(12)
                            }
                            
                            Button(action: {
                                // Save route
                            }) {
                                HStack {
                                    Image(systemName: "star.fill")
                                    Text("儲存路線")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.yellow.opacity(0.2))
                                .foregroundColor(.yellow)
                                .font(.headline)
                                .cornerRadius(12)
                            }
                            
                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Text("返回")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.gray.opacity(0.1))
                                    .foregroundColor(.gray)
                                    .font(.headline)
                                    .cornerRadius(12)
                            }
                        }
                        .padding()
                    }
                    .padding(.vertical)
                }
                .background(Color.lightBackground)
            }
            .navigationBarTitle("路線結果", displayMode: .inline)
            .navigationBarItems(trailing: Button("關閉") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct RouteSummaryView: View {
    let route: TravelRoute
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(route.startLocation.name)
                        .font(.headline)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down")
                            .font(.caption)
                        Text(route.endLocation.name)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(route.duration) 分鐘")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.hkBlue)
                    Text("預計時間")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            // Transport Mode Tags
            HStack(spacing: 8) {
                ForEach(route.transportationModes, id: \.self) { mode in
                    TransportModeTag(mode: mode)
                }
            }
        }
    }
}

struct RouteCard: View {
    let route: TravelRoute
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Card Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("選項 \(route.id.uuidString.prefix(4))")
                        .font(.headline)
                        .foregroundColor(.hkBlue)
                    
                    HStack(spacing: 8) {
                        Label("\(route.duration) 分鐘", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.accentOrange)
                        
                        Label("\(calculateCost(for: route)) HKD", systemImage: "dollarsign.circle")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color.white)
            
            // Expanded Details
            if isExpanded {
                VStack(spacing: 12) {
                    ForEach(route.steps) { step in
                        RouteStepView(step: step)
                    }
                    
                    if let impact = route.weatherImpact {
                        HStack {
                            Image(systemName: "cloud.sun.fill")
                                .foregroundColor(.blue)
                            Text("天氣影響: \(impact)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    }
                    
                    HStack {
                        Button(action: {
                            // Select this route
                        }) {
                            Text("選擇此路線")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.hkBlue)
                                .foregroundColor(.white)
                                .font(.caption)
                                .cornerRadius(6)
                        }
                        
                        Button(action: {
                            // Share route
                        }) {
                            Text("分享")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.gray.opacity(0.1))
                                .foregroundColor(.gray)
                                .font(.caption)
                                .cornerRadius(6)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
            }
        }
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        .padding(.horizontal)
    }
    
    private func calculateCost(for route: TravelRoute) -> Int {
        // Simple cost calculation
        var cost = 0
        for step in route.steps {
            switch step.transportMode {
            case "MTR": cost += 8
            case "Bus": cost += 6
            case "Minibus": cost += 7
            case "Tram": cost += 3
            case "Ferry": cost += 5
            case "Taxi": cost += 50
            default: cost += 0
            }
        }
        return cost
    }
}

struct RouteStepView: View {
    let step: RouteStep
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(colorForTransport(step.transportMode))
                    .frame(width: 36, height: 36)
                
                Image(systemName: iconForTransport(step.transportMode))
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
            
            // Details
            VStack(alignment: .leading, spacing: 2) {
                Text(step.instruction)
                    .font(.subheadline)
                
                HStack(spacing: 12) {
                    if let lineNumber = step.lineNumber {
                        Text(lineNumber)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.hkBlue.opacity(0.1))
                            .foregroundColor(.hkBlue)
                            .cornerRadius(4)
                    }
                    
                    if let distance = step.distance {
                        Text(String(format: "%.1f 公里", distance))
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    
                    Text("\(step.duration) 分鐘")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal)
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

struct TransportModeTag: View {
    let mode: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconForTransport(mode))
                .font(.caption2)
            Text(mode)
                .font(.caption2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(colorForTransport(mode).opacity(0.1))
        .foregroundColor(colorForTransport(mode))
        .cornerRadius(8)
    }
    
    private func iconForTransport(_ mode: String) -> String {
        switch mode {
        case "MTR": return "train.side.front.car"
        case "Bus": return "bus"
        case "Walk": return "figure.walk"
        default: return "questionmark"
        }
    }
    
    private func colorForTransport(_ mode: String) -> Color {
        switch mode {
        case "MTR": return .red
        case "Bus": return .green
        case "Walk": return .gray
        default: return .blue
        }
    }
}

struct WeatherImpactView: View {
    let impact: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("旅行建議")
                    .font(.headline)
                Text(impact)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
}

struct RouteOptionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
}

#Preview {
    let travelDataManager = TravelDataManager.shared
    let routes = travelDataManager.getRoutes(
        from: travelDataManager.locations.first!,
        to: travelDataManager.locations.last!
    )
    
    return RouteResultsView(routes: routes)
}
