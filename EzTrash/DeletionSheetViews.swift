//
//  DeletionSheetViews.swift
//  EzTrash
//

import SwiftUI

struct DeletionConfirmationView: View {
    let selectedApps: [AppInfo]
    let currentLanguage: AppLanguage
    var onCancel: () -> Void
    var onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(currentLanguage.localize("confirm_title"))
                .font(.headline)
            
            Text(currentLanguage.localize("confirm_desc"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
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
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)
                
                Button(currentLanguage.localize("auth_delete")) {
                    onDelete()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.top, 8)
        }
        .padding(20)
    }
}

struct DeletionProgressView: View {
    let deleteProgress: Double
    let deleteStatusText: String
    
    var body: some View {
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
    }
}

struct DeletionCompletedView: View {
    let currentLanguage: AppLanguage
    var onDone: () -> Void
    
    var body: some View {
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
                onDone()
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
        }
        .padding(32)
    }
}
