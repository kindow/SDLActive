//
//  ProxyManager.swift
//  TestSDL
//
//  Created by De biasi, Anna (A.) on 6/8/18.
//  Copyright © 2018 De biasi, Anna (A.). All rights reserved.
//

import UIKit

//Foundation
import SmartDeviceLink

class ProxyManager: NSObject {
    
    //weak var delegate: delegate?
    
    private let appName = "SyncProxyTester"
    private let appId = "883259982"
    
    // Manager
    fileprivate var sdlManager: SDLManager!
    
    // Singleton
    static let sharedManager = ProxyManager()
    
    private override init() {
        super.init()
        
        // Used for USB Connection
        let lifecycleConfiguration = SDLLifecycleConfiguration(appName: appName, appId: appId)
        
        // Used for TCP/IP Connection
        // let lifecycleConfiguration = SDLLifecycleConfiguration(appName: appName, appId: appId, ipAddress: "19.32.136.72", port: 12345)
        
        // App icon image
        if let appImage = UIImage(named: "AppIcon") {
            let appIcon = SDLArtwork(image: appImage, name: "AppIcon", persistent: true, as: .PNG /* or .PNG */)
            lifecycleConfiguration.appIcon = appIcon
        }
        // Short name for app
        lifecycleConfiguration.shortAppName = "EC"
       
        // Type of App created
        lifecycleConfiguration.appType = .information
        
        //
        let configuration = SDLConfiguration(lifecycle: lifecycleConfiguration, lockScreen: .enabled(), logging: .default())
        
        // configures
        sdlManager = SDLManager(configuration: configuration, delegate: self)
    }
    
    func connect() {
        // Start watching for a connection with a SDL Core
        sdlManager.start { (success, error) in
            if success {
                // Your app has successfully connected with the SDL Core
            }else{
                print("did not connect")
            }
        }
    }
}

//MARK: SDLManagerDelegate
extension ProxyManager: SDLManagerDelegate {
    
    func managerDidDisconnect() {
        print("Manager disconnected!")
    }
    
    func hmiLevel(_ oldLevel: SDLHMILevel, didChangeToLevel newLevel: SDLHMILevel) {
       // print("Went from HMI level \(oldLevel) to HMI level \(newLevel)")
        if(oldLevel == .none && newLevel == .full){
            // Defines the template layout
            let display = SDLSetDisplayLayout(predefinedLayout: .tilesWithGraphic)
            // Sending request to display layout
            sdlManager.send(request: display) { (request, response, error) in
                if response?.resultCode == .success {
                    // The template has been set successfully
                    print("The template has been set successfully")
                    self.setUp()
                }
            }
        }
    }
    
    func setUp(){
        sdlManager.screenManager.beginUpdates()
        // nutrition button
        let button1 = SDLSoftButtonObject(name: "Nutrition", state: SDLSoftButtonState.init(stateName: "Normal", text: "Nutrition", image: UIImage(named: "nutrition")!), handler: { (press, event) in
            guard let buttonPress1 = press else { return }
            switch buttonPress1.buttonPressMode {
                case .short:
                  self.makeCustomMenu(activity: "Nutrition", num: 1)
                default:
                    print("Error! nutrition")
            }
        })
        
        // soccer button
        let button2 = SDLSoftButtonObject(name: "Soccer", state: SDLSoftButtonState.init(stateName: "Normal", text: "Soccer", image: UIImage(named: "soccer")!), handler: { (press, event) in
            guard let buttonPress2 = press else { return }
            switch buttonPress2.buttonPressMode {
                case .short:
                    self.makeCustomMenu(activity: "Soccer", num: 2)
                default:
                    print("Error! soccer")
            }
        })
        
        // golf button
        let button3 = SDLSoftButtonObject(name: "Golf", state: SDLSoftButtonState.init(stateName: "Normal", text: "Golf", image: UIImage(named: "golf")!), handler: { (press, event) in
            guard let buttonPress3 = press else { return }
            switch buttonPress3.buttonPressMode {
                case .short:
                    self.makeCustomMenu(activity: "Golf" , num: 3)
            //  self.delegate?.didRequestMenuItems(event: "golf", callBack: {self.makeCustomMenu(activity: "Golf" , num: 3)})
                default:
                    print("Error! golf")
            }
        })
        // initializes the screen with the array of three buttons
        sdlManager?.screenManager.softButtonObjects = [button1, button2, button3]
        
        // puts the primary graphic on the screen
        sdlManager.screenManager.primaryGraphic = SDLArtwork.init(image: UIImage(named: "active")!, persistent: true, as: .PNG)
        
        // ends all screen updates
        sdlManager.screenManager.endUpdates { (error) in
            if error != nil {
                print("Error Updating UI")
            } else {
                print("Update to UI was Successful")
            }
        }
    }
    
    func makeCustomMenu(activity: String, num : Int){
        getJson(str: activity) { jsonData in
            var organizationNames = [String]()
            var count = 0
            while(count < 25){
                if(!organizationNames.contains((jsonData[count]).organization.organizationName)){
                    organizationNames.append((jsonData[count]).organization.organizationName)
                  //  print("COUNTTT :  ", organizationNames.count)
                }
                count += 1
            }
            count = 0
            var requestList = [SDLChoice]()
            for _ in  0..<organizationNames.count{
                requestList.append(SDLChoice(id: (UInt16(count + 8)), menuName: "\(organizationNames[count])", vrCommands: ["\(organizationNames[count])"]))
                count += 1
            }
            let createRequest = SDLCreateInteractionChoiceSet(id: UInt32(num), choiceSet: requestList)
            self.sdlManager.send(request: createRequest) { (request, response, error) in
                if response?.resultCode == .success {
                    //print("The request was successful, now send the SDLPerformInteraction RPC")
                    let performInteraction = SDLPerformInteraction(initialPrompt: "\(activity) Events", initialText: "\(activity) Events", interactionChoiceSetID: UInt16(num))
                    performInteraction.interactionMode = .manualOnly
                    performInteraction.interactionLayout = .listOnly
                    performInteraction.timeout = 15000 as NSNumber & SDLInt
                    self.sdlManager.send(request: performInteraction) { (request, response, error) in
                        let performInteractionResponse = response as! SDLPerformInteractionResponse
                        // Wait for user's selection or for timeout
                        if (performInteractionResponse.resultCode == SDLResult.timedOut || performInteractionResponse.resultCode == SDLResult.cancelRoute || performInteractionResponse.resultCode == .aborted ){
                            let deleteRequest = SDLDeleteInteractionChoiceSet(id: UInt32(num))
                            self.sdlManager.send(request: deleteRequest) { (request, response, error) in
                                if response?.resultCode == .success {
                                    print("The custom menu was deleted successfully 1")
                                }
                            }
                        }else if (performInteractionResponse.resultCode == .success){
                            // The custom menu timed out before the user could select an item
                            let choiceId = performInteractionResponse.choiceID
                            self.createAlert(activity: activity, jsonData: jsonData, identifier: num)
                            //self.displayInfoList(activity: activity, jsonData: jsonData, identifier : choiceId as! Int)
                                // The user selected an item in the custom menu
                              //  print("CHOICE ID   ", choiceId!)
                        }
                    }
                }
            }
        }
    }
    
    func createAlert(activity: String, jsonData: [APIStruct], identifier: Int){
        let address = " \((jsonData[identifier]).place.addressLine1Txt), \((jsonData[identifier]).place.cityName) \((jsonData[identifier]).place.stateProvinceCode)"
        let alert = SDLAlert(alertText1: activity , alertText2: address , alertText3: "Sales Start Date: \(String(getProperDate(from:(jsonData[identifier]).salesStartDate) ?? "N/A")), End Date: \(String( getProperDate(from:(jsonData[identifier]).salesEndDate) ?? "N/A"))")
        
        // Maximum time alert appears before being dismissed
        // Timeouts are must be between 3-10 seconds
        // Timeouts may not work when soft buttons are also used in the alert
        alert.duration = 5000 as NSNumber & SDLInt
        
        // A progress indicator (e.g. spinning wheel or hourglass)
        // Not all head units support the progress indicator
        alert.progressIndicator = true as NSNumber & SDLBool
        
        // Text-to-speech
        //alert.ttsChunks = SDLTTSChunk.textChunks(from: "hello")
        
        // Special tone played before the tts is spoken
        alert.playTone = true as NSNumber & SDLBool
        
        // Soft buttons
        let callNumber = SDLSoftButton()
        callNumber.text = "Call \((jsonData[identifier]).organization.primaryContactPhone)"
        callNumber.type = .text
        callNumber.softButtonID = 15 as NSNumber & SDLInt
        callNumber.handler = { (buttonPress, buttonEvent) in
            guard buttonPress != nil else { return }
            // create a custom action for the selected button
            let number = "7345760544"
            self.callNumber(number : number)
        }
        let getDirections = SDLSoftButton()
        getDirections.text = "Directions"
        getDirections.type = .text
        getDirections.softButtonID = 14 as NSNumber & SDLInt
        getDirections.handler = { (buttonPress, buttonEvent) in
            guard buttonPress != nil else { return }
            // create a custom action for the selected button
            self.getDirections(data : jsonData[identifier])
        }
        let menu = SDLSoftButton()
        menu.text = "Menu"
        menu.type = .text
        menu.softButtonID = 16 as NSNumber & SDLInt
        menu.handler = { (buttonPress, buttonEvent) in
            guard let press = buttonPress else { return }
            // create a custom action for the selected button
            print(press)
        }
        
        alert.softButtons = [getDirections, callNumber, menu]

        // Send the alert
        sdlManager.send(request: alert) { (request, response, error) in
            if response?.resultCode == .success {
                // alert was dismissed successfully
                let deleteRequest = SDLDeleteInteractionChoiceSet(id: UInt32(identifier))
                self.sdlManager.send(request: deleteRequest) { (request, response, error) in
                    if response?.resultCode == .success {
                       // print("The custom menu was deleted successfully")
                    }
                }
               // print("alert was dismissed successfully")
            }else{
                
                print("alert not successful")
                print("ERROR  ", error!)
            }
        }
    }
    
    func callNumber(number : String){
        var isPhoneCallSupported = false
        if let hmiCapabilities = self.sdlManager.registerResponse?.hmiCapabilities, let phoneCallsSupported = hmiCapabilities.phoneCall?.boolValue {
            isPhoneCallSupported = phoneCallsSupported
            if(!isPhoneCallSupported){
                print("Phone call is not supported")
            }
        }

        sdlManager.start { (success, error) in
            if !success {
                print("SDL errored starting up: \(error.debugDescription)")
                return
            }
        }
        
        let dialNumber = SDLDialNumber()
        dialNumber.number = "7345760544"

        sdlManager.send(request: dialNumber) { (request, response, error) in
            guard let response = response as? SDLDialNumberResponse else { return }
            
            if let error = error {
                print("Encountered Error sending DialNumber: \(error)")
                return
            }
            
            if response.resultCode != .success {
                if response.resultCode == .rejected {
                    print("DialNumber was rejected. Either the call was sent and cancelled or there is no device connected")
                } else if response.resultCode == .disallowed {
                    print("Your app is not allowed to use DialNumber")
                } else {
                    print("Some unknown error has occured!")
                }
                return
            }
            // Successfully sent!
        }
    }

    func getProperDate(from date: String) -> String? {
        // date format is YYYY-MM-DD
        let value = date
        let date1 = value[..<value.index(value.startIndex, offsetBy: 10)]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-mm-dd"
        guard let date = dateFormatter.date(from: String(date1)) else { return nil }
        dateFormatter.dateFormat = "MMMM dd, YYYY"
        let properDate = dateFormatter.string(from: date)
        return properDate
    }
    
    func getJson(str: String, completion: @escaping ([APIStruct]) ->()) { //_ callBack: (()-> ())?
        var apiStructData  = [APIStruct]()
        let session = URLSession(configuration: .ephemeral, delegate: nil, delegateQueue: OperationQueue.main)
        let url = URL(string: "http://api.amp.active.com/v2/search?query=\(str.lowercased())&category=event&start_date=2017-10-04..&near=Palo%20Alto,CA,US&radius=200&api_key=8auynm8hk7ejhq84pr64v77u")!
        let task = session.dataTask(with: url, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            guard let data = data else {
                return
            }
            guard let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) else {
                return
            }
            let dictJson = json as! [String : Any]
            for (key,_) in dictJson{
                if(key == "results"){
                    for result in dictJson["results"] as! [[String:Any]]{
                        let apiStruct = APIStruct(withData: result)
                        apiStructData.append(apiStruct!)
                    }
                    completion(apiStructData)
                }
            }
        })
        task.resume()
    }

    func getDirections(data : APIStruct){
        var isNavigationSupported = false
        if let hmiCapabilities = self.sdlManager.registerResponse?.hmiCapabilities, let navigationSupported = hmiCapabilities.navigation?.boolValue {
            isNavigationSupported = navigationSupported
            print(" T OR F  " , isNavigationSupported)
        }
        
        sdlManager.start { (success, error) in
            if !success {
                print("SDL errored starting up: \(error.debugDescription)")
                return
            }
        }

        let sendLocation = SDLSendLocation(longitude: -97.380967, latitude: 42.877737, locationName: data.organization.organizationName, locationDescription: "Western United States", address: ["\(data.place.addressLine1Txt), \(data.place.cityName), \(data.place.stateProvinceCode)"], phoneNumber: nil, image: nil)
        
        sdlManager.send(request: sendLocation) { (request, response, error) in
            guard let response = response as? SDLSendLocationResponse else { return }
            
            if let error = error {
                print("Encountered Error sending SendLocation: \(error)")
                return
            }
            
            if response.resultCode != .success {
                if response.resultCode == .invalidData {
                    print("SendLocation was rejected. The request contained invalid data.")
                } else if response.resultCode == .disallowed {
                    print("Your app is not allowed to use SendLocation")
                } else {
                    print("Some unknown error has occured!")
                }
                return
            }
            
            // Successfully sent!
        }
        
    }
}






/*
 * Creating the User Interface
 * 5.2 version of displaying text
 */


/* Satbir's Slack code to me
 *sdlManager.screenManager.primaryGraphic = SDLArtwork.init(image: #imageLiteral(resourceName: "icon"), persistent: true, as: .JPG)
 */


/*
 *Way #1 to do button
 *
 
 // Soft Buttons Object
 
 let softButtonState1 = SDLSoftButtonState(stateName: "Normal", text: "Button Label Text1", artwork:SDLArtwork(image: UIImage(named: "button")!, name: "button", persistent: true, as: SDLArtworkImageFormat(rawValue: 1)!))
 
 let softButtonState2 = SDLSoftButtonState(stateName: "Normal" , text: "Button Label Text2", artwork: SDLArtwork(image: UIImage(named: "button")!, name: "button", persistent: true, as: SDLArtworkImageFormat(rawValue: 1)!))
 
 let softButtonObject = SDLSoftButtonObject(name: "button", states: [softButtonState1, softButtonState2], initialStateName: "Normal") { (buttonPress, buttonEvent) in
 guard buttonPress != nil else { return }
 print("Button Selected")
 }
 sdlManager.screenManager.softButtonObjects = [softButtonObject]
 */


/*
 
 func displayInfoList(activity: String, jsonData: [APIStruct], identifier: Int){
 sdlManager.screenManager.beginUpdates()
 
 sdlManager.screenManager.textField1 = "\((jsonData[identifier]).place.addressLine1Txt), \((jsonData[identifier]).place.stateProvinceCode) \((jsonData[identifier]).place.cityName)"
 sdlManager.screenManager.textField2 = "\((jsonData[identifier]).assetPrices)"
 //sdlManager.screenManager.textField3 = "\((jsonData[identifier]).organization.primaryContactPhone)"
 // sdlManager.screenManager.textField4 = "Sales Start Date: \((jsonData[identifier]).salesStartDate), End Date: \((jsonData[identifier]).salesEndDate)"
 sdlManager.screenManager.primaryGraphic = SDLArtwork.init(image: UIImage(named: activity.lowercased())!, persistent: true, as: .PNG)
 //sdlManager.screenManager.softButtonObjects = [, <#SDLButtonObject#>]
 sdlManager.screenManager.endUpdates { (error) in
 if error != nil {
 print("Error Updating UI")
 } else {
 print("Update to UI was Successful")
 }
 }
 }
 
*/




