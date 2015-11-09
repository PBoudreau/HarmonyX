//
//  InterfaceController.swift
//  Watch Extension
//
//  Created by Philippe Boudreau on 2015-11-01.
//  Copyright © 2015 Fasterre. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity

import FSCHarmonyConfigKit

class InterfaceController: WKInterfaceController, WCSessionDelegate {

    @IBOutlet var table: WKInterfaceTable!
    
    @IBOutlet var statusGroup: WKInterfaceGroup!
    @IBOutlet var statusLabel: WKInterfaceLabel!
    @IBOutlet var activityImage: WKInterfaceImage!
    
    var session: WCSession? {
        didSet {
            if let session = session {
                session.delegate = self
                session.activateSession()
            }
        }
    }
    
    var harmonyConfiguration: FSCHarmonyConfiguration?
    var startingUp = true
    
    override init() {
        super.init()
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        session = WCSession.defaultSession()
        
        self.showStatus(true,
            withMessage: "Loading...",
            showActivity:  true)
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        print("willActivate")

        if (self.startingUp)
        {
            self.startingUp = false
            
            self.obtainInitialHarmonyHubState()
        }
        else
        {
            // Introduce a small delay before reconnecting to Harmony Hub as otherwise, we get
            // the error:
            //
            // Error connecting:  Error Domain=WCErrorDomain Code=7007 "WatchConnectivity session 
            // on paired device is not reachable."
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), { () -> Void in
                
                while !self.session!.reachable
                {
                    NSThread.sleepForTimeInterval(0.25)
                }
                
                self.session!.sendMessage(["command": "connect"], replyHandler:
                    {
                        (response) -> Void in
                        
                        self.refreshHarmonyHubState()
                        
                    }) { (error) -> Void in
                        print("Error connecting: ", error)
                }
            })
        }
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()

        print("didDeactivate")
        
        session!.sendMessage(["command": "disconnect"], replyHandler:
            {
                (response) -> Void in
                
                
            }) { (error) -> Void in
                print("Error disconnecting: ", error)
        }
    }

    func showStatus(showStatus: Bool,
        withMessage message: String?,
        showActivity showAcrivity: Bool)
    {
        self.statusGroup.setHidden(!showStatus);
        self.activityImage.setHidden(!showStatus && !showAcrivity)
        
        if let unwrappedMessage = message {
            
            self.statusLabel.setText(unwrappedMessage)
        }
    }
    
    private func obtainInitialHarmonyHubState() {
    
        print("initializeState")
        
        session!.sendMessage(["command": "getHarmonyState"], replyHandler:
            {
                (response) -> Void in
                
                if let currentActivityDict = response["currentActivity"] as? NSDictionary, currentActivity = FSCActivity.modelObjectWithDictionary(currentActivityDict as [NSObject : AnyObject])
                {
                    if let harmonyConfigDict = response["configuration"] as? NSDictionary, harmonyConfig = FSCHarmonyConfiguration.modelObjectWithDictionary(harmonyConfigDict as [NSObject : AnyObject]) {
                        
                        self.refreshTableWithConfig(harmonyConfig, currentActivity: currentActivity)
                        
                        self.session!.sendMessage(["command": "connect"], replyHandler:
                            {
                                (response) -> Void in
                                
                                
                            }) { (error) -> Void in
                                print("Error connecting: ", error)
                        }
                    }
                }
                
            }, errorHandler: { (error) -> Void in
                print("Error obtaining Harmony state: ", error)
        })
    }
    
    private func refreshHarmonyHubState() {
        
        print("refreshHarmonyHubState")
        
        session!.sendMessage(["command": "refreshHarmonyState"], replyHandler:
            {
                (response) -> Void in
                                
            }, errorHandler: { (error) -> Void in
                print("Error refreshing Harmony state: ", error)
        })
    }
    
    private func refreshTableWithConfig(harmonyConfig: FSCHarmonyConfiguration, currentActivity: FSCActivity)
    {
        let activities = harmonyConfig.activity
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            self.table.setNumberOfRows(activities.count, withRowType: "ActivityTableRowController")
            
            for (index, element) in activities.enumerate() {
                let row = self.table.rowControllerAtIndex(index) as! ActivityTableRowController
                
                let activity = element as! FSCActivity
                
                row.image.setImage(activity.watchImage(currentActivity.activityIdentifier == activity.activityIdentifier))
                row.activityName.setText(activity.label);
            }
            
            self.showStatus(false,
                withMessage: nil,
                showActivity: false);
        })
    }
    
    func session(session: WCSession,
        didReceiveMessage message: [String : AnyObject])
    {
        if let command = message["command"] as? NSString
        {
            print("Watch App received command", command)
            
            if command.isEqualToString("configurationChanged") ||
                command.isEqualToString("currentActivityChanged")
            {
                if let currentActivityDict = message["activity"] as? NSDictionary, currentActivity = FSCActivity.modelObjectWithDictionary(currentActivityDict as [NSObject : AnyObject])
                {
                    if let harmonyConfigDict = message["configuration"] as? NSDictionary, harmonyConfig = FSCHarmonyConfiguration.modelObjectWithDictionary(harmonyConfigDict as [NSObject : AnyObject]) {
                        
                        self.refreshTableWithConfig(harmonyConfig, currentActivity: currentActivity)
                    }
                }
            }
        }
    }
}
