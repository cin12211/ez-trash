//
//  ContentView.swift
//  EzTrash
//
//  Created by Cinny on 7/6/26.
//

import SwiftUI
import LocalAuthentication

enum SortOption: String, CaseIterable {
    case name
    case lastOpened
}

struct ContentView: View {
    @StateObject private var scanner = AppScanner()
    @State private var searchText = ""
    @State private var selectedAppIDs = Set<URL>()
    @State private var deselectedURLs = Set<URL>()
    @State private var currentLanguage: AppLanguage = .english
    @State private var hasSetWindowSize = false
    @State private var sortBy: SortOption = .name
    
    // Deletion Sheet states
    @State private var showingDeleteSheet = false
    @State private var deletionPhase: DeletionPhase = .confirmation
    @State private var deleteProgress: Double = 0.0
    @State private var deleteStatusText: String = ""
    @State private var showingSharePopover = false
    
    // Auth-related states
    @State private var showingAuthError = false
    @State private var authErrorMessage = ""
    
    // Filtered and sorted apps based on search query and sort selection
    var filteredApps: [AppInfo] {
        let apps: [AppInfo]
        if searchText.isEmpty {
            apps = scanner.apps
        } else {
            apps = scanner.apps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        switch sortBy {
        case .name:
            return apps.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        case .lastOpened:
            return apps.sorted {
                let d1 = $0.lastOpenedDate ?? Date.distantPast
                let d2 = $1.lastOpenedDate ?? Date.distantPast
                if d1 == d2 {
                    return $0.name.localizedStandardCompare($1.name) == .orderedAscending
                }
                return d1 > d2 // Most recently opened first
            }
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
            VStack(spacing: 0) {
                // Custom Search & Filter Header
                HStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                            .font(.system(size: 13, weight: .medium))
                        
                        TextField(currentLanguage.localize("search_prompt"), text: $searchText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13))
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                    
                    // Order/Sort Menu Icon
                    Menu {
                        Picker(currentLanguage.localize("sort_label"), selection: $sortBy) {
                            Text(currentLanguage.localize("sort_by_name"))
                                .tag(SortOption.name)
                            
                            Text(currentLanguage.localize("sort_by_last_opened"))
                                .tag(SortOption.lastOpened)
                        }
                        .pickerStyle(.inline)
                    } label: {
                        Image(systemName: "arrow.up.and.down.text.horizontal")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .menuStyle(.borderlessButton)
                    .frame(width: 24)
                    .help(currentLanguage.localize("sort_help"))
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
                
                Divider()
                
                List(selection: $selectedAppIDs) {
                    let userApps = filteredApps.filter { !$0.isOwnedByRoot }
                    let systemApps = filteredApps.filter { $0.isOwnedByRoot }
                    
                    if !userApps.isEmpty {
                        Section(header: Text(currentLanguage.localize("user_apps_section"))) {
                            ForEach(userApps) { app in
                                SidebarAppRow(app: app, currentLanguage: currentLanguage)
                                    .tag(app.id)
                            }
                        }
                    }
                    
                    if !systemApps.isEmpty {
                        Section(header: Text(currentLanguage.localize("system_apps_section"))) {
                            ForEach(systemApps) { app in
                                SidebarAppRow(app: app, currentLanguage: currentLanguage)
                                    .tag(app.id)
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
            }
            .navigationTitle(currentLanguage.localize("sidebar_title"))
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
                    Button(action: {
                        if let url = URL(string: "https://buymeacoffee.com/taccin032") {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        Label("Coffee Me", systemImage: "cup.and.saucer.fill")
                    }
                    .controlSize(.regular)
                    .help(currentLanguage.localize("support_me_help"))
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        showingSharePopover = true
                    }) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .controlSize(.regular)
                    .help(currentLanguage.localize("share_help"))
                    .popover(isPresented: $showingSharePopover, arrowEdge: .bottom) {
                        SharePopoverView(currentLanguage: currentLanguage)
                    }
                }
                
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
            
            // Set window default size to 70% screen width and 70% screen height, and center it
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
                switch deletionPhase {
                case .confirmation:
                    DeletionConfirmationView(
                        selectedApps: selectedApps,
                        currentLanguage: currentLanguage,
                        onCancel: {
                            showingDeleteSheet = false
                        },
                        onDelete: {
                            authenticateAndStartDeletion()
                        }
                    )
                case .deleting:
                    DeletionProgressView(
                        deleteProgress: deleteProgress,
                        deleteStatusText: deleteStatusText
                    )
                case .completed:
                    DeletionCompletedView(
                        currentLanguage: currentLanguage,
                        onDone: {
                            // Instantly remove from UI first (avoid heavy re-scan)
                            let deletedIDs = selectedAppIDs
                            scanner.apps.removeAll(where: { deletedIDs.contains($0.id) })
                            
                            // Clear selections
                            selectedAppIDs.removeAll()
                            deselectedURLs.removeAll()
                            
                            // Dismiss sheet
                            showingDeleteSheet = false
                        }
                    )
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

#Preview {
    ContentView()
}
