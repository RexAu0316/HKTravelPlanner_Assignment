// LocationManager.swift - 完整修复版
import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    
    private let locationManager = CLLocationManager()
    
    // 发布位置信息
    @Published var userLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: String?
    
    // 位置更新计数器（用于调试）
    @Published var locationUpdateCount = 0
    
    // 是否正在获取位置
    @Published var isUpdatingLocation = false
    
    override init() {
        super.init()
        print("📍 LocationManager 初始化")
        
        // 设置位置管理器
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10  // 每移动10米更新一次
        locationManager.activityType = .otherNavigation
        locationManager.pausesLocationUpdatesAutomatically = false
        
        // 检查当前授权状态
        authorizationStatus = locationManager.authorizationStatus
        print("📍 当前授权状态: \(authorizationStatusToString(authorizationStatus))")
    }
    
    // MARK: - 公开方法
    
    /// 请求位置权限
    func requestPermission() {
        print("📍 请求位置权限...")
        
        let status = locationManager.authorizationStatus
        
        switch status {
        case .notDetermined:
            print("📍 首次请求位置权限")
            locationManager.requestWhenInUseAuthorization()
            
        case .authorizedWhenInUse, .authorizedAlways:
            print("📍 已有权限，开始更新位置")
            startUpdatingLocation()
            
        case .denied, .restricted:
            print("📍 位置权限被拒绝或受限")
            locationError = "位置服務已停用。請前往設定 > 隱私權 > 定位服務中啟用。"
            
        @unknown default:
            break
        }
    }
    
    /// 开始更新位置
    func startUpdatingLocation() {
        print("📍 开始更新位置...")
        
        guard CLLocationManager.locationServicesEnabled() else {
            locationError = "設備位置服務未啟用。"
            print("❌ 设备位置服务未启用")
            return
        }
        
        let status = locationManager.authorizationStatus
        print("📍 检查权限状态: \(authorizationStatusToString(status))")
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            isUpdatingLocation = true
            locationManager.startUpdatingLocation()
            print("📍 位置更新已启动")
            
        case .notDetermined:
            print("📍 尚未请求权限，正在请求...")
            locationManager.requestWhenInUseAuthorization()
            
        case .denied, .restricted:
            locationError = "位置權限被拒絕。請前往設定啟用位置服務。"
            print("❌ 位置权限被拒绝")
            
        @unknown default:
            break
        }
    }
    
    /// 停止更新位置
    func stopUpdatingLocation() {
        isUpdatingLocation = false
        locationManager.stopUpdatingLocation()
        print("📍 位置更新已停止")
    }
    
    /// 获取当前位置（一次性）
    func requestCurrentLocation() {
        print("📍 请求当前位置...")
        
        let status = locationManager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.requestLocation()
        } else {
            requestPermission()
        }
    }
    
    /// 获取香港坐标（备用）
    func getHongKongCoordinate() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: 22.3193, longitude: 114.1694)
    }
    
    /// 检查是否有有效的位置
    var hasValidLocation: Bool {
        return userLocation != nil && userLocation!.horizontalAccuracy >= 0
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        locationUpdateCount += 1
        
        DispatchQueue.main.async {
            self.userLocation = location
            self.locationError = nil
            
            // 输出位置信息到控制台
            print("📍 位置更新 #\(self.locationUpdateCount):")
            print("   纬度: \(location.coordinate.latitude)")
            print("   经度: \(location.coordinate.longitude)")
            print("   精度: \(location.horizontalAccuracy) 米")
            print("   时间: \(location.timestamp)")
            
            // 如果精度太差，继续等待更好的位置
            if location.horizontalAccuracy > 100 {
                print("⚠️ 位置精度较差 (\(location.horizontalAccuracy)米)，继续等待更精确的位置")
            } else {
                print("✅ 位置精度良好 (\(location.horizontalAccuracy)米)")
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("📍 授权状态变更: \(authorizationStatusToString(status))")
        
        DispatchQueue.main.async {
            self.authorizationStatus = status
            
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.locationError = nil
                self.isUpdatingLocation = true
                manager.startUpdatingLocation()
                
                // 权限刚获得，立即请求一次位置
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    manager.requestLocation()
                }
                
            case .denied, .restricted:
                self.locationError = "位置權限被拒絕。請前往設定啟用位置服務。"
                self.isUpdatingLocation = false
                manager.stopUpdatingLocation()
                
            case .notDetermined:
                self.isUpdatingLocation = false
                
            @unknown default:
                break
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ 位置更新失败: \(error.localizedDescription)")
        
        DispatchQueue.main.async {
            self.locationError = "獲取位置失敗: \(error.localizedDescription)"
        }
    }
    
    // MARK: - 辅助函数
    
    private func authorizationStatusToString(_ status: CLAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "未決定"
        case .restricted: return "受限制"
        case .denied: return "已拒絕"
        case .authorizedAlways: return "始終允許"
        case .authorizedWhenInUse: return "使用時允許"
        @unknown default: return "未知"
        }
    }
}
