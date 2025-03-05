//
//  CurrentlyRunningAppProcessApp.swift
//  CurrentlyRunningAppProcess
//
//  Created by Joel Brewster on 19/1/2025.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var iconWindow: NSWindow!
    var workspaceNotificationObserver: Any?
    var screenParametersObserver: Any?
    
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
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
        
        // Create default white container view
        let containerView = NSView(frame: NSRect(x: 2.5, y: 2.5, width: 19, height: 19))
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
        
        // Try loading SVG icon first
        if let bundlePath = Bundle.main.resourcePath {
            let appName = frontmostApp.localizedName?.lowercased() ?? ""
            let iconName = ":\(appName):.svg"
            let svgPath = (bundlePath as NSString).appendingPathComponent(iconName)
            let fallbackPath = (bundlePath as NSString).appendingPathComponent("add.svg")
            
            // If app-specific SVG exists, use it, otherwise use fallback
            if FileManager.default.fileExists(atPath: svgPath) {
                imageView.image = NSImage(contentsOfFile: svgPath)
            } else {
                // Always use fallback icon if no app-specific icon exists
                imageView.image = NSImage(contentsOfFile: fallbackPath)
            }
            
            containerView.addSubview(imageView)
            let wrapperView = NSView(frame: NSRect(x: 0, y: 0, width: 24, height: 24))
            wrapperView.addSubview(containerView)
            iconWindow.contentView = wrapperView
            iconWindow.orderFront(nil)
            return
        }
    }
}
