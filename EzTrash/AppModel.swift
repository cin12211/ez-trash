//
//  AppModel.swift
//  EzTrash
//
//  Created by Cinny on 7/6/26.
//

import Foundation
import Cocoa
import Combine

struct RelatedFile: Identifiable, Hashable, Equatable {
    let id: URL
    let name: String
    let relativePath: String
    let size: Int64
    var isSelected: Bool = true
    
    var sizeString: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

struct AppInfo: Identifiable, Hashable, Equatable {
    let id: URL // The file URL of the .app
    let name: String
    let bundleIdentifier: String?
    let icon: NSImage
    var size: Int64?
    var relatedFiles: [RelatedFile] = []
    var isOwnedByRoot: Bool = false
    
    var sizeString: String {
        if let size = size {
            return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
        }
        return "Calculating..."
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: AppInfo, rhs: AppInfo) -> Bool {
        return lhs.id == rhs.id
    }
}

class AppScanner: ObservableObject {
    @Published var apps: [AppInfo] = []
    @Published var isScanning = false
    @Published var scanProgress: Double = 0.0
    
    private var libraryContentsCache: [URL] = []
    private var cancellables = Set<AnyCancellable>()
    private let fileManager = FileManager.default
    
    /// Scans the /Applications folder and loads apps
    func scanApps() {
        isScanning = true
        scanProgress = 0.0
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Pre-scan all library directories ONCE to build cache.
            // This prevents macOS from prompting TCC permissions multiple times.
            self.preScanLibraryDirectories()
            
            let appsDir = URL(fileURLWithPath: "/Applications")
            guard let appURLs = try? self.fileManager.contentsOfDirectory(at: appsDir, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsSubdirectoryDescendants]) else {
                DispatchQueue.main.async {
                    self.isScanning = false
                }
                return
            }
            
            // Filter only .app bundles
            let appBundles = appURLs.filter { $0.pathExtension.lowercased() == "app" }
            let totalApps = appBundles.count
            
            var scannedApps: [AppInfo] = []
            
            for (index, appURL) in appBundles.enumerated() {
                let name = appURL.deletingPathExtension().lastPathComponent
                
                // Get Bundle ID
                let plistURL = appURL.appendingPathComponent("Contents/Info.plist")
                var bundleID: String? = nil
                if let plistData = try? Data(contentsOf: plistURL),
                   let plist = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any] {
                    bundleID = plist["CFBundleIdentifier"] as? String
                }
                
                // Get Icon
                let icon = NSWorkspace.shared.icon(forFile: appURL.path)
                
                // Determine if owned by root
                var isOwnedByRoot = false
                if let attributes = try? self.fileManager.attributesOfItem(atPath: appURL.path) {
                    if let ownerID = attributes[.ownerAccountID] as? NSNumber {
                        isOwnedByRoot = (ownerID.intValue == 0)
                    } else if let ownerName = attributes[.ownerAccountName] as? String {
                        isOwnedByRoot = (ownerName == "root")
                    }
                }
                
                let app = AppInfo(id: appURL, name: name, bundleIdentifier: bundleID, icon: icon, size: nil, relatedFiles: [], isOwnedByRoot: isOwnedByRoot)
                scannedApps.append(app)
                
                let progress = Double(index + 1) / Double(totalApps)
                DispatchQueue.main.async {
                    self.scanProgress = progress
                }
            }
            
            // Sort by name
            scannedApps.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            
            DispatchQueue.main.async {
                self.apps = scannedApps
                self.isScanning = false
                
                // Asynchronously load sizes and related files for each app using cache
                self.loadDetailsForAllApps()
            }
        }
    }
    
    /// Pre-scans the 9 Library directories once in a single sequential sweep to trigger TCC permission prompt only once.
    /// Filters out Apple system directories (like AddressBook, Calendars, Mail) to prevent triggering Contacts / Calendar privacy prompts.
    private func preScanLibraryDirectories() {
        var allURLs: [URL] = []
        let libraryPaths = [
            "~/Library/Application Support",
            "~/Library/Caches",
            "~/Library/Preferences",
            "~/Library/Logs",
            "~/Library/LaunchAgents",
            "~/Library/Saved Application State",
            "~/Library/HTTPStorages",
            "~/Library/Containers",
            "~/Library/Group Containers"
        ]
        
        for pathPattern in libraryPaths {
            let expandedPath = NSString(string: pathPattern).expandingTildeInPath
            let dirURL = URL(fileURLWithPath: expandedPath)
            
            if let contents = try? fileManager.contentsOfDirectory(at: dirURL, includingPropertiesForKeys: nil, options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles]) {
                for itemURL in contents {
                    let itemName = itemURL.lastPathComponent.lowercased()
                    
                    // Exclude Apple system folders/databases to prevent Contacts, Calendars, Mail, Safari TCC privacy prompts
                    if itemName.hasPrefix("com.apple") ||
                       itemName == "addressbook" ||
                       itemName == "calendar" ||
                       itemName == "messages" ||
                       itemName == "mail" ||
                       itemName == "safari" ||
                       itemName == "callhistory" {
                        continue
                    }
                    
                    allURLs.append(itemURL)
                }
            }
        }
        self.libraryContentsCache = allURLs
    }
    
    /// Asynchronously calculates sizes and searches for leftover files
    private func loadDetailsForAllApps() {
        for app in apps {
            calculateSizeAndFindRelatedFiles(for: app)
        }
    }
    
    func calculateSizeAndFindRelatedFiles(for app: AppInfo) {
        let appURL = app.id
        let appName = app.name
        let bundleID = app.bundleIdentifier
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            
            // 1. Calculate main app size
            let appSize = self.getFolderSize(at: appURL)
            
            // 2. Find related files (using cached library contents, no disk I/O)
            let relatedURLs = self.scanForRelatedFiles(appName: appName, bundleID: bundleID)
            
            var relatedFiles: [RelatedFile] = []
            let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
            
            for url in relatedURLs {
                let size = self.getFolderSize(at: url)
                var relativePath = url.path
                if relativePath.hasPrefix(homeDir) {
                    relativePath = "~" + relativePath.dropFirst(homeDir.count)
                }
                
                let relFile = RelatedFile(
                    id: url,
                    name: url.lastPathComponent,
                    relativePath: relativePath,
                    size: size,
                    isSelected: true
                )
                relatedFiles.append(relFile)
            }
            
            // Sort related files by size descending
            relatedFiles.sort { $0.size > $1.size }
            
            DispatchQueue.main.async {
                if let index = self.apps.firstIndex(where: { $0.id == app.id }) {
                    self.apps[index].size = appSize
                    self.apps[index].relatedFiles = relatedFiles
                }
            }
        }
    }
    
    /// Helper to recursively calculate folder size
    private func getFolderSize(at url: URL) -> Int64 {
        var isDir: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDir) else { return 0 }
        
        if !isDir.boolValue {
            let attrs = try? fileManager.attributesOfItem(atPath: url.path)
            return attrs?[.size] as? Int64 ?? 0
        }
        
        var totalSize: Int64 = 0
        let resourceKeys: [URLResourceKey] = [.isRegularFileKey, .fileSizeKey]
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: resourceKeys, options: [.skipsHiddenFiles], errorHandler: nil) else {
            return 0
        }
        
        for case let fileURL as URL in enumerator {
            if let resourceValues = try? fileURL.resourceValues(forKeys: Set(resourceKeys)),
               resourceValues.isRegularFile == true {
                totalSize += Int64(resourceValues.fileSize ?? 0)
            }
        }
        
        return totalSize
    }
    
    /// Helper to search associated files by matching pre-scanned cache
    private func scanForRelatedFiles(appName: String, bundleID: String?) -> [URL] {
        var results: [URL] = []
        var searchStrings = [appName.lowercased()]
        if let bid = bundleID?.lowercased() {
            searchStrings.append(bid)
            
            let parts = bid.components(separatedBy: ".")
            for part in parts {
                if part.count > 3 && part != "com" && part != "app" && part != "desktop" {
                    searchStrings.append(part)
                }
            }
        }
        
        for itemURL in libraryContentsCache {
            let itemName = itemURL.lastPathComponent.lowercased()
            for searchStr in searchStrings {
                if itemName.contains(searchStr) {
                    results.append(itemURL)
                    break
                }
            }
        }
        
        return results
    }
    
    /// Recycles (moves to trash) a list of URLs
    func recycleFiles(urls: [URL], completion: @escaping (Bool, Error?) -> Void) {
        DispatchQueue.main.async {
            NSWorkspace.shared.recycle(urls) { (newURLs, error) in
                if let error = error {
                    completion(false, error)
                } else {
                    completion(true, nil)
                }
            }
        }
    }
}
