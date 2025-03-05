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
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else { return }
        
        // Create container view with white background - centered in the 24x24 window
        let containerView = NSView(frame: NSRect(x: 2.5, y: 2.5, width: 19, height: 19)) // Centered in 24x24 window
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = NSColor.white.cgColor
        containerView.layer?.cornerRadius = 4.5
        containerView.layer?.shadowColor = NSColor.black.withAlphaComponent(0.25).cgColor
        containerView.layer?.shadowOffset = NSSize(width: 0, height: -0.5)
        containerView.layer?.shadowOpacity = 1.0
        containerView.layer?.shadowRadius = 0.5
        
        let imageView = NSImageView(frame: NSRect(x: 2.5, y: 2.5, width: 14, height: 14))
        imageView.imageScaling = .scaleProportionallyDown
        imageView.wantsLayer = true
        
        // Try loading SVG icon
        if let bundlePath = Bundle.main.resourcePath {
            let appName = frontmostApp.localizedName?.lowercased() ?? ""
            let iconName = ":\(appName):.svg"
            let svgPath = (bundlePath as NSString).appendingPathComponent(iconName)
            
            if let svgImage = NSImage(contentsOfFile: svgPath) {
                imageView.image = svgImage
                containerView.addSubview(imageView)
                
                // Create a wrapper view to center the container
                let wrapperView = NSView(frame: NSRect(x: 0, y: 0, width: 24, height: 24))
                wrapperView.addSubview(containerView)
                iconWindow.contentView = wrapperView
                iconWindow.orderFront(nil)
                return
            }
        }
        
        // For system icons, use the full window size
        imageView.frame = NSRect(x: 1, y: 1, width: 22, height: 22) // Slightly inset
        
        // Only if SVG not found, use system icon with effects
        if let appIcon = frontmostApp.icon,
           let cgImage = appIcon.cgImage(forProposedRect: nil, context: nil, hints: nil),
           let filter = CIFilter(name: "CIColorControls") {
            let ciImage = CIImage(cgImage: cgImage)
            filter.setValue(ciImage, forKey: kCIInputImageKey)
            filter.setValue(1, forKey: kCIInputSaturationKey)
            
            let isDarkMode = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            if isDarkMode {
                filter.setValue(1.4, forKey: kCIInputContrastKey)
                filter.setValue(0.2, forKey: kCIInputBrightnessKey)
            } else {
                filter.setValue(1.2, forKey: kCIInputContrastKey)
                filter.setValue(0.1, forKey: kCIInputBrightnessKey)
            }
            
            if let outputImage = filter.outputImage {
                let context = CIContext()
                if let resultCGImage = context.createCGImage(outputImage, from: outputImage.extent) {
                    imageView.frame = NSRect(x: 0, y: 0, width: 22, height: 22) // Full size for system icons
                    imageView.image = NSImage(cgImage: resultCGImage, size: appIcon.size)
                } else {
                    imageView.image = appIcon
                }
            } else {
                imageView.image = appIcon
            }
        } else {
            imageView.image = frontmostApp.icon
        }
        
        // Create wrapper for system icon too
        let wrapperView = NSView(frame: NSRect(x: 0, y: 0, width: 24, height: 24))
        wrapperView.addSubview(imageView)
        iconWindow.contentView = wrapperView
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
