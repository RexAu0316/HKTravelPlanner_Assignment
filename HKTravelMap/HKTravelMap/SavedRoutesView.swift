//
//  SavedRoutesView.swift
//  HKTravelMap
//
//  Created by Rex Au on 7/1/2026.
//

import SwiftUI

struct SavedRoutesView: View {
    @ObservedObject var travelDataManager = TravelDataManager.shared
    @Environment(\.presentationMode) var presentationMode
    @State private var showingClearAlert = false
    @State private var selectedRoute: TravelRoute?
    @State private var showRouteDetails = false
    
    var body: some View {
        NavigationView {
            Group {
                if travelDataManager.savedRoutes.isEmpty {
                    EmptySavedRoutesView()
                } else {
                    List {
                        ForEach(travelDataManager.savedRoutes) { route in
                            SavedRouteCard(route: route)
                                .onTapGesture {
                                    selectedRoute = route
                                    showRouteDetails = true
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        removeRoute(route)
                                    } label: {
                                        Label("刪除", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("已保存路線")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("完成") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: !travelDataManager.savedRoutes.isEmpty ?
                    Button(action: {
                        showingClearAlert = true
                    }) {
                        Text("清除全部")
                            .foregroundColor(.red)
                    } : nil
            )
            .alert("清除所有保存的路線", isPresented: $showingClearAlert) {
                Button("取消", role: .cancel) { }
                Button("清除", role: .destructive) {
                    travelDataManager.clearSavedRoutes()
                }
            } message: {
                Text("確定要清除所有已保存的路線嗎？此操作無法撤銷。")
            }
            .sheet(isPresented: $showRouteDetails) {
                if let route = selectedRoute {
                    SavedRouteDetailView(route: route)
                }
            }
        }
    }
    
    private func removeRoute(_ route: TravelRoute) {
        travelDataManager.removeSavedRoute(route)
    }
}

struct EmptySavedRoutesView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "map")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("尚未保存任何路線")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("在路線規劃結果中點擊「保存路線」按鈕來收藏常用路線")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxHeight: .infinity)
        .padding()
    }
}

struct SavedRouteCard: View {
    let route: TravelRoute
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        
                        Text(route.startLocation.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                    }
                    
                    HStack {
                        Image(systemName: "flag.circle.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                        
                        Text(route.endLocation.name)
                            .font(.subheadline)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(route.duration)分鐘")
                        .font(.headline)
                        .foregroundColor(.hkBlue)
                    
                    Text(formatDate(route.departureTime))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(spacing: 8) {
                ForEach(route.transportationModes.prefix(3), id: \.self) { mode in
                    TransportModeCapsule(mode: mode)
                }
                
                if route.transportationModes.count > 3 {
                    Text("+\(route.transportationModes.count - 3)")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.secondary)
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct SavedRouteDetailView: View {
    let route: TravelRoute
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var travelDataManager = TravelDataManager.shared
    
    var isSaved: Bool {
        travelDataManager.isRouteSaved(route)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 路線摘要
                    RouteSummaryCard(route: route)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    // 詳細步驟
                    VStack(alignment: .leading, spacing: 16) {
                        Text("詳細步驟")
                            .font(.headline)
                            .foregroundColor(.hkBlue)
                            .padding(.horizontal)
                        
                        ForEach(route.steps) { step in
                            RouteStepDetailCard(step: step)
                                .padding(.horizontal)
                        }
                    }
                    
                    // 操作按鈕
                    VStack(spacing: 12) {
                        Button(action: {
                            // 重新使用此路線
                            useRouteAgain()
                        }) {
                            Text("重新規劃此路線")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.hkBlue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        
                        Button(action: {
                            if isSaved {
                                travelDataManager.removeSavedRoute(route)
                            } else {
                                travelDataManager.addSavedRoute(route)
                            }
                        }) {
                            HStack {
                                Image(systemName: isSaved ? "bookmark.slash" : "bookmark")
                                Text(isSaved ? "從收藏中移除" : "重新保存")
                            }
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.gray.opacity(0.1))
                            .foregroundColor(.gray)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                }
                .padding(.bottom, 30)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("路線詳情")
            .navigationBarItems(trailing: Button("完成") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func useRouteAgain() {
        // 這裡可以實現重新規劃路線的邏輯
        // 例如，將起點和終點傳遞回主頁面
        print("重新規劃路線: \(route.startLocation.name) → \(route.endLocation.name)")
        
        // 添加觸覺反饋
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // 關閉視圖
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    SavedRoutesView()
}
