//
//  SharePopoverView.swift
//  EzTrash
//

import SwiftUI
import AppKit

struct SharePopoverView: View {
    let currentLanguage: AppLanguage
    let shareURL = "https://github.com/cin12211/EzTrash"
    @State private var isCopied = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(currentLanguage.localize("share_title"))
                .font(.headline)
            
            Text(currentLanguage.localize("share_desc"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack(spacing: 8) {
                Text(shareURL)
                    .font(.system(.body, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(4)
                    .textSelection(.enabled)
                
                Button(action: {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(shareURL, forType: .string)
                    
                    withAnimation {
                        isCopied = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            isCopied = false
                        }
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                        Text(isCopied ? currentLanguage.localize("copied") : currentLanguage.localize("copy"))
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(16)
        .frame(width: 380)
    }
}
