//
//  FavoritesView.swift
//  HKTravelMap
//
//  Created by Rex Au on 7/1/2026.
//

import SwiftUI

struct FavoritesView: View {
    @ObservedObject var travelDataManager = TravelDataManager.shared
    
    var body: some View {
        List {
            Section(header: Text("收藏地點")) {
                ForEach(travelDataManager.locations.filter { $0.isFavorite }) { location in
                    LocationRow(location: location)
                }
            }
            
            Section(header: Text("所有地點")) {
                ForEach(travelDataManager.locations) { location in
                    LocationRow(location: location)
                }
            }
            
            Section(header: Text("分類")) {
                ForEach(["Transport Hub", "Shopping", "Dining", "Entertainment"], id: \.self) { category in
                    HStack {
                        Image(systemName: iconForCategory(category))
                            .foregroundColor(colorForCategory(category))
                            .frame(width: 30)
                        
                        Text(category)
                        
                        Spacer()
                        
                        Text("\(travelDataManager.locations.filter { $0.category == category }.count)")
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("我的收藏")
        .listStyle(.insetGrouped)
    }
    
    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "Transport Hub":
            return "train.side.front.car"
        case "Shopping":
            return "bag.fill"
        case "Dining":
            return "fork.knife"
        case "Entertainment":
            return "film.fill"
        default:
            return "mappin.circle.fill"
        }
    }
    
    private func colorForCategory(_ category: String) -> Color {
        switch category {
        case "Transport Hub":
            return .blue
        case "Shopping":
            return .pink
        case "Dining":
            return .orange
        case "Entertainment":
            return .purple
        default:
            return .gray
        }
    }
}

struct LocationRow: View {
    let location: Location
    @State private var isFavorite: Bool
    
    init(location: Location) {
        self.location = location
        _isFavorite = State(initialValue: location.isFavorite)
    }
    
    var body: some View {
        HStack {
            Image(systemName: "mappin.circle.fill")
                .foregroundColor(.hkRed)
                .font(.title2)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(location.name)
                    .font(.headline)
                Text(location.address)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                if !location.category.isEmpty {
                    Text(location.category)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.hkBlue.opacity(0.1))
                        .foregroundColor(.hkBlue)
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            Button(action: {
                isFavorite.toggle()
                TravelDataManager.shared.updateFavoriteStatus(for: location.id, isFavorite: isFavorite)
            }) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .foregroundColor(isFavorite ? .yellow : .gray)
                    .font(.title3)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationView {
        FavoritesView()
    }
}
