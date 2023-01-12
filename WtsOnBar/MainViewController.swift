/*
Author: <Anthony Sychev> (hello at dm211 dot com | a.sychev at jfranc dot studio) 
Buy me a coffe: https://www.buymeacoffee.com/twooneone
MainViewController.swift (c) 2023 
Created:  2023-01-12 21:21:36 
Desc: 

 
TODO:
    [] - save files to storage
        https://developer.apple.com/forums/thread/680302
        https://stackoverflow.com/questions/13189531/api-to-get-users-download-folder-on-mac-in-a-sandbox-app
    [] - separete localStorage from two views
 
 https://stackoverflow.com/questions/39772007/wkwebview-persistent-storage-of-cookies
 https://www.innominds.com/blog/wkwebview-to-native-code-interaction
 
 Samples:
 https://www.raywenderlich.com/450-menus-and-popovers-in-menu-bar-apps-for-macos
 
*/

import WebKit
import Cocoa

class MainViewController: NSViewController, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler, WKDownloadDelegate {
   
    let urlWhatsapp:URL = URL(string: "https://web.whatsapp.com/")!
    let urlTelegram:URL = URL(string: "https://web.telegram.org/k/")!
    let urlDiscord:URL = URL(string: "https://discord.com/app/")!
    
    let op = ProcessInfo().operatingSystemVersion
       
    var pinStatus: Bool = false;
    
    let defaults = UserDefaults.standard
    
    var customAgent = "Mozilla/5.0 (Macintosh; %arch% Mac OS X %bus% %ver%) TwoOneOne AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.2 Safari/605.1.15"
    
    var wtsLocalStorage: String = "";
    
    let prevWhtTitle: String = "";
    let webWthCfg:WKWebViewConfiguration = WKWebViewConfiguration()
    var userController:WKUserContentController = WKUserContentController()
     
    @IBOutlet weak var wtsWebKit: WKWebView! //link to front view container
    @IBOutlet weak var teleWebKit: WKWebView! //link to front view container
    @IBOutlet weak var discWebKit: WKWebView! //link to front view container
    
    struct BlobComponents: Codable {
        let url: String
        let mimeType: String
        let size: Int64
        let dataString: String
    }
    
    override func viewDidAppear()
    {
        super.viewDidAppear()
        // You can use a notification and observe it in a view model where you want to fetch the data for your SwiftUI view every time the popover appears.
        //NotificationCenter.default.post(name: Notification.Name("ViewDidAppear"), object: nil)
        
        //here update status of view elements
        
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
                
        if UserDefaults.standard.string(forKey: "pinstatus") != nil {
            self.pinStatus = UserDefaults.standard.bool(forKey: "pinstatus");
        }else{
            defaults.set(pinStatus, forKey: "pinstatus");
            defaults.synchronize();
        }
        
        //complete user-agent
        var osArch: String = "Intel"
        
        #if !arch(x86_64)
            osArch = "Silicon"
        #endif
        
        customAgent = customAgent.replacingOccurrences(of: "%arch%", with: "\(osArch)")
        customAgent = customAgent.replacingOccurrences(of: "%ver%", with: "\(op.majorVersion)_\(op.minorVersion)_\(op.patchVersion)")
        
        //----------------
       
        //HTTPCookieStorage.shared.cookieAcceptPolicy = .always
        let storage = HTTPCookieStorage.shared
        storage.cookieAcceptPolicy = .never
        debugPrint(storage.cookies as Any) // 0

        //----------------
        
        //WHATS APP
        var urlWthReq = URLRequest(url: urlWhatsapp);
        urlWthReq.setValue("TwoOneOne", forHTTPHeaderField:"X-Author")
        
        //let wtsWebKit = WKWebView(frame: CGRect(x: -3, y: -3, width: 897/*self.view.frame.width*/, height: 632 /*self.view.frame.height-200.0*/), configuration: webCfg)

        wtsWebKit.load(urlWthReq)
        wtsWebKit.customUserAgent = customAgent
                
        if #available(OSX 11.0, *) {
            wtsWebKit.pageZoom = 0.8
        }
        
        wtsWebKit.navigationDelegate = self
        
        let wtsController = wtsWebKit?.configuration.userContentController;
        wtsController?.add(self, name: "jsBlobDownload")
        wtsController?.add(self, name: "jsListener")
            
        //NOTE: observer on change title of page
        wtsWebKit.addObserver(self, forKeyPath: #keyPath(WKWebView.title), options: .new, context: nil)
        
        ///
        ///
        //Blob Download
        //DOC: https://stackoverflow.com/questions/70312488/how-to-download-a-blob-uri-using-alamofire
        //DOC: https://www.advancedswift.com/get-javascript-errors-from-a-wkwebview-in-swift/
        //Minifier: https://skalman.github.io/UglifyJS-online/
        /*
         (function () {})();
         
         function blobToDataURL(blob, callback) {
             var reader = new FileReader()
             reader.onload = function(e) {callback(e.target.result.split(",")[1])}
             reader.readAsDataURL(blob)
         }

         async function run() {
             const url = "\(url)"
             const blob = await fetch(url).then(r => r.blob())

             blobToDataURL(blob, datauri => {
                 const responseObj = {
                     url: url,
                     mimeType: blob.type,
                     size: blob.size,
                     dataString: datauri
                 }
                 window.webkit.messageHandlers.jsListener.postMessage(JSON.stringify(responseObj))
             })
         }

         run()
         
        */
        let scriptJsBlobDownload = WKUserScript(
            source:
                """
                 function blobToDataURL(blob, callback) {
                     var reader = new FileReader()
                     reader.onload = function(e) {callback(e.target.result.split(",")[1])}
                     reader.readAsDataURL(blob)
                 }

                 async function run() {
                     const url = "(url)"
                     const blob = await fetch(url).then(r => r.blob())

                     blobToDataURL(blob, datauri => {
                         const responseObj = {
                             url: url,
                             mimeType: blob.type,
                             size: blob.size,
                             dataString: datauri
                         }
                            console.log(JSON.stringify(responseObj))
                         window.webkit.messageHandlers.jsBlobDownload.postMessage(JSON.stringify(responseObj))
                     })
                 }

                 run()
                """,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        
        wtsController?.addUserScript(scriptJsBlobDownload);
        ///
        ///
        
        //----------------
        
        //TELEGRAM
        var urlTeleReq = URLRequest(url: urlTelegram);
        urlTeleReq.setValue("TwoOneOne", forHTTPHeaderField:"X-Author")
        
        //let wtsWebKit = WKWebView(frame: CGRect(x: -3, y: -3, width: 897/*self.view.frame.width*/, height: 632 /*self.view.frame.height-200.0*/), configuration: webCfg)

        teleWebKit.load(urlTeleReq)
        teleWebKit.customUserAgent = customAgent
        
        if #available(OSX 11.0, *) {
            teleWebKit.pageZoom = 0.8
        }
        
        teleWebKit.navigationDelegate = self
        
        //NOTE: observer on change title of page
        teleWebKit.addObserver(self, forKeyPath: #keyPath(WKWebView.title), options: .new, context: nil)
        
        //----------------
        
        //DISCOD
        var urlDiscReq = URLRequest(url: urlDiscord);
        urlDiscReq.setValue("TwoOneOne", forHTTPHeaderField:"X-Author")
        
        discWebKit.load(urlDiscReq)
        discWebKit.customUserAgent = customAgent
        
        if #available(OSX 11.0, *) {
            discWebKit.pageZoom = 0.8
        }
        
        discWebKit.navigationDelegate = self
        
        //NOTE: observer on change title of page
        discWebKit.addObserver(self, forKeyPath: #keyPath(WKWebView.title), options: .new, context: nil)
        
        //----------------
    }
    
    /*
     Detect changes on title or content of page
     */
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "title" {
            //whatsupp show notification
            if let title = wtsWebKit.title {
                debugPrint("[169] -> whats app change title")
                debugPrint(title)
                //DOC:https://stackoverflow.com/questions/24049020/nsnotificationcenter-addobserver-in-swift
                if title != prevWhtTitle {
                    NotificationCenter.default.post(name: Notification.Name("changeNotificationIcon"), object: nil)
                }
            }
            
            //teleWebKit
            //discWebKit
        }
    }
    
    /*
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
    }
    */
    
    /*
     Implement Policy configs apply
     */
    /*
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        //NOTE: allow or deny hosts
        if let host = navigationAction.request.url?.host {
                if host == "whatsapp.com" {
                    decisionHandler(.allow)
                    return
                }
            }
        //decisionHandler(.cancel)
     
        //NOTE: detect blob
        if let url = navigationAction.request.url, let scheme = url.scheme?.lowercased() {
            if scheme == "blob" {
                // Defer to JS handling
                debugPrint("[220] -> blob")
                //blobDownloadWith(jsonString: url)
                debugPrint(url)
                
                
                decisionHandler(.cancel)
            } else {
                
                decisionHandler(.allow)
            }
        }
    }
     */
     
    
    //TODO: interpret js for download files, open links and other staff
    //recive messages from js
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        debugPrint("[232] -> ok from js")
        debugPrint(message)
        debugPrint(message.name)
        
        //NOTE: can send new window on safari
        if message.name == "jsListener" {
            debugPrint(message.body)
            return;
        }
        
        if message.name == "jsBlobDownload" {
            guard let jsonString = message.body as? String else {
                return
            }
            blobDownloadWith(jsonString: jsonString)
        }
    }
    
    /**
        Callback on show pop
     */
    func onShowPopover() {
        debugPrint("--> showing pop from mainViewController")
    }
    
    //---------------------------------------------------------------------------------
    
    //Download Files
    @available(macOS 11.3, *)
    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        //NOTE:is called when download file
        download.delegate = self
    }
    
    @available(macOS 11.3, *)
    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        download.delegate = self
    }
    
    @available(macOS 11.3, *)
    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
        
        debugPrint("[211] -> download")
        
        let url = response.url
        let scheme = url?.scheme?.lowercased()
        
        if scheme != "blob" {
            downloadFileToUserDesktopFolder(url: url!, fileName: response.suggestedFilename!)
        }
        
        /*
        if scheme == "blob" {
            return;
            //downloadBlob(url: url!)
        }else{
            downloadFileToUserDesktopFolder(url: url!, fileName: response.suggestedFilename!)
        }
        */
    }
        
    /**
        constol when download is finished
     */
    @available(macOS 11.3, *)
    func downloadDidFinish(_ download: WKDownload) {
        debugPrint("[220] -> download donw")
    }
    
    /**
        Download with blob
     */
    private func blobDownloadWith(jsonString: String) {
        guard let jsonData = jsonString.data(using: .utf8) else {
            debugPrint("[255] Cannot convert blob JSON into data!")
            return
        }

        let decoder = JSONDecoder()
        
        do {
            let file = try decoder.decode(BlobComponents.self, from: jsonData)
            
            guard let data = Data(base64Encoded: file.dataString),
                let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, file.mimeType as CFString, nil),
                let ext = UTTypeCopyPreferredTagWithClass(uti.takeRetainedValue(), kUTTagClassFilenameExtension)
            else {
                debugPrint("[268] error")
                return
            }
            
            let fileName = file.url.components(separatedBy: "/").last ?? "unknown"
            let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let url = path.appendingPathComponent("blobDownload-\(fileName).\(ext.takeRetainedValue())")
            
            try data.write(to: url)
            
            let locFile = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop/").appendingPathComponent(fileName)
            try data.write(to: locFile)
            
        } catch {
            debugPrint("[278] error")
            return
        }
    }
    
    /**
     Download file
     */
    private func downloadFileToUserDesktopFolder(url downloadUrl : URL, fileName: String) {
        debugPrint("[229] -> download file")
        debugPrint(fileName)
        
        let localFileURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop/").appendingPathComponent(downloadUrl.lastPathComponent)
        
        
        //let localFileURL = FileManager.default.temporaryDirectory.appendingPathComponent(downloadUrl.lastPathComponent)

        URLSession.shared.dataTask(with: downloadUrl) { data, response, err in
            guard let data = data, err == nil else {
                debugPrint("[232] Error while downloading document from url=\(downloadUrl.absoluteString): \(err.debugDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                debugPrint("[237] Download http status=\(httpResponse.statusCode)")
            }

            // write the downloaded data to a temporary folder
            do {
                try data.write(to: localFileURL, options: .atomic)   // atomic option overwrites it if needed
                debugPrint("[243] Stored document from url=\(downloadUrl.absoluteString) in folder=\(localFileURL.absoluteString)")
                /*
                DispatchQueue.main.async {
                    // localFileURL
                    // here is where your file
                    
                   
                     //NOTE: move tmp file to desktop
                    //let home = FileManager.default.homeDirectoryForCurrentUser
                    let home = FileManager.default.homeDirectoryForCurrentUser
                    let playgroundURL = home.appendingPathComponent("Desktop/")
                    let fileManager = FileManager.default
                    
                    let newFile = playgroundURL.appendingPathComponent(fileName).path
                    
                    do{
                        try fileManager.moveItem(atPath: localFileURL.absoluteString, toPath: newFile)
                    } catch {
                        debugPrint("[254] -> download write error on documents folder")
                        debugPrint(error)
                    }
                     
                }
                 */
            } catch {
                debugPrint(error)
                return
            }
        }.resume()
    }
}
