/*
Author: <Anthony Sychev> (hello at dm211 dot com | a.sychev at jfranc dot studio) 
Buy me a coffe: https://www.buymeacoffee.com/twooneone
AppDelegate.swift (c) 2023 
Created:  2023-01-12 21:07:40 
Desc: Main app
Doc: Controls popup container where is shows tabs
Sample: https://github.com/AnaghSharma/Ambar-SwiftUI/
*/

import Cocoa

@NSApplicationMain

class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var eventMonitor: EventMonitor?
    
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength) //NOTE: Left / Right padding over icons
    
    let popover = NSPopover();
    let mainViewController = MainViewController(nibName: "MainViewController", bundle: nil); //NOTE: call some function from MainViewController Class
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if let button = statusItem.button {
            setNotificationOnStatusBar(value: false)
            
            button.action = #selector(statusBarButtonClicked(sender:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.target = self
        }
        
        //NOTE: add lisner for click outside close popup
        eventMonitor = EventMonitor(mask: [.leftMouseUp, .rightMouseUp], handler: mouseEventHandler)
        
        //popover.contentViewController?.view = NSHostingView(rootView: contentView)
        popover.contentViewController = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil).instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("TabView")) as? NSViewController
        
        popover.behavior = .semitransient
        popover.animates = true
        //popover.contentSize = NSSize(width: 360, height: 360)
        
        //
        NotificationCenter.default.addObserver(self, selector: #selector(self.methodOfReceivedNotification(notification:)), name: Notification.Name("changeNotificationIcon"), object: nil)

    }
    
    //NOTE: recive listener for change icon
    @objc func methodOfReceivedNotification(notification: Notification) {
        self.setNotificationOnStatusBar(value: true)
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    /**
        Mouse event,
        close popup view on click out of it
    */
    func mouseEventHandler(_ event: NSEvent?) {
        if(mainViewController.pinStatus == false)
        {
            //close popup on clock out
            if(popover.isShown) {
                hidePopover(sender: nil)
            }
        }
    }
  
    /**
        Show / change notification icon on status bar
    */
    func setNotificationOnStatusBar(value: Bool) {
        if value {
            //notify
            if let statusBarButton = statusItem.button {
                statusBarButton.image = #imageLiteral(resourceName: "StatusBarNotifyIcon")
                statusBarButton.image?.size = NSSize(width: 18.0, height: 18.0)
                statusBarButton.image?.isTemplate = true
            }
        }else{
            //normal
            if let statusBarButton = statusItem.button {
                statusBarButton.image = #imageLiteral(resourceName: "StatusBarIcon")
                statusBarButton.image?.size = NSSize(width: 18.0, height: 18.0)
                statusBarButton.image?.isTemplate = true
            }
        }
    }
        
    func showPopover(sender: AnyObject?) {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            
            self.mainViewController.onShowPopover();
            
            if UserDefaults.standard.bool(forKey: "pinstatus") == false {
                eventMonitor?.start()
            }
        }
    }
    
    func hidePopover(sender: AnyObject?) {
        popover.performClose(sender)
        
        if UserDefaults.standard.bool(forKey: "pinstatus") == false {
            eventMonitor?.stop()
        }
    }
    
    /**
        Action on click over icon
        Single clicl
        Right click solution: https://stackoverflow.com/questions/38999700/detect-left-and-right-click-events-on-nsstatusitem-swift
    */
    @objc func statusBarButtonClicked(sender: NSStatusBarButton) {
        
        let event = NSApp.currentEvent!
        
        self.setNotificationOnStatusBar(value: false)
        
        if event.type == .rightMouseUp {
            // Right button click
            hidePopover(sender: nil)
            
            let contextMenu = NSMenu()
            contextMenu.addItem(NSMenuItem(title: "About", action: #selector(onShowAbout(sender:)), keyEquivalent: "a"))
            contextMenu.addItem(NSMenuItem(title: "Pin / Un Pin", action: #selector(onPinUnpin(sender:)), keyEquivalent: "p"))
            contextMenu.addItem(NSMenuItem(title: "Quit", action: #selector(onQuit(sender:)), keyEquivalent: "q"))
            
            statusItem.menu = contextMenu
            statusItem.popUpMenu(contextMenu);
            statusItem.menu = nil //NOTE: Otherwise clicks won't be processed again
        } else {
            // Left button click
            if popover.isShown {
                hidePopover(sender: nil)
            } else {
                showPopover(sender: nil)
            }
        }
    }
    
    @objc func onShowAbout(sender: NSMenuItem) {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        if let windowController = storyboard.instantiateController(withIdentifier: "About") as? NSWindowController {
            windowController.showWindow(self)
        }
    }
        
    /**
        Call function for pi and unpin tabs view
     */
    @objc func onPinUnpin(sender: NSMenuItem) {
        mainViewController.pinStatus.toggle()
        mainViewController.defaults.set(mainViewController.pinStatus, forKey: "pinstatus");
        mainViewController.defaults.synchronize();
        
        eventMonitor?.stop()
    }
    
    /**
        Exit from program on select option
     */
    @objc func onQuit(sender: AnyObject?) {
        NSApplication.shared.terminate(self)
    }
}

