//
//  AppDelegate.swift
//  CSD Cycle Day
//
//  Created by Evan I. Trowbridge on 3/20/18.
//  Copyright © 2018 TrowLink. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    let statusItem = NSStatusBar.system.statusItem(withLength: -1)
    let popover = NSPopover()
    var eventMonitor: EventMonitor?
    var ViewController: ViewController?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        SetPrefs()
        
        // setup view controller
        let mainViewController = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil).instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "ViewControllerId")) as! ViewController
        
        // setup popover
        popover.contentViewController = mainViewController
        eventMonitor = EventMonitor(mask: [NSEvent.EventTypeMask.leftMouseDown, NSEvent.EventTypeMask.rightMouseDown]) { [unowned self] event in
            if self.popover.isShown {
                self.closePopover(sender: event)
            }
        }
        eventMonitor?.start()
        
        // setup menu icon
        if let button = statusItem.button {
            button.image = NSImage(named: NSImage.Name(rawValue: "StatusBarIcon"))
            button.imagePosition = .imageLeft
            button.title = "Cycle Day"
            //button.action = #selector(AppDelegate.updateCycleDay)
            button.action = #selector(self.doSomeAction(sender:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        // show or hide the menu bar item for api testing
        if(UserDefaults.standard.bool(forKey: "showMenuBar")){
            if #available(OSX 10.12, *) {
                statusItem.isVisible = true
            }
        } else {
            if #available(OSX 10.12, *) {
                statusItem.isVisible = false
            }
        }
        
        
        // print app config details
        print("Update Interval: "+String(UserDefaults.standard.integer(forKey: "updateInterval")))
        print("Spam Interval: "+String(UserDefaults.standard.integer(forKey: "spamInterval")))
        print("Sheet ID: "+UserDefaults.standard.string(forKey: "spreadsheetId")!)
        print("Sheet Name: "+UserDefaults.standard.string(forKey: "spreadsheetName")!)
        print("API Key: "+UserDefaults.standard.string(forKey: "sheetsAPIKey")!)
        print("Show Errors: "+String(UserDefaults.standard.bool(forKey: "showErrors")))
        print("Show Menu Bar: "+String(UserDefaults.standard.bool(forKey: "showMenuBar")))
        print("Spam Protection: "+String(UserDefaults.standard.bool(forKey: "spamProtection")))
        print("--------------------------------------------------------------")
        
        // timer for icon and notifications
        start()
        _ = Timer.scheduledTimer(timeInterval: TimeInterval(5), target: self, selector: #selector(AppDelegate.start), userInfo: nil, repeats: true)
    }
    
    @objc func doSomeAction(sender: NSStatusItem) {
        let event = NSApp.currentEvent!
        if event.type == NSEvent.EventType.rightMouseUp {
            togglePopover(nil)
        } else {
            manualUpdate()
        }
    }
    @objc func togglePopover(_ sender: Any?) {
        if popover.isShown {
            closePopover(sender: sender)
        } else {
            showPopover(sender: sender)
        }
    }
    func showPopover(sender: Any?) {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
    }
    func closePopover(sender: Any?) {
        popover.performClose(sender)
    }
    
    var lastCheckUpdate = NSDate() //get time when app started for timer
    var fistCheckUpdate = false
    @objc func start(){
        let elapsedTime = NSDate().timeIntervalSince(lastCheckUpdate as Date)
        //print(elapsedTime)
        
        if (elapsedTime>=Double(UserDefaults.standard.integer(forKey: "updateInterval"))){
            lastCheckUpdate = NSDate() // record time again
            _ = Timer.scheduledTimer(timeInterval: TimeInterval(15), target: self, selector: #selector(AppDelegate.updateCycleDay), userInfo: nil, repeats: false)
            print("debug: update main"+" - "+Date().description(with: Locale.current))
        }
        if (fistCheckUpdate==false){
            updateCycleDay()
            fistCheckUpdate = true
            print("debug: update first"+" - "+Date().description(with: Locale.current))
        }
    }
    
    // spam prevent
    var lastCheckManualUpdate = NSDate() //get time when app started for timer
    var fistCheckManualUpdate = false
    @objc func manualUpdate(){
        if(UserDefaults.standard.bool(forKey: "spamProtection")) {
            let elapsedTime = NSDate().timeIntervalSince(lastCheckManualUpdate as Date)
            //print(elapsedTime)
            
            if (elapsedTime>=Double(UserDefaults.standard.integer(forKey: "spamInterval"))){
                lastCheckManualUpdate = NSDate() // record time again
                updateCycleDay()
                print("debug: manual update main "+" - "+Date().description(with: Locale.current))
            }
            if (fistCheckManualUpdate==false){
                updateCycleDay()
                fistCheckManualUpdate = true
                print("debug: manual update first"+" - "+Date().description(with: Locale.current))
            }
        } else {
            updateCycleDay()
            print("debug: manual update"+" - "+Date().description(with: Locale.current))
        }
    }
    
    // setup errors
    enum MyError: Error {
        case FoundError(String)
    }
    
    // check for sheet update
    @objc func updateCycleDay() {
        
        // check for internet connection
        if Reachability.isConnectedToNetwork(){
            DispatchQueue.main.async {
                var values: [String] = []
                
                // request url
                let url = NSURL(string: "https://sheets.googleapis.com/v4/spreadsheets/"+UserDefaults.standard.string(forKey: "spreadsheetId")!+"/values/"+UserDefaults.standard.string(forKey: "spreadsheetName")!+"!A1:C1?key="+UserDefaults.standard.string(forKey: "sheetsAPIKey")!+"")
                
                //fetching the data from the url
                URLSession.shared.dataTask(with: (url as URL?)!, completionHandler: {(data, response, error) -> Void in
                    do {
                        if let jsonObj  = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? NSDictionary {
                            //printing the json in console
                            //print(jsonObj)
                            
                            // decode the json
                            if let valueArray = jsonObj.value(forKey: "values") as? NSArray {
                                //looping through all the elements
                                //print(valueArray)
                                for value in valueArray{
                                    //print(value)
                                    if let valueArray2 = value as? NSArray {
                                        for cell in valueArray2 {
                                            //print(cell)
                                            values.append(cell as! String)
                                        }
                                    }
                                }
                            }
                            
                            // error detecting
                            if(String(describing: jsonObj).range(of:"API key not valid") != nil){
                                print("ERROR: API key not valid.")
                                DispatchQueue.main.async {
                                    self.ShowError(errorString: "API key not valid.")
                                }
                                throw MyError.FoundError("ERROR: API key not valid.")
                            } else if(String(describing: jsonObj).range(of:"Unable to parse range") != nil){
                                print("ERROR: Unable to parse range.")
                                DispatchQueue.main.async {
                                    self.ShowError(errorString: "Unable to parse range.")
                                }
                                throw MyError.FoundError("ERROR: Unable to parse range.")
                            } else if(String(describing: jsonObj).range(of:"Requested entity was not found") != nil){
                                print("ERROR: Sheet not found.")
                                DispatchQueue.main.async {
                                    self.ShowError(errorString: "Sheet not found.")
                                }
                                throw MyError.FoundError("ERROR: Sheet not found.")
                            } else if (values.count < 3){
                                DispatchQueue.main.async {
                                    self.ShowError(errorString: "Spreadsheet not configured correctly.")
                                }
                                print("ERROR: Spreadsheet not configured correctly.")
                                throw MyError.FoundError("ERROR: Spreadsheet not configured correctly.")
                            } else if(values.count == 3){
                                print(values[2])
                                DispatchQueue.main.async {
                                    self.statusItem.title = values[2];
                                    self.ViewController?.setCycleDayPopover(cycleDayText: values[2])
                                }
                            } else {
                                print(error ?? "error")
                                _ = Timer.scheduledTimer(timeInterval: TimeInterval(15), target: self, selector: #selector(AppDelegate.updateCycleDay), userInfo: nil, repeats: false)
                            }
                            //remove cache for better results
                            URLCache.shared.removeAllCachedResponses()
                        } else {
                            print("Error: jsonObj")
                        }
                    } catch {
                        //print(error)
                        //self.updateCycleDay()
                        print(error.localizedDescription)
                    }
                }).resume()
                // clear values array
                values.removeAll()
            }
        }else{
            print("Internet Connection not Available! Retrying in 5sec")
            _ = Timer.scheduledTimer(timeInterval: TimeInterval(15), target: self, selector: #selector(AppDelegate.updateCycleDay), userInfo: nil, repeats: false)
        }
    }
    
    func ShowError(errorString: String){
        if(UserDefaults.standard.bool(forKey: "showErrors")){
            let alert = NSAlert()
            alert.messageText = "Error"
            alert.informativeText = errorString
            alert.addButton(withTitle: "OK")
            _ = alert.runModal()
        }
    }
    
    // set defualt prefs
    func SetPrefs(){
        UserDefaults.standard.set(5, forKey: "timerInterval")
        UserDefaults.standard.set(7200, forKey: "updateInterval")
        UserDefaults.standard.set(100, forKey: "spamInterval")
        UserDefaults.standard.set("api_key", forKey: "sheetsAPIKey")
        UserDefaults.standard.set("spreadsheet_Id", forKey: "spreadsheetId")
        UserDefaults.standard.set("sheet_name", forKey: "spreadsheetName")
        UserDefaults.standard.set(true, forKey: "showErrors")
        UserDefaults.standard.set(true, forKey: "showMenuBar")
        UserDefaults.standard.set(true, forKey: "spamProtection")
        
        // file path for plist
        //let path = "/Library/Preferences/com.trowlink.CycleDay.plist"
        let path = "/Users/trowbrev18/Desktop/com.trowlink.CycleDay.plist"
        
        //var pathToApplication: String = Bundle.main.bundlePath
        
        let selfServiceFileManager = FileManager.default
        
        if selfServiceFileManager.fileExists(atPath: path) {
            let dictRoot = NSDictionary(contentsOfFile: path)
            if let dict = dictRoot {
                //print(dict)
                UserDefaults.standard.set(dict["timerInterval"] as! Int, forKey: "timerInterval")
                UserDefaults.standard.set(dict["updateInterval"] as! Int, forKey: "updateInterval")
                UserDefaults.standard.set(dict["spamInterval"] as! Int, forKey: "spamInterval")
                UserDefaults.standard.set(dict["sheetsAPIKey"] as! String, forKey: "sheetsAPIKey")
                UserDefaults.standard.set(dict["spreadsheetId"] as! String, forKey: "spreadsheetId")
                UserDefaults.standard.set(dict["spreadsheetName"] as! String, forKey: "spreadsheetName")
                UserDefaults.standard.set(dict["showErrors"] as! Bool, forKey: "showErrors")
                UserDefaults.standard.set(dict["showMenuBar"] as! Bool, forKey: "showMenuBar")
                UserDefaults.standard.set(dict["spamProtection"] as! Bool, forKey: "spamProtection")
            }
        } else {
            // show error message if no plist found in path specified above
            print("debug: plist error - "+String(UserDefaults.standard.bool(forKey: "dontShowNotFoundError")))
            if(UserDefaults.standard.bool(forKey: "dontShowNotFoundError") == false) {
                let alert = NSAlert()
                alert.messageText = "Error"
                alert.informativeText = "Cycle Day configuration not found at: " + path + " Cycle Day will use default configuration."
                alert.addButton(withTitle: "OK")
                alert.addButton(withTitle: "Don't show this message again.")
                let result = alert.runModal()
                switch(result) {
                case NSApplication.ModalResponse.alertFirstButtonReturn:
                    print("OK")
                case NSApplication.ModalResponse.alertSecondButtonReturn:
                    UserDefaults.standard.set(true, forKey: "dontShowNotFoundError")
                    print("don't show again")
                default:
                    break
                }
            }
        }
    }
}


// check connection -----------------------------------------------------
import SystemConfiguration

public class Reachability {
    
    class func isConnectedToNetwork() -> Bool {
        
        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == false {
            return false
        }
        
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        let ret = (isReachable && !needsConnection)
        
        return ret
    }
}
