//
//  CurrentlyRunningAppProcessApp.swift
//  CurrentlyRunningAppProcess
//
//  Created by Joel Brewster on 19/1/2025.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var iconWindow: NSWindow!
    var workspaceNotificationObserver: Any?
    var screenParametersObserver: Any?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Setup workspace notifications
        let workspace = NSWorkspace.shared
        workspaceNotificationObserver = workspace.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: nil) { [weak self] notification in
                self?.updateActiveAppIcon()
        }
        
        // Add screen observer
        screenParametersObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: nil) { [weak self] _ in
                self?.updateWindowPosition()
        }
        
        // Create floating window for icon
        iconWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 24, height: 24),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        iconWindow.level = .statusBar
        iconWindow.backgroundColor = .clear
        iconWindow.isOpaque = false
        iconWindow.hasShadow = false
        iconWindow.ignoresMouseEvents = true
        iconWindow.collectionBehavior = [.canJoinAllSpaces, .transient]
        
        updateWindowPosition()
        
        // Set initial icon
        updateActiveAppIcon()
    }
    
    func updateWindowPosition() {
        guard let screen = NSScreen.main else { return }
        let appleMenuBarHeight = screen.frame.height - screen.visibleFrame.height - (screen.visibleFrame.origin.y - screen.frame.origin.y) - 1
        
        let xPosition: CGFloat = 16 + screen.frame.minX
        let yPosition: CGFloat = screen.frame.minY + screen.frame.height - appleMenuBarHeight/2 - 12
        
        iconWindow.setFrameOrigin(NSPoint(x: xPosition, y: yPosition))
    }
    
    func updateActiveAppIcon() {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication,
              let appIcon = frontmostApp.icon else { return }
        
        let imageView = NSImageView(frame: NSRect(x: 0, y: 0, width: 22, height: 22))
        imageView.imageScaling = .scaleProportionallyDown
        imageView.wantsLayer = true
        
        // Add subtle shadow
        imageView.layer?.shadowColor = NSColor.black.withAlphaComponent(0.2).cgColor
        imageView.layer?.shadowOffset = NSSize(width: 0, height: 0)
        imageView.layer?.shadowOpacity = 1.0
        imageView.layer?.shadowRadius = 1.0
        
        // Apply grayscale filter with adaptive brightness
        if let cgImage = appIcon.cgImage(forProposedRect: nil, context: nil, hints: nil),
           let filter = CIFilter(name: "CIColorControls") {
            let ciImage = CIImage(cgImage: cgImage)
            filter.setValue(ciImage, forKey: kCIInputImageKey)
            filter.setValue(1, forKey: kCIInputSaturationKey) // Remove color
            
            // Adjust brightness and contrast based on appearance
            let isDarkMode = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            if isDarkMode {
                filter.setValue(1.4, forKey: kCIInputContrastKey)   // Increase contrast in dark mode
                filter.setValue(0.2, forKey: kCIInputBrightnessKey) // Lighter in dark mode
            } else {
                filter.setValue(1.2, forKey: kCIInputContrastKey)   // Keep original contrast in light mode
                filter.setValue(0.1, forKey: kCIInputBrightnessKey) // Very slightly darker in light mode
            }
            
            if let outputImage = filter.outputImage {
                let context = CIContext()
                if let resultCGImage = context.createCGImage(outputImage, from: outputImage.extent) {
                    imageView.image = NSImage(cgImage: resultCGImage, size: appIcon.size)
                } else {
                    imageView.image = appIcon // Fallback to original if conversion fails
                }
            } else {
                imageView.image = appIcon // Fallback to original if filter fails
            }
        } else {
            imageView.image = appIcon // Fallback to original if conversion fails
        }
        
        iconWindow.contentView = imageView
        iconWindow.orderFront(nil)
    }
}

@main
struct CurrentlyRunningAppProcessApp {
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory) // This hides the Dock icon
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}

