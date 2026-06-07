//
//  ContentView.swift
//  EzTrash
//
//  Created by Cinny on 7/6/26.
//

import SwiftUI
import LocalAuthentication

enum DeletionPhase {
    case confirmation
    case deleting
    case completed
}

enum AppLanguage: String, CaseIterable {
    case english = "en"
    case vietnamese = "vi"
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .vietnamese: return "Tiếng Việt"
        }
    }
    
    var shortName: String {
        switch self {
        case .english: return "EN"
        case .vietnamese: return "VI"
        }
    }
    
    func localize(_ key: String, arg: String = "") -> String {
        switch self {
        case .english:
            switch key {
            case "search_prompt": return "Search apps..."
            case "scanning": return "Scanning Applications folder..."
            case "no_apps": return "No applications found"
            case "apps_found": return "apps found"
            case "refresh_help": return "Refresh list of applications"
            case "sidebar_title": return "Applications"
            case "empty_title": return "No Application Selected"
            case "empty_desc": return "Select one or more applications from the sidebar to scan for associated files and uninstall."
            case "apps_selected": return "\(arg) Applications Selected"
            case "app_bundle": return "Application Bundle"
            case "associated_files": return "Associated Files & Folders (\(arg))"
            case "no_associated": return "No associated files found"
            case "total_selected": return "Total selected to delete:"
            case "move_to_trash_single": return "Move to Trash"
            case "move_to_trash_multi": return "Move \(arg) Apps to Trash"
            case "auth_failed": return "Authentication Failed"
            case "confirm_title": return "Confirm Uninstallation"
            case "confirm_desc": return "Are you sure you want to move the selected applications and their associated files to the Trash?"
            case "cancel": return "Cancel"
            case "auth_delete": return "Delete"
            case "init_uninstall": return "Initializing uninstallation..."
            case "trashing": return "Trashing: \(arg)"
            case "moved_to_trash": return "Moved to Trash"
            case "moved_to_trash_desc": return "Successfully cleaned and moved selected applications and their associated files to the Trash."
            case "done": return "Done"
            case "auth_reason": return "Confirm trashing of \(arg) and associated files."
            case "system_app_warning": return "System/App Store apps cannot be deleted"
            case "user_apps_section": return "User Applications"
            case "system_apps_section": return "System / App Store"
            default: return key
            }
        case .vietnamese:
            switch key {
            case "search_prompt": return "Tìm ứng dụng..."
            case "scanning": return "Đang quét thư mục Ứng dụng..."
            case "no_apps": return "Không tìm thấy ứng dụng"
            case "apps_found": return "ứng dụng được tìm thấy"
            case "refresh_help": return "Làm mới danh sách ứng dụng"
            case "sidebar_title": return "Ứng dụng"
            case "empty_title": return "Chưa chọn ứng dụng"
            case "empty_desc": return "Chọn một hoặc nhiều ứng dụng từ thanh bên để quét các tệp liên quan và gỡ cài đặt."
            case "apps_selected": return "Đã chọn \(arg) ứng dụng"
            case "app_bundle": return "Bộ cài ứng dụng"
            case "associated_files": return "Tệp & Thư mục liên quan (\(arg))"
            case "no_associated": return "Không tìm thấy tệp liên quan"
            case "total_selected": return "Tổng dung lượng cần xoá:"
            case "move_to_trash_single": return "Di chuyển vào Thùng rác"
            case "move_to_trash_multi": return "Di chuyển \(arg) ứng dụng vào Thùng rác"
            case "auth_failed": return "Xác thực thất bại"
            case "confirm_title": return "Xác nhận gỡ cài đặt"
            case "confirm_desc": return "Bạn có chắc chắn muốn di chuyển các ứng dụng đã chọn và tệp liên quan vào Thùng rác?"
            case "cancel": return "Huỷ"
            case "auth_delete": return "Xoá"
            case "init_uninstall": return "Bắt đầu gỡ cài đặt..."
            case "trashing": return "Đang xoá: \(arg)"
            case "moved_to_trash": return "Đã di chuyển vào Thùng rác"
            case "moved_to_trash_desc": return "Đã dọn dẹp và di chuyển các ứng dụng cùng file liên quan vào Thùng rác thành công."
            case "done": return "Hoàn tất"
            case "auth_reason": return "Xác nhận di chuyển \(arg) và các tệp liên quan vào Thùng rác."
            case "system_app_warning": return "Không thể gỡ ứng dụng hệ thống / App Store"
            case "user_apps_section": return "Ứng dụng Người dùng"
            case "system_apps_section": return "Hệ thống / App Store"
            default: return key
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var scanner = AppScanner()
    @State private var searchText = ""
    @State private var selectedAppIDs = Set<URL>()
    @State private var deselectedURLs = Set<URL>()
    @State private var currentLanguage: AppLanguage = .english
    @State private var hasSetWindowSize = false
    
    // Deletion Sheet states
    @State private var showingDeleteSheet = false
    @State private var deletionPhase: DeletionPhase = .confirmation
    @State private var deleteProgress: Double = 0.0
    @State private var deleteStatusText: String = ""
    
    // Auth-related states
    @State private var showingAuthError = false
    @State private var authErrorMessage = ""
    
    // Filtered apps based on search query
    var filteredApps: [AppInfo] {
        if searchText.isEmpty {
            return scanner.apps
        } else {
            return scanner.apps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    // Computed list of selected apps
    var selectedApps: [AppInfo] {
        scanner.apps.filter { selectedAppIDs.contains($0.id) }
    }
    
    // Computed total size of files to be deleted
    var totalBytesToDelete: Int64 {
        var total: Int64 = 0
        for app in selectedApps {
            total += app.size ?? 0
            for file in app.relatedFiles {
                if !deselectedURLs.contains(file.id) {
                    total += file.size
                }
            }
        }
        return total
    }
    
    var totalSizeString: String {
        ByteCountFormatter.string(fromByteCount: totalBytesToDelete, countStyle: .file)
    }
    
    var hasRootOwnedSelection: Bool {
        selectedApps.contains(where: { $0.isOwnedByRoot })
    }
    
    var body: some View {
        NavigationSplitView {
            // Left Column: App List (Sidebar)
            List(selection: $selectedAppIDs) {
                let userApps = filteredApps.filter { !$0.isOwnedByRoot }
                let systemApps = filteredApps.filter { $0.isOwnedByRoot }
                
                if !userApps.isEmpty {
                    Section(header: Text(currentLanguage.localize("user_apps_section"))) {
                        ForEach(userApps) { app in
                            HStack(spacing: 8) {
                                Image(nsImage: app.icon)
                                    .resizable()
                                    .frame(width: 32, height: 32)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 4) {
                                        Text(app.name)
                                            .font(.body)
                                        if app.isOwnedByRoot {
                                            Image(systemName: "lock.fill")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    Text(app.sizeString)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .tag(app.id)
                        }
                    }
                }
                
                if !systemApps.isEmpty {
                    Section(header: Text(currentLanguage.localize("system_apps_section"))) {
                        ForEach(systemApps) { app in
                            HStack(spacing: 8) {
                                Image(nsImage: app.icon)
                                    .resizable()
                                    .frame(width: 32, height: 32)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 4) {
                                        Text(app.name)
                                            .font(.body)
                                        if app.isOwnedByRoot {
                                            Image(systemName: "lock.fill")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    Text(app.sizeString)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .tag(app.id)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle(currentLanguage.localize("sidebar_title"))
            .searchable(text: $searchText, placement: .sidebar, prompt: currentLanguage.localize("search_prompt"))
        } detail: {
            // Right Column: App Detail & Leftovers
            Group {
                if selectedApps.isEmpty {
                    // Native macOS empty state
                    ContentUnavailableView {
                        Label(currentLanguage.localize("empty_title"), systemImage: "trash")
                    } description: {
                        Text(currentLanguage.localize("empty_desc"))
                    }
                } else {
                    VStack(spacing: 0) {
                        // Header Section (Native styling)
                        HStack(alignment: .center, spacing: 16) {
                            if selectedApps.count == 1 {
                                let app = selectedApps[0]
                                Image(nsImage: app.icon)
                                    .resizable()
                                    .frame(width: 64, height: 64)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(alignment: .center, spacing: 6) {
                                        Text(app.name)
                                            .font(.title)
                                            .fontWeight(.bold)
                                        if app.isOwnedByRoot {
                                            Image(systemName: "lock.fill")
                                                .font(.title3)
                                                .foregroundColor(.secondary)
                                                .help(currentLanguage.localize("system_app_warning"))
                                        }
                                    }
                                    
                                    if let bundleID = app.bundleIdentifier {
                                        Text(bundleID)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            } else {
                                Image(systemName: "square.grid.3x3.square")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                                    .frame(width: 64, height: 64)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(currentLanguage.localize("apps_selected", arg: "\(selectedApps.count)"))
                                        .font(.title)
                                        .fontWeight(.bold)
                                    
                                    Text(selectedApps.map { $0.name }.joined(separator: ", "))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color(NSColor.windowBackgroundColor))
                        
                        Divider()
                        
                        // Native macOS grouped details list
                        List {
                            ForEach(selectedApps) { app in
                                Section(header: HStack {
                                    Image(nsImage: app.icon)
                                        .resizable()
                                        .frame(width: 16, height: 16)
                                    Text(app.name)
                                        .font(.headline)
                                    Spacer()
                                    Text(app.sizeString)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }) {
                                    // The main application itself
                                    HStack {
                                        Toggle("", isOn: .constant(true))
                                            .toggleStyle(.checkbox)
                                            .disabled(true)
                                        
                                        Image(systemName: "app")
                                            .foregroundColor(.secondary)
                                        
                                        Text(currentLanguage.localize("app_bundle"))
                                        
                                        Spacer()
                                        
                                        Text(app.id.path)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                            .truncationMode(.middle)
                                    }
                                    
                                    // Leftover files
                                    ForEach(app.relatedFiles) { file in
                                        let isSelected = !deselectedURLs.contains(file.id)
                                        HStack {
                                            Toggle("", isOn: Binding(
                                                get: { isSelected },
                                                set: { checked in
                                                    if checked {
                                                        deselectedURLs.remove(file.id)
                                                    } else {
                                                        deselectedURLs.insert(file.id)
                                                    }
                                                }
                                            ))
                                            .toggleStyle(.checkbox)
                                            
                                            Image(systemName: file.id.pathExtension.isEmpty ? "folder" : "doc")
                                                .foregroundColor(.secondary)
                                            
                                            Text(file.name)
                                                .lineLimit(1)
                                            
                                            Spacer()
                                            
                                            Text(file.relativePath)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                                .truncationMode(.middle)
                                                .padding(.horizontal, 8)
                                            
                                            Text(file.sizeString)
                                                .foregroundColor(.secondary)
                                                .frame(minWidth: 60, alignment: .trailing)
                                        }
                                    }
                                }
                            }
                        }
                        .listStyle(.inset)
                        
                        Divider()
                        
                        // Bottom status & Action bar (Native macOS style)
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(currentLanguage.localize("total_selected"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(totalSizeString)
                                    .font(.headline)
                            }
                            
                            Spacer()
                            
                            if hasRootOwnedSelection {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    Text(currentLanguage.localize("system_app_warning"))
                                        .font(.callout)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.trailing, 8)
                            }
                            
                            Button(role: .destructive, action: {
                                deletionPhase = .confirmation
                                showingDeleteSheet = true
                            }) {
                                Text(selectedApps.count == 1 ? currentLanguage.localize("move_to_trash_single") : currentLanguage.localize("move_to_trash_multi", arg: "\(selectedApps.count)"))
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .disabled(hasRootOwnedSelection)
                        }
                        .padding()
                        .background(Color(NSColor.windowBackgroundColor))
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Picker("", selection: $currentLanguage) {
                        ForEach(AppLanguage.allCases, id: \.self) { lang in
                            Text(lang.shortName).tag(lang)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 72)
                    .controlSize(.regular)
                    .help("Change language / Thay đổi ngôn ngữ")
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { scanner.scanApps() }) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .controlSize(.regular)
                    .help(currentLanguage.localize("refresh_help"))
                }
            }
        }
        .background(WindowAccessor { window in
            guard !hasSetWindowSize else { return }
            hasSetWindowSize = true
            
            // Set window default size to 70% screen width and 60% screen height, and center it
            if let screen = window.screen ?? NSScreen.main {
                let screenFrame = screen.visibleFrame // Accounts for Dock and Menu Bar
                let targetWidth = screenFrame.width * 0.70
                let targetHeight = screenFrame.height * 0.70
                
                let targetX = screenFrame.minX + (screenFrame.width - targetWidth) / 2
                let targetY = screenFrame.minY + (screenFrame.height - targetHeight) / 2
                
                let targetRect = NSRect(x: targetX, y: targetY, width: targetWidth, height: targetHeight)
                window.setFrame(targetRect, display: true, animate: false)
            }
        })
        .onAppear {
            scanner.scanApps()
        }
        // Authentication failure alert
        .alert(currentLanguage.localize("auth_failed"), isPresented: $showingAuthError) {
            Button(currentLanguage.localize("done"), role: .cancel) { }
        } message: {
            Text(authErrorMessage)
        }
        // Unified Deletion Status Sheet
        .sheet(isPresented: $showingDeleteSheet) {
            VStack(spacing: 20) {
                if deletionPhase == .confirmation {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(currentLanguage.localize("confirm_title"))
                            .font(.headline)
                        
                        Text(currentLanguage.localize("confirm_desc"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // Left-aligned list of applications to delete
                        ScrollView {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(selectedApps) { app in
                                    HStack(spacing: 8) {
                                        Image(nsImage: app.icon)
                                            .resizable()
                                            .frame(width: 20, height: 20)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(app.name)
                                                .font(.body)
                                                .fontWeight(.medium)
                                            Text(app.id.path)
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                                .truncationMode(.middle)
                                        }
                                        Spacer()
                                    }
                                }
                            }
                            .padding(8)
                        }
                        .frame(maxHeight: 120)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(6)
                        
                        HStack {
                            Spacer()
                            Button(currentLanguage.localize("cancel")) {
                                showingDeleteSheet = false
                            }
                            .keyboardShortcut(.cancelAction)
                            
                            // Uses native primary button style (Accent Color) with shorter label
                            Button(currentLanguage.localize("auth_delete")) {
                                authenticateAndStartDeletion()
                            }
                            .buttonStyle(.borderedProminent)
                            .keyboardShortcut(.defaultAction)
                        }
                        .padding(.top, 8)
                    }
                    .padding(20)
                } else if deletionPhase == .deleting {
                    VStack(spacing: 16) {
                        ProgressView(value: deleteProgress, total: 1.0)
                            .progressViewStyle(.linear)
                            .frame(width: 300)
                        
                        Text("\(Int(deleteProgress * 100))%")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text(deleteStatusText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .frame(width: 320)
                    }
                    .padding(32)
                } else if deletionPhase == .completed {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .frame(width: 48, height: 48)
                            .foregroundColor(.green)
                        
                        Text(currentLanguage.localize("moved_to_trash"))
                            .font(.headline)
                        
                        Text(currentLanguage.localize("moved_to_trash_desc"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button(currentLanguage.localize("done")) {
                            // Instantly remove from UI first (avoid heavy re-scan)
                            let deletedIDs = selectedAppIDs
                            scanner.apps.removeAll(where: { deletedIDs.contains($0.id) })
                            
                            // Clear selections
                            selectedAppIDs.removeAll()
                            deselectedURLs.removeAll()
                            
                            // Dismiss sheet
                            showingDeleteSheet = false
                        }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.defaultAction)
                    }
                    .padding(32)
                }
            }
            .frame(width: 420)
        }
    }
    
    // Core LocalAuthentication logic
    private func authenticateAndStartDeletion() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let appNames = selectedApps.map { $0.name }.joined(separator: ", ")
            let reason = currentLanguage.localize("auth_reason", arg: appNames)
            
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authError in
                DispatchQueue.main.async {
                    if success {
                        // Progress to deleting state
                        self.deletionPhase = .deleting
                        self.deleteProgress = 0.0
                        self.deleteStatusText = currentLanguage.localize("init_uninstall")
                        
                        self.performDeletionStepByStep()
                    } else {
                        if let authError = authError as? LAError, authError.code != .userCancel {
                            self.authErrorMessage = authError.localizedDescription
                            self.showingAuthError = true
                            self.showingDeleteSheet = false
                        }
                    }
                }
            }
        } else {
            // Fallback if no local password configured
            self.deletionPhase = .deleting
            self.performDeletionStepByStep()
        }
    }
    
    // Sequential deletion with real-time UI progress reporting
    private func performDeletionStepByStep() {
        var urlsToRecycle: [URL] = []
        
        for app in selectedApps {
            // Add app bundle itself
            urlsToRecycle.append(app.id)
            
            // Add checked related files
            for file in app.relatedFiles {
                if !deselectedURLs.contains(file.id) {
                    urlsToRecycle.append(file.id)
                }
            }
        }
        
        // Terminate running apps
        for app in selectedApps {
            let runningApps = NSWorkspace.shared.runningApplications
            for runningApp in runningApps {
                if runningApp.bundleIdentifier == app.bundleIdentifier || runningApp.bundleIdentifier == app.id.lastPathComponent {
                    runningApp.forceTerminate()
                }
            }
        }
        
        let totalFiles = urlsToRecycle.count
        guard totalFiles > 0 else {
            self.deletionPhase = .completed
            return
        }
        
        var currentIndex = 0
        
        func deleteNext() {
            guard currentIndex < totalFiles else {
                DispatchQueue.main.async {
                    self.deleteProgress = 1.0
                    self.deletionPhase = .completed
                }
                return
            }
            
            let url = urlsToRecycle[currentIndex]
            let filename = url.lastPathComponent
            let progress = Double(currentIndex) / Double(totalFiles)
            
            DispatchQueue.main.async {
                self.deleteProgress = progress
                self.deleteStatusText = currentLanguage.localize("trashing", arg: filename)
            }
            
            // Artificial delay (150ms) to ensure smooth progress animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                NSWorkspace.shared.recycle([url]) { (newURLs, error) in
                    if let error = error {
                        print("Recycle failed for \(url.path): \(error.localizedDescription)")
                    }
                    currentIndex += 1
                    deleteNext()
                }
            }
        }
        
        // Start sequential deletion
        DispatchQueue.global(qos: .userInitiated).async {
            deleteNext()
        }
    }
}

// NSViewRepresentable helper to access and customize the hosting NSWindow
struct WindowAccessor: NSViewRepresentable {
    var onChange: (NSWindow) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                onChange(window)
            }
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let window = nsView.window {
                onChange(window)
            }
        }
    }
}

#Preview {
    ContentView()
}
