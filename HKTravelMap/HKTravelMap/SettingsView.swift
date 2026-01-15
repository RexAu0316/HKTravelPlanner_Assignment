//
//  SettingsView.swift
//  HKTravelMap
//
//  Created by Rex Au on 7/1/2026.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var notificationsEnabled = true
    @State private var locationAccess = true
    @AppStorage("saveHistory") private var saveHistory = true
    @State private var autoUpdate = true
    @State private var selectedLanguage = "English"
    @State private var selectedMapProvider = "Apple Maps"
    @State private var colorSchemeMode: ColorSchemeMode = .system
    
    let languages = ["English", "Traditional Chinese", "Simplified Chinese"]
    let mapProviders = ["Apple Maps", "Google Maps"]
    
    @ObservedObject var travelDataManager = TravelDataManager.shared
    @State private var showingClearHistoryAlert = false
    @State private var showingClearFavoritesAlert = false
    
    enum ColorSchemeMode: String, CaseIterable {
        case system = "跟隨系統"
        case light = "淺色模式"
        case dark = "深色模式"
    }
    
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
                // 暗黑模式選項
                HStack {
                    Image(systemName: colorSchemeIcon)
                        .foregroundColor(colorSchemeIconColor)
                        .frame(width: 30)
                    
                    Picker("主題模式", selection: $colorSchemeMode) {
                        ForEach(ColorSchemeMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue)
                                .tag(mode)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: colorSchemeMode) { newValue in
                        updateDarkModeSetting(for: newValue)
                    }
                }
                
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.blue)
                        .frame(width: 30)
                    Toggle("位置存取", isOn: $locationAccess)
                }
                
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.orange)
                        .frame(width: 30)
                    Toggle("保存歷史", isOn: $saveHistory)
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
                    Text("語言")
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
                    Text("地圖提供商")
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
                        Text("交通偏好")
                    }
                }
            }
            
            // Personal Data Section
            Section(header: Text("個人資料")) {
                Button(action: {
                    showingClearHistoryAlert = true
                }) {
                    HStack {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.red)
                            .frame(width: 30)
                        Text("清除歷史")
                        Spacer()
                        Text("\(travelDataManager.recentRoutes.count) 項")
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
                        Text("清除收藏")
                        Spacer()
                        Text("\(travelDataManager.getFavoriteLocations().count) 項")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .foregroundColor(.red)
                }
            }
            
            // Account Actions Section
            Section {
                Button(action: {
                    // 登出操作
                }) {
                    HStack {
                        Spacer()
                        Text("登出")
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
                
                Button(action: {
                    // 刪除帳號操作
                }) {
                    HStack {
                        Spacer()
                        Text("刪除帳號")
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
            }
            
            // About Section
            Section {
                NavigationLink(destination: AboutView()) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        Text("關於應用程式")
                    }
                }
                
                NavigationLink(destination: TermsOfServiceView()) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.gray)
                            .frame(width: 30)
                        Text("服務條款")
                    }
                }
                
                NavigationLink(destination: PrivacyPolicyView()) {
                    HStack {
                        Image(systemName: "hand.raised")
                            .foregroundColor(.green)
                            .frame(width: 30)
                        Text("隱私政策")
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("設定")
        .onAppear {
            // 加載保存的主題模式設置
            loadColorSchemeMode()
        }
        .alert("清除歷史", isPresented: $showingClearHistoryAlert) {
            Button("取消", role: .cancel) { }
            Button("清除全部", role: .destructive) {
                travelDataManager.clearHistory()
            }
        } message: {
            Text("確定要清除所有歷史記錄嗎？此操作無法還原。")
        }
        .alert("清除收藏", isPresented: $showingClearFavoritesAlert) {
            Button("取消", role: .cancel) { }
            Button("清除全部", role: .destructive) {
                travelDataManager.clearFavorites()
            }
        } message: {
            Text("確定要清除所有收藏嗎？此操作無法還原。")
        }
    }
    
    private var colorSchemeIcon: String {
        switch colorSchemeMode {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "circle.lefthalf.filled"
        }
    }
    
    private var colorSchemeIconColor: Color {
        switch colorSchemeMode {
        case .light: return .orange
        case .dark: return .purple
        case .system: return .blue
        }
    }
    
    private func loadColorSchemeMode() {
        if let savedMode = UserDefaults.standard.string(forKey: "colorSchemeMode"),
           let mode = ColorSchemeMode(rawValue: savedMode) {
            colorSchemeMode = mode
        } else {
            colorSchemeMode = .system
        }
    }
    
    private func updateDarkModeSetting(for mode: ColorSchemeMode) {
        // 保存模式到 UserDefaults
        UserDefaults.standard.set(mode.rawValue, forKey: "colorSchemeMode")
        
        // 根據模式設置 isDarkMode
        switch mode {
        case .system:
            // 跟隨系統設置
            let isSystemDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
            isDarkMode = isSystemDarkMode
        case .light:
            isDarkMode = false
        case .dark:
            isDarkMode = true
        }
    }
}

// MARK: - 創建一個擴展來處理系統主題變更
extension View {
    @ViewBuilder
    func preferredColorScheme(for mode: SettingsView.ColorSchemeMode) -> some View {
        switch mode {
        case .system:
            self.preferredColorScheme(nil) // 跟隨系統
        case .light:
            self.preferredColorScheme(.light)
        case .dark:
            self.preferredColorScheme(.dark)
        }
    }
}

// MARK: - 修改 HKTravelMapApp.swift 來支持三種模式
// 在 HKTravelMapApp.swift 中，需要這樣修改：
/*
@main
struct HKTravelMapApp: App {
    @AppStorage("colorSchemeMode") private var colorSchemeMode = "跟隨系統"
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    setupColorScheme()
                }
                .onChange(of: colorSchemeMode) { _ in
                    setupColorScheme()
                }
        }
    }
    
    private func setupColorScheme() {
        let mode = SettingsView.ColorSchemeMode(rawValue: colorSchemeMode) ?? .system
        
        switch mode {
        case .system:
            // 跟隨系統設置
            let isSystemDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
            isDarkMode = isSystemDarkMode
        case .light:
            isDarkMode = false
        case .dark:
            isDarkMode = true
        }
    }
}
*/

// MARK: - Subpages (保持原樣不變，但可以添加暗黑模式支持)
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
            Section(header: Text("偏好的交通方式")) {
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
            
            Section(header: Text("其他設定")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("最大步行距離")
                    HStack {
                        Slider(value: .constant(1.0), in: 0.1...5.0, step: 0.1)
                        Text("1.0 公里")
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 8)
                
                Toggle("避免樓梯/電梯", isOn: .constant(false))
                Toggle("偏好有蓋行人路", isOn: .constant(true))
            }
        }
        .navigationTitle("交通偏好")
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

// MARK: - 其他子頁面保持原樣，但已翻譯為中文
struct NotificationSettingsView: View {
    @State private var routeNotifications = true
    @State private var weatherAlerts = true
    @State private var trafficAlerts = true
    @State private var promotionNotifications = false
    
    var body: some View {
        List {
            Section(header: Text("通知類型")) {
                Toggle("路線更新", isOn: $routeNotifications)
                Toggle("天氣警報", isOn: $weatherAlerts)
                Toggle("交通警報", isOn: $trafficAlerts)
                Toggle("促銷資訊", isOn: $promotionNotifications)
            }
            
            Section(header: Text("通知時間")) {
                DatePicker("每日提醒", selection: .constant(Date()), displayedComponents: .hourAndMinute)
                Toggle("非工作時間靜音", isOn: .constant(true))
            }
            
            Section(header: Text("緊急警報")) {
                Toggle("極端天氣", isOn: .constant(true))
                Toggle("重大交通中斷", isOn: .constant(true))
            }
        }
        .navigationTitle("通知設定")
        .listStyle(InsetGroupedListStyle())
    }
}

struct DataUsageView: View {
    var body: some View {
        List {
            Section(header: Text("數據用量")) {
                HStack {
                    Text("地圖數據")
                    Spacer()
                    Text("245 MB")
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text("路線數據")
                    Spacer()
                    Text("156 MB")
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text("緩存數據")
                    Spacer()
                    Text("89 MB")
                        .foregroundColor(.gray)
                }
            }
            
            Section(header: Text("數據設定")) {
                Toggle("僅Wi-Fi下載", isOn: .constant(true))
                Toggle("自動刪除舊數據", isOn: .constant(false))
            }
            
            Section {
                Button("清除所有數據") {
                    // 清除數據操作
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("數據用量")
        .listStyle(InsetGroupedListStyle())
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("服務條款")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("最後更新：2025年12月31日")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Group {
                    Text("1. 接受條款")
                        .font(.headline)
                    Text("通過下載、安裝或使用香港旅遊規劃應用程式，您同意受這些服務條款的約束。如果您不同意這些條款，請不要使用本應用程式。")
                    
                    Text("2. 服務說明")
                        .font(.headline)
                    Text("本應用程式提供香港的旅遊規劃服務，包括但不限於路線規劃、交通資訊、天氣資訊等。我們努力提供準確的資訊，但不能保證實時準確性。")
                    
                    Text("3. 用戶責任")
                        .font(.headline)
                    Text("您對使用本應用程式導致的任何損壞或損失負責。使用應用程式時，請遵守所有適用法律和法規。")
                    
                    Text("4. 隱私政策")
                        .font(.headline)
                    Text("您的隱私對我們很重要。請查看我們的隱私政策，了解我們如何收集、使用和保護您的個人資訊。")
                    
                    Text("5. 服務變更")
                        .font(.headline)
                    Text("我們保留隨時修改或終止服務的權利，恕不另行通知。我們不對服務的任何修改、價格變更、暫停或終止承擔責任。")
                }
                .padding(.bottom, 8)
            }
            .padding()
        }
        .navigationTitle("服務條款")
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("隱私政策")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("最後更新：2025年12月31日")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text("我們重視您的隱私。本隱私政策解釋了香港旅遊規劃如何收集、使用和保護您的個人資訊。")
                    .font(.headline)
                
                Group {
                    Text("我們收集的資訊")
                        .font(.headline)
                    Text("我們可能會收集以下資訊：\n• 位置數據（用於路線規劃）\n• 搜索歷史\n• 設備資訊\n• 使用統計")
                    
                    Text("我們如何使用資訊")
                        .font(.headline)
                    Text("我們使用收集的資訊來：\n• 提供和改進服務\n• 個性化用戶體驗\n• 分析使用模式\n• 發送重要通知")
                    
                    Text("數據安全")
                        .font(.headline)
                    Text("我們採取合理的安全措施來保護您的個人資訊，但不能保證絕對安全。")
                    
                    Text("第三方服務")
                        .font(.headline)
                    Text("我們可能會使用第三方服務（例如地圖服務、天氣API）來提供功能。這些服務有自己的隱私政策。")
                    
                    Text("聯繫我們")
                        .font(.headline)
                    Text("如果您對我們的隱私政策有任何疑問，請聯繫我們：privacy@hktravelplanner.com")
                }
                .padding(.bottom, 8)
            }
            .padding()
        }
        .navigationTitle("隱私政策")
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
                    Text("香港旅遊規劃")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("版本 1.0.0")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text("為香港居民和遊客提供智能旅遊規劃")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("功能特色")
                        .font(.headline)
                    
                    FeatureRow(
                        icon: "map.fill",
                        title: "智能路線規劃",
                        description: "結合實時交通、天氣和個人偏好"
                    )
                    
                    FeatureRow(
                        icon: "cloud.sun.fill",
                        title: "實時天氣資訊",
                        description: "根據天氣情況調整路線"
                    )
                    
                    FeatureRow(
                        icon: "clock.fill",
                        title: "多種交通方式",
                        description: "港鐵、巴士、小巴、渡輪等"
                    )
                    
                    FeatureRow(
                        icon: "star.fill",
                        title: "個人化收藏",
                        description: "保存常用地點和路線"
                    )
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("開發團隊")
                        .font(.headline)
                    
                    Text("本應用程式由香港高等科技教育學院（THEi）的學生開發，作為VT6002CEM移動應用程式開發課程作業的一部分。")
                        .font(.body)
                }
                .padding()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("特別感謝")
                        .font(.headline)
                    
                    Text("• 香港天文台 - 天氣數據API\n• 港鐵公司 - 交通數據\n• 運輸署 - 公共交通資訊")
                        .font(.body)
                }
                .padding()
                
                Text("© 2025-2026 香港旅遊規劃。保留所有權利。")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top)
            }
            .padding(.vertical)
        }
        .navigationTitle("關於應用程式")
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
