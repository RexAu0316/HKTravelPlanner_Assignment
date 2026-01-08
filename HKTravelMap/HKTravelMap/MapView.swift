// MapView.swift - 简单直接的用户定位版本
import SwiftUI
import MapKit
import CoreLocation

struct MapView: View {
    @StateObject private var locationManager = LocationManager.shared
    @ObservedObject var travelDataManager = TravelDataManager.shared
    
    // 地图区域状态
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 22.3193, longitude: 114.1694),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    @State private var selectedLocation: Location?
    @State private var searchText = ""
    
    var body: some View {
        ZStack {
            // 1. 核心地图视图
            Map(
                coordinateRegion: $region,
                interactionModes: .all,
                showsUserLocation: true,
                userTrackingMode: .constant(.none),
                annotationItems: travelDataManager.locations
            ) { location in
                MapAnnotation(coordinate: location.coordinate) {
                    MapMarker(location: location, selectedLocation: $selectedLocation)
                }
            }
            .mapStyle(.standard)
            .edgesIgnoringSafeArea(.top)
            
            // 2. 简单的UI覆盖层
            VStack {
                // 顶部搜索栏
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("搜尋地點", text: $searchText)
                            .padding(.vertical, 8)
                    }
                    .padding(.horizontal, 10)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(radius: 2)
                    
                    if !searchText.isEmpty {
                        Button("搜尋") {
                            searchLocation()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.hkBlue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 60)
                
                Spacer()
                
                // 底部按钮
                HStack {
                    Spacer()
                    
                    VStack(spacing: 15) {
                        // 定位按钮 - 核心功能
                        Button(action: {
                            locateUserNow()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 50, height: 50)
                                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                                
                                Image(systemName: "location.fill")
                                    .font(.title2)
                                    .foregroundColor(.hkBlue)
                            }
                        }
                        
                        // 香港按钮
                        Button(action: {
                            centerOnHongKong()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 50, height: 50)
                                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                                
                                Image(systemName: "mappin.and.ellipse")
                                    .font(.title2)
                                    .foregroundColor(.hkRed)
                            }
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationTitle("地圖")
        .navigationBarHidden(true)
        .onAppear {
            // 应用启动时立即尝试定位
            locateUserOnAppear()
        }
    }
    
    // MARK: - 核心定位函数
    
    /// 应用启动时定位用户
    private func locateUserOnAppear() {
        print("🗺️ 应用启动，开始定位...")
        
        // 检查位置服务是否可用
        guard CLLocationManager.locationServicesEnabled() else {
            print("❌ 位置服务未启用")
            return
        }
        
        // 检查当前授权状态
        let status = locationManager.authorizationStatus
        print("🗺️ 当前授权状态: \(status.rawValue)")
        
        switch status {
        case .notDetermined:
            // 首次使用，请求权限
            print("🗺️ 请求位置权限")
            locationManager.requestPermission()
            
        case .authorizedWhenInUse, .authorizedAlways:
            // 已有权限，开始定位
            print("🗺️ 已有权限，开始更新位置")
            locationManager.startUpdatingLocation()
            
            // 如果已经有位置，立即居中
            if let userLocation = locationManager.userLocation {
                print("🗺️ 已有位置，立即居中")
                centerOnLocation(userLocation.coordinate)
            } else {
                // 等待位置更新
                print("🗺️ 等待位置更新...")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if let userLocation = locationManager.userLocation {
                        centerOnLocation(userLocation.coordinate)
                    } else {
                        print("❌ 2秒后仍未获取到位置")
                    }
                }
            }
            
        case .denied, .restricted:
            print("❌ 位置权限被拒绝")
            // 显示香港作为默认位置
            
        @unknown default:
            break
        }
    }
    
    /// 点击定位按钮时调用
    private func locateUserNow() {
        print("📍 用户点击定位按钮")
        
        let status = locationManager.authorizationStatus
        
        switch status {
        case .notDetermined:
            // 请求权限
            locationManager.requestPermission()
            
        case .authorizedWhenInUse, .authorizedAlways:
            // 确保位置更新已启动
            locationManager.startUpdatingLocation()
            
            // 尝试获取当前位置
            if let userLocation = locationManager.userLocation {
                print("📍 成功获取位置，居中显示")
                centerOnLocation(userLocation.coordinate)
            } else {
                print("📍 等待获取位置...")
                
                // 等待3秒获取位置
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    if let userLocation = locationManager.userLocation {
                        centerOnLocation(userLocation.coordinate)
                    } else {
                        print("❌ 3秒后仍未获取到位置")
                    }
                }
            }
            
        case .denied, .restricted:
            print("❌ 用户已拒绝位置权限")
            
        @unknown default:
            break
        }
    }
    
    /// 居中到香港
    private func centerOnHongKong() {
        print("🇭🇰 居中到香港")
        let hongKongCoordinate = CLLocationCoordinate2D(latitude: 22.3193, longitude: 114.1694)
        centerOnLocation(hongKongCoordinate)
    }
    
    /// 通用的位置居中函数
    private func centerOnLocation(_ coordinate: CLLocationCoordinate2D) {
        print("📍 移动地图到坐标: \(coordinate.latitude), \(coordinate.longitude)")
        
        withAnimation(.easeInOut(duration: 0.5)) {
            region.center = coordinate
            region.span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        }
    }
    
    /// 搜索地点
    private func searchLocation() {
        guard !searchText.isEmpty else { return }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = region
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            DispatchQueue.main.async {
                if let response = response, let firstResult = response.mapItems.first {
                    // 移动到搜索结果
                    centerOnLocation(firstResult.placemark.coordinate)
                    
                    // 创建位置对象
                    let newLocation = Location(
                        name: firstResult.name ?? "未知地點",
                        address: firstResult.placemark.title ?? "未知地址",
                        latitude: firstResult.placemark.coordinate.latitude,
                        longitude: firstResult.placemark.coordinate.longitude,
                        category: "搜索結果"
                    )
                    
                    selectedLocation = newLocation
                }
            }
        }
    }
}

// MARK: - 地图标记视图
struct MapMarker: View {
    let location: Location
    @Binding var selectedLocation: Location?
    
    var body: some View {
        Button(action: {
            withAnimation {
                selectedLocation = location
            }
        }) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 36, height: 36)
                        .shadow(radius: 3)
                    
                    Image(systemName: location.isFavorite ? "star.fill" : "mappin.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(location.isFavorite ? .yellow : .hkRed)
                }
                
                Text(location.name.components(separatedBy: ",").first ?? "")
                    .font(.system(size: 10, weight: .medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(4)
                    .offset(y: 5)
            }
        }
    }
}

// MARK: - 预览
#Preview {
    NavigationView {
        MapView()
    }
}
