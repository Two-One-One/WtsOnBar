/*
 Close program
 NSApplication.shared.terminate(self)
 */
import AppKit
import WebKit
import Cocoa

class TabViewController: NSViewController, WKUIDelegate, WKNavigationDelegate {
    
    @IBOutlet weak var WtsWebKit: WKWebView!
    
    override func loadView() {}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //WHATS APP
        let url = URL(string: "https://web.whatsapp.com/")!
        WtsWebKit.load(URLRequest(url: url))
        WtsWebKit.allowsBackForwardNavigationGestures = true
        
        /*
        //WHATS APP BUSINESS
        WtsBWebKit.load(URLRequest(url: url))
        WtsBWebKit.allowsBackForwardNavigationGestures = true
         */
    }
    
    override func viewDidAppear()
    {
        super.viewDidAppear()
        // You can use a notification and observe it in a view model where you want to fetch the data for your SwiftUI view every time the popover appears.
        // NotificationCenter.default.post(name: Notification.Name("ViewDidAppear"), object: nil)
    }
    
}
