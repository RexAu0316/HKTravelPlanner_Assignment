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
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedRouteId: UUID?
    @State private var expandedRouteId: UUID?
    @State private var showShareSheet = false
    @State private var showSaveConfirmation = false
    @State private var isSaved = false
    @State private var activeTab = 0
    @State private var mapViewHeight: CGFloat = 300
    @State private var showRouteDetails = false
    
    // 添加 TravelDataManager 觀察對象
    @ObservedObject var travelDataManager = TravelDataManager.shared
    
    // 模擬導航狀態
    @State private var isNavigating = false
    @State private var navigationProgress: Double = 0.0
    @State private var remainingTime: Int = 45
    
    // 保存確認狀態
    @State private var saveSuccessMessage = ""
    @State private var showSaveSuccess = false
    
    var selectedRoute: TravelRoute? {
        if let selectedId = selectedRouteId {
            return routes.first { $0.id == selectedId }
        }
        return routes.first
    }
    
    var isCurrentRouteSaved: Bool {
        guard let route = selectedRoute else { return false }
        return travelDataManager.isRouteSaved(route)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // 路線摘要卡片
                    if let firstRoute = routes.first {
                        RouteSummaryCard(route: firstRoute)
                            .padding(.horizontal)
                            .padding(.top)
                    }
                    
                    // 路線選項標籤
                    if routes.count > 1 {
                        RouteOptionsTabs(
                            routes: routes,
                            selectedRouteId: $selectedRouteId,
                            expandedRouteId: $expandedRouteId
                        )
                        .padding(.horizontal)
                        .padding(.top, 16)
                    }
                    
                    // 詳細路線列表
                    LazyVStack(spacing: 16) {
                        ForEach(routes) { route in
                            RouteDetailCard(
                                route: route,
                                isSelected: selectedRouteId == route.id,
                                isExpanded: expandedRouteId == route.id,
                                isSaved: travelDataManager.isRouteSaved(route),
                                onSelect: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedRouteId = route.id
                                        expandedRouteId = route.id
                                    }
                                },
                                onExpand: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        expandedRouteId = expandedRouteId == route.id ? nil : route.id
                                    }
                                },
                                onSave: {
                                    saveRoute(route)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    
                    // 額外選項
                    AdditionalOptionsView()
                        .padding(.horizontal)
                        .padding(.top, 24)
                    
                    // 天氣影響
                    if let weatherImpact = routes.first?.weatherImpact {
                        WeatherImpactCard(impact: weatherImpact)
                            .padding(.horizontal)
                            .padding(.top, 16)
                    }
                    
                    // 操作按鈕
                    ActionButtonsView(
                        isNavigating: $isNavigating,
                        showShareSheet: $showShareSheet,
                        showSaveConfirmation: $showSaveConfirmation,
                        isSaved: $isSaved,
                        onNavigate: startNavigation,
                        onSave: {
                            if let route = selectedRoute {
                                saveRoute(route)
                            }
                        },
                        onClose: { presentationMode.wrappedValue.dismiss() }
                    )
                    .padding(.horizontal)
                    .padding(.top, 24)
                    .padding(.bottom, 30)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitle("路線結果", displayMode: .inline)
            .navigationBarItems(
                leading: Button("返回") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: HStack(spacing: 16) {
                    // 保存狀態指示器
                    if isCurrentRouteSaved {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text("已保存")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    Button("完成") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            )
            .sheet(isPresented: $showRouteDetails) {
                if let route = routes.first(where: { $0.id == selectedRouteId }) {
                    RouteDetailsFullView(route: route)
                }
            }
            .overlay {
                if isNavigating {
                    NavigationOverlay(
                        progress: navigationProgress,
                        remainingTime: remainingTime,
                        onCancel: cancelNavigation
                    )
                }
                
                // 保存成功提示
                if showSaveSuccess {
                    SaveSuccessOverlay(message: saveSuccessMessage)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    showSaveSuccess = false
                                }
                            }
                        }
                }
            }
            .onAppear {
                if let firstRoute = routes.first {
                    selectedRouteId = firstRoute.id
                    // 檢查是否已保存
                    isSaved = travelDataManager.isRouteSaved(firstRoute)
                }
                
                // 初始化模擬數據
                setupMockData()
            }
            .onChange(of: selectedRouteId) { newId in
                if let route = routes.first(where: { $0.id == newId }) {
                    isSaved = travelDataManager.isRouteSaved(route)
                }
            }
        }
    }
    
    private func setupMockData() {
        // 設置模擬導航進度
        navigationProgress = 0.0
        remainingTime = routes.first?.duration ?? 45
    }
    
    // MARK: - 保存路線功能
    
    private func saveRoute(_ route: TravelRoute) {
        if travelDataManager.isRouteSaved(route) {
            // 如果已保存，詢問是否移除
            removeSavedRoute(route)
        } else {
            // 保存路線
            travelDataManager.addSavedRoute(route)
            isSaved = true
            
            // 顯示保存成功提示
            saveSuccessMessage = "路線已保存到收藏"
            withAnimation(.spring()) {
                showSaveSuccess = true
            }
            
            // 添加觸覺反饋
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            // 3秒後隱藏提示
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeOut) {
                    showSaveSuccess = false
                }
            }
        }
    }
    
    private func removeSavedRoute(_ route: TravelRoute) {
        travelDataManager.removeSavedRoute(route)
        isSaved = false
        
        // 顯示移除提示
        saveSuccessMessage = "已從收藏中移除"
        withAnimation(.spring()) {
            showSaveSuccess = true
        }
        
        // 添加觸覺反饋
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeOut) {
                showSaveSuccess = false
            }
        }
    }
    
    private func startNavigation() {
        withAnimation(.spring()) {
            isNavigating = true
        }
        
        // 模擬導航進度
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if navigationProgress < 1.0 {
                withAnimation(.linear(duration: 1.0)) {
                    navigationProgress += 0.01
                    remainingTime -= 1
                }
            } else {
                timer.invalidate()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring()) {
                        isNavigating = false
                    }
                }
            }
        }
    }
    
    private func cancelNavigation() {
        withAnimation(.spring()) {
            isNavigating = false
            navigationProgress = 0.0
            remainingTime = routes.first?.duration ?? 45
        }
    }
}

// MARK: - 路線摘要卡片
struct RouteSummaryCard: View {
    let route: TravelRoute
    
    var body: some View {
        VStack(spacing: 16) {
            // 起點終點
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                        
                        Text(route.startLocation.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }
                    
                    HStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 2, height: 20)
                            .padding(.leading, 11)
                        
                        Text(route.endLocation.name)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // 時間和費用
                VStack(alignment: .trailing, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(route.duration)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.hkBlue)
                        
                        Text("分鐘")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("約 HK$ \(calculateTotalFare())")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            // 交通方式標籤
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(route.transportationModes, id: \.self) { mode in
                        TransportModeCapsule(mode: mode)
                    }
                    
                    // 天氣標籤
                    if let impact = route.weatherImpact {
                        if impact.contains("雨") {
                            WeatherCapsule(icon: "cloud.rain", text: "雨天", color: .blue)
                        } else if impact.contains("熱") {
                            WeatherCapsule(icon: "sun.max", text: "炎熱", color: .orange)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 5)
        )
    }
    
    private func calculateTotalFare() -> Int {
        // 簡單計算總費用
        var total = 0
        for step in route.steps {
            switch step.transportMode {
            case "MTR": total += 8
            case "Bus": total += 6
            case "Minibus": total += 7
            case "Tram": total += 3
            case "Ferry": total += 5
            case "Taxi": total += 50
            default: total += 0
            }
        }
        return total
    }
}

// MARK: - 交通方式膠囊標籤
struct TransportModeCapsule: View {
    let mode: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconForTransport(mode))
                .font(.caption2)
                .foregroundColor(.white)
            
            Text(mode)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(colorForTransport(mode))
        .cornerRadius(12)
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

// MARK: - 天氣膠囊標籤
struct WeatherCapsule: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.white)
            
            Text(text)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color)
        .cornerRadius(12)
    }
}

// MARK: - 路線選項標籤
struct RouteOptionsTabs: View {
    let routes: [TravelRoute]
    @Binding var selectedRouteId: UUID?
    @Binding var expandedRouteId: UUID?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(routes) { route in
                    RouteOptionTab(
                        route: route,
                        isSelected: selectedRouteId == route.id,
                        isExpanded: expandedRouteId == route.id,
                        onSelect: {
                            selectedRouteId = route.id
                        },
                        onExpand: {
                            expandedRouteId = expandedRouteId == route.id ? nil : route.id
                        }
                    )
                }
            }
        }
    }
}

struct RouteOptionTab: View {
    let route: TravelRoute
    let isSelected: Bool
    let isExpanded: Bool
    let onSelect: () -> Void
    let onExpand: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    // 路線時間和編號
                    VStack(alignment: .leading, spacing: 2) {
                        Text("路線 \(route.id.uuidString.prefix(4))")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(isSelected ? .white : .secondary)
                        
                        Text("\(route.duration)分鐘")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(isSelected ? .white : .primary)
                    }
                    
                    Spacer()
                    
                    // 展開/摺疊按鈕
                    Button(action: onExpand) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(isSelected ? .white : .gray)
                            .frame(width: 20, height: 20)
                            .background(isSelected ? Color.white.opacity(0.2) : Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // 費用
                Text("HK$ \(calculateFare(for: route))")
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .orange)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minWidth: 120)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.hkBlue : Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func calculateFare(for route: TravelRoute) -> Int {
        var total = 0
        for step in route.steps {
            switch step.transportMode {
            case "MTR": total += 8
            case "Bus": total += 6
            case "Minibus": total += 7
            case "Tram": total += 3
            case "Ferry": total += 5
            case "Taxi": total += 50
            default: total += 0
            }
        }
        return total
    }
}

// MARK: - 路線詳細卡片
struct RouteDetailCard: View {
    let route: TravelRoute
    let isSelected: Bool
    let isExpanded: Bool
    let isSaved: Bool
    let onSelect: () -> Void
    let onExpand: () -> Void
    let onSave: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 卡片標題
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(isSelected ? Color.hkBlue : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                        
                        Text("路線 \(route.id.uuidString.prefix(4))")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    
                    HStack(spacing: 8) {
                        Label("\(route.duration)分鐘", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.accentOrange)
                        
                        Label("HK$ \(calculateFare())", systemImage: "dollarsign.circle")
                            .font(.caption)
                            .foregroundColor(.green)
                        
                        Label("\(countTransfers())次轉乘", systemImage: "arrow.triangle.2.circlepath")
                            .font(.caption)
                            .foregroundColor(.purple)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    // 保存狀態指示器
                    if isSaved {
                        Image(systemName: "bookmark.fill")
                            .font(.caption)
                            .foregroundColor(.hkBlue)
                    }
                    
                    // 選擇指示器
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.hkBlue)
                    }
                    
                    // 保存按鈕
                    Button(action: onSave) {
                        Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                            .font(.body)
                            .foregroundColor(isSaved ? .hkBlue : .gray)
                    }
                    
                    // 展開按鈕
                    Button(action: onExpand) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.body)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            .contentShape(Rectangle())
            .onTapGesture(perform: onSelect)
            
            // 展開的詳細內容
            if isExpanded {
                VStack(spacing: 0) {
                    Divider()
                        .padding(.horizontal)
                    
                    // 路線步驟
                    VStack(spacing: 0) {
                        ForEach(Array(route.steps.enumerated()), id: \.element.id) { index, step in
                            RouteStepRow(step: step, isLast: index == route.steps.count - 1)
                        }
                    }
                    .padding(.vertical, 12)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // 操作按鈕
                    HStack(spacing: 12) {
                        Button(action: {
                            // 選擇此路線
                            onSelect()
                        }) {
                            Text("選擇此路線")
                                .font(.caption)
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.hkBlue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        
                        Button(action: onSave) {
                            HStack(spacing: 4) {
                                Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                                Text(isSaved ? "已保存" : "保存路線")
                            }
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(isSaved ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                            .foregroundColor(isSaved ? .green : .gray)
                            .cornerRadius(8)
                        }
                        
                        Button(action: {
                            // 分享路線
                            shareRoute()
                        }) {
                            Text("分享")
                                .font(.caption)
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.purple.opacity(0.1))
                                .foregroundColor(.purple)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .background(Color(.systemBackground))
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color.hkBlue.opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }
    
    private func shareRoute() {
        let routeText = """
        路線: \(route.startLocation.name) → \(route.endLocation.name)
        時間: \(route.duration)分鐘
        費用: HK$ \(calculateFare())
        出發時間: \(formatDate(route.departureTime))
        
        步驟:
        \(route.steps.map { "• \($0.instruction) (\($0.duration)分鐘)" }.joined(separator: "\n"))
        """
        
        let activityViewController = UIActivityViewController(
            activityItems: [routeText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityViewController, animated: true)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func calculateFare() -> Int {
        var total = 0
        for step in route.steps {
            switch step.transportMode {
            case "MTR": total += 8
            case "Bus": total += 6
            case "Minibus": total += 7
            case "Tram": total += 3
            case "Ferry": total += 5
            case "Taxi": total += 50
            default: total += 0
            }
        }
        return total
    }
    
    private func countTransfers() -> Int {
        return route.steps.filter { $0.transportMode != "Walk" }.count - 1
    }
}

// MARK: - 路線步驟行
struct RouteStepRow: View {
    let step: RouteStep
    let isLast: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // 時間線
            VStack(spacing: 0) {
                // 頂部圓點
                Circle()
                    .fill(colorForTransport(step.transportMode))
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                
                // 連接線
                if !isLast {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 24)
            
            // 步驟詳細信息
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(step.instruction)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    Text("\(step.duration)分鐘")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.accentOrange)
                }
                
                // 交通工具信息
                HStack(spacing: 8) {
                    if let lineNumber = step.lineNumber {
                        Text(lineNumber)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(colorForTransport(step.transportMode).opacity(0.1))
                            .foregroundColor(colorForTransport(step.transportMode))
                            .cornerRadius(4)
                    }
                    
                    if let platform = step.platform {
                        Text("月台 \(platform)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    if let distance = step.distance {
                        Text("\(String(format: "%.1f", distance))公里")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // 交通工具圖標
            Image(systemName: iconForTransport(step.transportMode))
                .font(.title3)
                .foregroundColor(colorForTransport(step.transportMode))
                .frame(width: 32)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
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

// MARK: - 額外選項視圖
struct AdditionalOptionsView: View {
    @State private var selectedOption = 0
    
    let options = [
        ("clock.badge.exclamationmark", "時間選項", Color.orange),
        ("dollarsign.circle", "價格比較", Color.green),
        ("leaf", "環保路線", Color.green),
        ("arrow.triangle.swap", "替代路線", Color.blue)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("更多選項")
                .font(.headline)
                .foregroundColor(.hkBlue)
                .padding(.horizontal)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(options.indices, id: \.self) { index in
                    AdditionalOptionButton(
                        icon: options[index].0,
                        title: options[index].1,
                        color: options[index].2,
                        isSelected: selectedOption == index,
                        action: {
                            selectedOption = index
                            // 執行相應操作
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct AdditionalOptionButton: View {
    let icon: String
    let title: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(color.opacity(isSelected ? 0.2 : 0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 天氣影響卡片
struct WeatherImpactCard: View {
    let impact: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: weatherIcon(for: impact))
                .font(.title2)
                .foregroundColor(weatherColor(for: impact))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("旅行建議")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(impact)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(20)
        .background(weatherColor(for: impact).opacity(0.1))
        .cornerRadius(16)
    }
    
    private func weatherIcon(for impact: String) -> String {
        if impact.contains("雨") {
            return "cloud.rain.fill"
        } else if impact.contains("熱") {
            return "sun.max.fill"
        } else if impact.contains("冷") {
            return "thermometer.snowflake"
        } else {
            return "exclamationmark.triangle.fill"
        }
    }
    
    private func weatherColor(for impact: String) -> Color {
        if impact.contains("雨") {
            return .blue
        } else if impact.contains("熱") {
            return .orange
        } else if impact.contains("冷") {
            return .blue
        } else {
            return .yellow
        }
    }
}

// MARK: - 操作按鈕視圖
struct ActionButtonsView: View {
    @Binding var isNavigating: Bool
    @Binding var showShareSheet: Bool
    @Binding var showSaveConfirmation: Bool
    @Binding var isSaved: Bool
    let onNavigate: () -> Void
    let onSave: () -> Void
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // 導航按鈕
            Button(action: {
                if !isNavigating {
                    onNavigate()
                }
            }) {
                HStack {
                    if isNavigating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "play.fill")
                            .font(.headline)
                    }
                    
                    Text(isNavigating ? "導航中..." : "開始導航")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.hkBlue, Color.hkBlue.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .font(.headline)
                .cornerRadius(12)
                .shadow(color: .hkBlue.opacity(0.3), radius: 5, x: 0, y: 3)
            }
            
            HStack(spacing: 12) {
                // 保存按鈕
                Button(action: onSave) {
                    HStack {
                        Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                            .font(.headline)
                            .foregroundColor(isSaved ? .white : .hkBlue)
                        
                        Text(isSaved ? "已保存" : "保存路線")
                            .fontWeight(.medium)
                            .foregroundColor(isSaved ? .white : .hkBlue)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(isSaved ? Color.hkBlue : Color.hkBlue.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.hkBlue, lineWidth: isSaved ? 0 : 1)
                    )
                    .font(.headline)
                    .cornerRadius(12)
                }
                
                // 分享按鈕
                Button(action: { showShareSheet = true }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .font(.headline)
                        
                        Text("分享")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.purple.opacity(0.1))
                    .foregroundColor(.purple)
                    .font(.headline)
                    .cornerRadius(12)
                }
            }
            
            // 返回按鈕
            Button(action: onClose) {
                Text("返回")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.gray.opacity(0.1))
                    .foregroundColor(.gray)
                    .font(.headline)
                    .cornerRadius(12)
            }
            
            // 保存確認提示
            if showSaveConfirmation {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    Text("路線已保存到收藏")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
                .transition(.opacity)
            }
        }
    }
}

// MARK: - 導航覆蓋層
struct NavigationOverlay: View {
    let progress: Double
    let remainingTime: Int
    let onCancel: () -> Void
    
    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // 進度環
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.green, .blue]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1.0), value: progress)
                    
                    VStack(spacing: 4) {
                        Text("\(remainingTime)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("分鐘")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                // 導航信息
                VStack(spacing: 8) {
                    Text("導航進行中")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("請按照指示前進")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // 取消按鈕
                Button(action: onCancel) {
                    Text("取消導航")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(Color.red.opacity(0.3))
                        .cornerRadius(10)
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground).opacity(0.9))
            )
            .padding(40)
        }
    }
}

// MARK: - 保存成功覆蓋層
struct SaveSuccessOverlay: View {
    let message: String
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                
                Text(message)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(Color.green.opacity(0.9))
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            )
            .padding(.bottom, 50)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: message)
    }
}

// MARK: - 完整路線詳細視圖
struct RouteDetailsFullView: View {
    let route: TravelRoute
    @Environment(\.presentationMode) var presentationMode
    
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
                    
                    // 旅行提示
                    if let notes = route.notes {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("注意事項")
                                .font(.headline)
                                .foregroundColor(.hkBlue)
                                .padding(.horizontal)
                            
                            Text(notes)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .padding(.horizontal)
                        }
                    }
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
}

struct RouteStepDetailCard: View {
    let step: RouteStep
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: iconForTransport(step.transportMode))
                    .font(.title2)
                    .foregroundColor(colorForTransport(step.transportMode))
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(step.instruction)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let lineNumber = step.lineNumber {
                        Text(lineNumber)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(step.duration)分鐘")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.accentOrange)
                    
                    if let distance = step.distance {
                        Text("\(String(format: "%.1f", distance))公里")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Divider()
            
            HStack {
                if let platform = step.platform {
                    Label("月台 \(platform)", systemImage: "signpost.right")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                if let stopName = step.stopName {
                    Label(stopName, systemImage: "mappin.circle")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                Text(step.transportMode)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(colorForTransport(step.transportMode).opacity(0.1))
                    .foregroundColor(colorForTransport(step.transportMode))
                    .cornerRadius(6)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
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

#Preview {
    let travelDataManager = TravelDataManager.shared
    let routes = travelDataManager.getRoutes(
        from: travelDataManager.locations.first!,
        to: travelDataManager.locations.last!
    )
    
    return RouteResultsView(routes: routes)
}
