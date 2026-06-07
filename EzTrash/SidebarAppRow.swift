//
//  SidebarAppRow.swift
//  EzTrash
//

import SwiftUI

struct SidebarAppRow: View {
    let app: AppInfo
    let currentLanguage: AppLanguage
    
    var body: some View {
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
                Text("\(app.sizeString) - \(currentLanguage.localize("last_opened")): \(app.lastOpenedString(language: currentLanguage))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }
}
