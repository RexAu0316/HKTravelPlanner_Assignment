// TransportView.swift - 現代化設計版
import SwiftUI
import MapKit
import Combine

struct TransportView: View {
    @StateObject private var transportManager = TransportationManager.shared
    @State private var selectedRoute: TransportationRoute?
    @State private var showRouteDetails = false
    @State private var searchText = ""
    @State private var showingNearbyTransport = false
    @State private var selectedCategory = "全部"
    @State private var isSearching = false
    
    let categories = ["全部", "港鐵", "巴士", "小巴", "電車", "渡輪"]
    
    var filteredMTRStations: [MTRStation] {
        if searchText.isEmpty {
            return transportManager.mtrStations
        } else {
            return transportManager.mtrStations.filter { station in
                station.chineseName.localizedCaseInsensitiveContains(searchText) ||
                station.englishName.localizedCaseInsensitiveContains(searchText) ||
                station.stationCode.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var filteredBusRoutes: [BusRoute] {
        if searchText.isEmpty {
            return transportManager.busRoutes
        } else {
            return transportManager.busRoutes.filter { route in
                route.routeNumber.localizedCaseInsensitiveContains(searchText) ||
                route.chineseName.localizedCaseInsensitiveContains(searchText) ||
                route.englishName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category Picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(categories, id: \.self) { category in
                            CategoryChip(
                                title: category,
                                isSelected: selectedCategory == category,
                                action: {
                                    selectedCategory = category
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(Color(.systemBackground))
                
                // Search Bar
                ModernSearchField(
                    text: $searchText,
                    placeholder: "搜尋車站、路線或服務...",
                    isSearching: $isSearching
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                
                if !searchText.isEmpty && filteredMTRStations.isEmpty && filteredBusRoutes.isEmpty {
                    // Empty State
                    VStack(spacing: 20) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        VStack(spacing: 8) {
                            Text("未找到「\(searchText)」的結果")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("請嘗試其他搜索關鍵詞")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Quick Actions
                            quickActionsSection
                            
                            // Service Status
                            if !transportManager.serviceStatus.isEmpty {
                                serviceStatusSection
                            }
                            
                            // MTR Stations
                            if selectedCategory == "全部" || selectedCategory == "港鐵" {
                                if !filteredMTRStations.isEmpty {
                                    mtrStationsSection
                                }
                            }
                            
                            // Bus Routes
                            if selectedCategory == "全部" || selectedCategory == "巴士" {
                                if !filteredBusRoutes.isEmpty {
                                    busRoutesSection
                                }
                            }
                            
                            Spacer(minLength: 20)
                        }
                        .padding(.vertical, 16)
                    }
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("公共交通")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        transportManager.fetchMTRStations()
                        transportManager.fetchBusRoutes()
                        transportManager.fetchServiceStatus()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 18))
                            .foregroundColor(.hkBlue)
                    }
                }
            }
            .overlay {
                if transportManager.isLoading {
                    LoadingOverlay()
                }
            }
            .alert("錯誤", isPresented: .constant(transportManager.error != nil)) {
                Button("確定") {
                    transportManager.error = nil
                }
                Button("重試") {
                    transportManager.fetchMTRStations()
                    transportManager.fetchBusRoutes()
                }
            } message: {
                Text(transportManager.error?.localizedDescription ?? "")
            }
            .sheet(isPresented: $showingNearbyTransport) {
                ModernNearbyTransportView()
            }
        }
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("快速功能")
                .font(.headline)
                .foregroundColor(.hkBlue)
                .padding(.horizontal, 16)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                TransportQuickAction(
                    icon: "location.fill",
                    title: "附近交通",
                    color: .blue,
                    action: {
                        showingNearbyTransport = true
                    }
                )
                
                TransportQuickAction(
                    icon: "clock.fill",
                    title: "實時到站",
                    color: .green,
                    action: {
                        // Show real-time arrivals
                    }
                )
                
                TransportQuickAction(
                    icon: "exclamationmark.triangle.fill",
                    title: "服務狀態",
                    color: .orange,
                    action: {
                        transportManager.fetchServiceStatus()
                    }
                )
                
                TransportQuickAction(
                    icon: "map.fill",
                    title: "路線規劃",
                    color: .purple,
                    action: {
                        // Show route planner
                    }
                )
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Service Status Section
    private var serviceStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("服務狀態")
                    .font(.headline)
                    .foregroundColor(.hkBlue)
                
                Spacer()
                
                Button("查看全部") {
                    // Show all status
                }
                .font(.caption)
                .foregroundColor(.hkBlue)
            }
            .padding(.horizontal, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(transportManager.serviceStatus.prefix(3)) { status in
                        ServiceStatusCard(status: status)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    // MARK: - MTR Stations Section
    private var mtrStationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("港鐵車站")
                    .font(.headline)
                    .foregroundColor(.hkBlue)
                
                Spacer()
                
                NavigationLink("查看全部") {
                    ModernMTRStationListView(stations: filteredMTRStations)
                }
                .font(.caption)
                .foregroundColor(.hkBlue)
            }
            .padding(.horizontal, 16)
            
            VStack(spacing: 12) {
                ForEach(filteredMTRStations.prefix(5)) { station in
                    ModernMTRStationRow(station: station)
                        .padding(.horizontal, 16)
                }
            }
        }
    }
    
    // MARK: - Bus Routes Section
    private var busRoutesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("巴士路線")
                    .font(.headline)
                    .foregroundColor(.hkBlue)
                
                Spacer()
                
                NavigationLink("查看全部") {
                    ModernBusRouteListView(routes: filteredBusRoutes)
                }
                .font(.caption)
                .foregroundColor(.hkBlue)
            }
            .padding(.horizontal, 16)
            
            VStack(spacing: 12) {
                ForEach(filteredBusRoutes.prefix(5)) { route in
                    ModernBusRouteCard(route: route)
                        .padding(.horizontal, 16)
                }
            }
        }
    }
}

// MARK: - Components
struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.hkBlue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct ModernSearchField: View {
    @Binding var text: String
    let placeholder: String
    @Binding var isSearching: Bool
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .font(.system(size: 18))
            
            TextField(placeholder, text: $text)
                .focused($isFocused)
                .font(.system(size: 16))
                .submitLabel(.search)
                .onChange(of: isFocused) { focused in
                    isSearching = focused
                }
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 18))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct TransportQuickAction: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
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
    }
}

struct ServiceStatusCard: View {
    let status: ServiceStatus
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(statusColor(for: status.status))
                    .frame(width: 8, height: 8)
                
                Text(status.serviceType.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(status.status.rawValue)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(statusColor(for: status.status).opacity(0.2))
                    .foregroundColor(statusColor(for: status.status))
                    .cornerRadius(4)
            }
            
            Text(status.message)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            if !status.affectedLines.isEmpty {
                Text("受影響: \(status.affectedLines.joined(separator: ", "))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .frame(width: 280)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private func statusColor(for status: ServiceStatus.Status) -> Color {
        switch status {
        case .normal: return .green
        case .delay: return .orange
        case .suspended: return .red
        case .diverted: return .yellow
        case .special: return .blue
        }
    }
}

struct ModernMTRStationRow: View {
    let station: MTRStation
    
    var body: some View {
        NavigationLink(destination: ModernMTRStationDetailView(station: station)) {
            HStack(spacing: 16) {
                // Line Icon
                ZStack {
                    Circle()
                        .fill(lineColor(for: station.lineCode))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "train.side.front.car")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                
                // Station Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(station.chineseName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(station.englishName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 6) {
                        Text(station.lineName)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(lineColor(for: station.lineCode).opacity(0.1))
                            .foregroundColor(lineColor(for: station.lineCode))
                            .cornerRadius(4)
                        
                        Text(station.district)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Station Code
                Text(station.stationCode)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .cornerRadius(6)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func lineColor(for lineCode: String) -> Color {
        switch lineCode {
        case "IL": return .blue
        case "TWL": return .red
        case "EAL": return .green
        case "TKL": return .purple
        case "TML": return .brown
        default: return .gray
        }
    }
}

struct ModernBusRouteCard: View {
    let route: BusRoute
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                // Route Number
                Text(route.routeNumber)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(companyColor(for: route.company))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(route.chineseName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(route.englishName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Fare
                if let fare = route.fare {
                    Text("$\(fare, specifier: "%.1f")")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                }
            }
            
            // Route Info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                        Text(route.origin)
                            .font(.caption)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "flag.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.red)
                        Text(route.destination)
                            .font(.caption)
                    }
                }
                
                Spacer()
                
                // Company Tag
                Text(route.company.rawValue)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(companyColor(for: route.company).opacity(0.1))
                    .foregroundColor(companyColor(for: route.company))
                    .cornerRadius(6)
            }
            
            // Journey Time
            if let journeyTime = route.journeyTime {
                HStack {
                    Label("\(journeyTime)分鐘", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text(route.serviceType.rawValue)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        .onTapGesture {
            // Show route details
        }
    }
    
    private func companyColor(for company: BusRoute.BusCompany) -> Color {
        switch company {
        case .kmb: return .red
        case .ctb: return .yellow
        case .nwfb: return .green
        case .lwb: return .orange
        case .nlb: return .blue
        case .gmb: return .purple
        }
    }
}

// MARK: - List Views
struct ModernMTRStationListView: View {
    let stations: [MTRStation]
    @State private var selectedLine = "全部"
    
    var lines: [String] {
        let allLines = ["全部"] + Array(Set(stations.map { $0.lineName })).sorted()
        return allLines
    }
    
    var filteredStations: [MTRStation] {
        if selectedLine == "全部" {
            return stations
        } else {
            return stations.filter { $0.lineName == selectedLine }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Line Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(lines, id: \.self) { line in
                        LineFilterChip(
                            line: line,
                            isSelected: selectedLine == line,
                            action: {
                                selectedLine = line
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(.systemBackground))
            
            // Stations List
            List {
                ForEach(filteredStations) { station in
                    ModernMTRStationRow(station: station)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
            }
            .listStyle(PlainListStyle())
        }
        .navigationTitle("港鐵車站")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LineFilterChip: View {
    let line: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(line)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.hkBlue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct ModernBusRouteListView: View {
    let routes: [BusRoute]
    @State private var selectedCompany = "全部"
    
    var companies: [String] {
        let allCompanies = ["全部"] + Array(Set(routes.map { $0.company.rawValue })).sorted()
        return allCompanies
    }
    
    var filteredRoutes: [BusRoute] {
        if selectedCompany == "全部" {
            return routes
        } else {
            return routes.filter { $0.company.rawValue == selectedCompany }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Company Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(companies, id: \.self) { company in
                        CompanyFilterChip(
                            company: company,
                            isSelected: selectedCompany == company,
                            action: {
                                selectedCompany = company
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(.systemBackground))
            
            // Routes List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredRoutes) { route in
                        ModernBusRouteCard(route: route)
                            .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 16)
            }
            .background(Color(.systemGroupedBackground))
        }
        .navigationTitle("巴士路線")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CompanyFilterChip: View {
    let company: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(company)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.hkBlue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

// MARK: - Loading Overlay
struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                
                Text("加載中...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(Color.black.opacity(0.7))
            .cornerRadius(16)
        }
    }
}

// MARK: - Modern Nearby Transport View
struct ModernNearbyTransportView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var locationManager = LocationManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted {
                    // Location permission denied
                    VStack(spacing: 20) {
                        Image(systemName: "location.slash.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                        
                        VStack(spacing: 8) {
                            Text("位置權限被拒絕")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("請前往設定 > 隱私權 > 定位服務中啟用位置權限")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        Button("前往設定") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.hkBlue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding()
                } else {
                    // Show nearby transport
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // User Location
                            if let userLocation = locationManager.userLocation {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("當前位置")
                                        .font(.headline)
                                        .foregroundColor(.hkBlue)
                                    
                                    HStack {
                                        Image(systemName: "location.fill")
                                            .foregroundColor(.accentOrange)
                                        Text("緯度: \(String(format: "%.6f", userLocation.coordinate.latitude))")
                                            .font(.caption)
                                        Text("經度: \(String(format: "%.6f", userLocation.coordinate.longitude))")
                                            .font(.caption)
                                    }
                                    .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                                .padding(.horizontal)
                            }
                            
                            // Nearby Stations
                            VStack(alignment: .leading, spacing: 12) {
                                Text("附近交通設施")
                                    .font(.headline)
                                    .foregroundColor(.hkBlue)
                                    .padding(.horizontal)
                                
                                ForEach(0..<5) { index in
                                    NearbyTransportRow(index: index)
                                        .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("附近交通")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("完成") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct NearbyTransportRow: View {
    let index: Int
    
    let facilities = [
        ("中環站", "MTR", "0.3公里", "blue"),
        ("交易廣場巴士站", "巴士", "0.1公里", "green"),
        ("中環碼頭", "渡輪", "0.5公里", "purple"),
        ("德輔道中電車站", "電車", "0.2公里", "red"),
        ("畢打街的士站", "的士", "0.1公里", "yellow")
    ]
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(facilityColor(for: index))
                    .frame(width: 40, height: 40)
                
                Image(systemName: facilityIcon(for: index))
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(facilities[index].0)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(facilities[index].1)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(facilities[index].2)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("步行約5分鐘")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
    
    private func facilityColor(for index: Int) -> Color {
        switch facilities[index].3 {
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "red": return .red
        case "yellow": return .orange
        default: return .gray
        }
    }
    
    private func facilityIcon(for index: Int) -> String {
        switch facilities[index].1 {
        case "MTR": return "train.side.front.car"
        case "巴士": return "bus"
        case "渡輪": return "ferry"
        case "電車": return "tram"
        case "的士": return "car"
        default: return "mappin"
        }
    }
}

// MARK: - Modern MTR Station Detail View
struct ModernMTRStationDetailView: View {
    let station: MTRStation
    @StateObject private var transportManager = TransportationManager.shared
    @State private var arrivals: [RealTimeArrival] = []
    @State private var isLoadingArrivals = false
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Station Header
                stationHeader
                
                // Real-time Arrivals
                realTimeArrivalsSection
                
                // Station Facilities
                facilitiesSection
                
                // Nearby Exits
                exitsSection
            }
            .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(station.stationCode)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchArrivals()
        }
    }
    
    // MARK: - Station Header
    private var stationHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                ZStack {
                    Circle()
                        .fill(lineColor(for: station.lineCode))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "train.side.front.car")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(station.chineseName)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(station.englishName)
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 8)
            }
            
            HStack(spacing: 8) {
                Text(station.lineName)
                    .font(.headline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(lineColor(for: station.lineCode).opacity(0.1))
                    .foregroundColor(lineColor(for: station.lineCode))
                    .cornerRadius(8)
                
                Text(station.district)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    // MARK: - Real-time Arrivals Section
    private var realTimeArrivalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("實時到站時間")
                    .font(.headline)
                    .foregroundColor(.hkBlue)
                
                Spacer()
                
                Button(action: fetchArrivals) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 18))
                        .foregroundColor(.hkBlue)
                }
                .disabled(isLoadingArrivals)
            }
            
            if isLoadingArrivals {
                ProgressView("加載中...")
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if arrivals.isEmpty {
                emptyArrivalsState
            } else {
                arrivalsGrid
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    private var emptyArrivalsState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.badge.xmark")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("暫無到站信息")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    private var arrivalsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            ForEach(arrivals.prefix(6)) { arrival in
                ArrivalCard(arrival: arrival)
            }
        }
    }
    
    // MARK: - Facilities Section
    private var facilitiesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("車站設施")
                .font(.headline)
                .foregroundColor(.hkBlue)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    FacilityTag(icon: "wifi", label: "免費Wi-Fi")
                    FacilityTag(icon: "elevator", label: "升降機")
                    FacilityTag(icon: "escalator", label: "扶手電梯")
                    FacilityTag(icon: "parkingsign", label: "停車場")
                    FacilityTag(icon: "restroom", label: "洗手間")
                    FacilityTag(icon: "storefront", label: "商店")
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    // MARK: - Exits Section
    private var exitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("主要出口")
                .font(.headline)
                .foregroundColor(.hkBlue)
            
            VStack(spacing: 12) {
                ForEach(0..<3) { index in
                    ExitRow(index: index)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    // MARK: - Helper Functions
    private func fetchArrivals() {
        isLoadingArrivals = true
        arrivals = []
        
        transportManager.fetchMTRRealTimeArrival(stationCode: station.stationCode, lineCode: station.lineCode)
            .receive(on: DispatchQueue.main)
            .sink { _ in
                isLoadingArrivals = false
            } receiveValue: { arrivals in
                self.arrivals = arrivals
            }
            .store(in: &cancellables)
    }
    
    private func lineColor(for lineCode: String) -> Color {
        switch lineCode {
        case "IL": return .blue
        case "TWL": return .red
        case "EAL": return .green
        case "TKL": return .purple
        case "TML": return .brown
        default: return .gray
        }
    }
}

// MARK: - Arrival Card
struct ArrivalCard: View {
    let arrival: RealTimeArrival
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(arrival.destination)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Spacer()
                
                if arrival.delayInSeconds > 0 {
                    Text("+\(arrival.delayInSeconds)秒")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
            
            HStack {
                if let platform = arrival.platform {
                    Text("月台 \(platform)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(formatTime(arrival.estimatedArrivalTime))
                    .font(.headline)
                    .foregroundColor(arrival.isEstimated ? .orange : .hkBlue)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Facility Tag
struct FacilityTag: View {
    let icon: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.hkBlue)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.primary)
        }
        .frame(width: 70)
        .padding(.vertical, 8)
        .background(Color.hkBlue.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Exit Row
struct ExitRow: View {
    let index: Int
    
    let exits = [
        ("A出口", "通往交易廣場、中環中心"),
        ("B出口", "通往皇后大道中、置地廣場"),
        ("C出口", "通往德輔道中、香港站")
    ]
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.hkBlue.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Text(exits[index].0.prefix(1))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.hkBlue)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(exits[index].0)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(exits[index].1)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    TransportView()
}
