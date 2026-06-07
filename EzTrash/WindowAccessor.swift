//
//  WindowAccessor.swift
//  EzTrash
//

import SwiftUI
import AppKit

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
