//
//  MapView.swift
//  HKTravelMap
//
//  Created by Rex Au on 7/1/2026.
//

import SwiftUI

struct MapView: View {
    @ObservedObject var travelDataManager = TravelDataManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Map Placeholder
            ZStack {
                // Map Background
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.green.opacity(0.3), Color.blue.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 400)
                    .overlay(
                        // Simulated Map Markers
                        ZStack {
                            // Victoria Harbour
                            Rectangle()
                                .fill(Color.blue.opacity(0.5))
                                .frame(width: 300, height: 60)
                                .offset(y: 30)
                            
                            // Location Markers
                            ForEach(travelDataManager.locations.indices, id: \.self) { index in
                                let location = travelDataManager.locations[index]
                                let xOffset = CGFloat((Double(index) - 2.0) * 60.0)
                                let yOffset = CGFloat.random(in: -50...50)
                                
                                VStack(spacing: 4) {
                                    Image(systemName: location.isFavorite ? "star.circle.fill" : "mappin.circle.fill")
                                        .font(.title)
                                        .foregroundColor(location.isFavorite ? .yellow : .hkRed)
                                        .background(Circle().fill(Color.white).frame(width: 24, height: 24))
                                    
                                    Text(location.name.split(separator: " ").first?.description ?? "")
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.black.opacity(0.7))
                                        .foregroundColor(.white)
                                        .cornerRadius(4)
                                }
                                .offset(x: xOffset, y: yOffset)
                            }
                        }
                    )
                
                // Map Center Marker
                Circle()
                    .stroke(Color.hkRed, lineWidth: 3)
                    .frame(width: 20, height: 20)
                    .background(Circle().fill(Color.white).frame(width: 10, height: 10))
            }
            
            // Map Controls Area
            ScrollView {
                VStack(spacing: 20) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("搜尋地點或地址", text: .constant(""))
                        Button(action: {}) {
                            Text("搜尋")
                                .font(.subheadline)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.hkBlue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    .padding(.horizontal)
                    
                    // Quick Location Buttons
                    VStack(alignment: .leading, spacing: 12) {
                        Text("快速位置")
                            .font(.headline)
                            .foregroundColor(.hkBlue)
                        
                        HStack(spacing: 15) {
                            MapActionButton(
                                icon: "location.fill",
                                title: "當前位置",
                                color: .blue
                            ) {
                                // Go to current location
                            }
                            
                            MapActionButton(
                                icon: "house.fill",
                                title: "住家",
                                color: .green
                            ) {
                                // Go to home
                            }
                            
                            MapActionButton(
                                icon: "briefcase.fill",
                                title: "工作",
                                color: .orange
                            ) {
                                // Go to work
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Nearby Places
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("附近地點")
                                .font(.headline)
                                .foregroundColor(.hkBlue)
                            
                            Spacer()
                            
                            Button("查看全部") {
                                // Show all nearby places
                            }
                            .font(.subheadline)
                            .foregroundColor(.accentOrange)
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(travelDataManager.locations.prefix(5)) { location in
                                    NearbyPlaceCard(location: location)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Map Features
                    VStack(alignment: .leading, spacing: 12) {
                        Text("地圖功能")
                            .font(.headline)
                            .foregroundColor(.hkBlue)
                        
                        HStack(spacing: 15) {
                            MapFeatureButton(
                                icon: "layers",
                                title: "圖層",
                                description: "切換地圖樣式"
                            )
                            
                            MapFeatureButton(
                                icon: "arrow.triangle.turn.up.right.diamond",
                                title: "導航",
                                description: "開始導航"
                            )
                            
                            MapFeatureButton(
                                icon: "eye",
                                title: "街景",
                                description: "查看街景級別"
                            )
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color.lightBackground)
        }
        .navigationTitle("地圖")
    }
}

struct MapActionButton: View {
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
                    .frame(width: 50, height: 50)
                    .background(color.opacity(0.1))
                    .cornerRadius(12)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct NearbyPlaceCard: View {
    let location: Location
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: location.isFavorite ? "star.fill" : "mappin.circle.fill")
                .font(.title2)
                .foregroundColor(location.isFavorite ? .yellow : .hkRed)
                .frame(height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(location.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text("1.2km 距離")
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                HStack {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    Text("4.5")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(width: 120)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

struct MapFeatureButton: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.hkBlue)
                .frame(width: 40, height: 40)
                .background(Color.hkBlue.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    NavigationView {
        MapView()
    }
}
