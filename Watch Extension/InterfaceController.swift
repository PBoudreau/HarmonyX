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

    @IBOutlet var activityImage: WKInterfaceImage!
    @IBOutlet var table: WKInterfaceTable!
    
    var session: WCSession? {
        didSet {
            if let session = session {
                session.delegate = self
                session.activateSession()
            }
        }
    }
    
    var harmonyConfiguration: FSCHarmonyConfiguration?
    var stateInitialized = false
    
    override init() {
        super.init()
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        if (!stateInitialized)
        {
            stateInitialized = true
            
            self.initializeState()
        }
        else
        {
            // *** Doesn't seem to be getting called.
            
            session = WCSession.defaultSession()
            
            session!.sendMessage(["command": "connect"], replyHandler:
                {
                    (response) -> Void in
                    
                    
                }) { (error) -> Void in
                    print(error)
            }
        }
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        
        session = WCSession.defaultSession()
        
        session!.sendMessage(["command": "disconnect"], replyHandler:
            {
                (response) -> Void in
                
                
            }) { (error) -> Void in
                print(error)
        }
    }

    private func initializeState() {
        session = WCSession.defaultSession()
        
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
                                print(error)
                        }
                    }
                }
                
            }, errorHandler: { (error) -> Void in
                print(error)
                
//                dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                    
//                    self.activityImage.stopAnimating()
//                    self.activityImage.setHidden(true)
//                    self.table.setHidden(false)
//                })
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
            
//            self.activityImage.stopAnimating()
//            self.activityImage.setHidden(true)
//            self.table.setHidden(false)
        })
    }
    
    func session(session: WCSession,
        didReceiveMessage message: [String : AnyObject],
        replyHandler: ([String : AnyObject]) -> Void)
    {
        if let command = message["command"] as? NSString
        {
            if command.isEqualToString("configurationChanged") ||
                command.isEqualToString("currentActivityChanged")
            {
                if let currentActivityDict = message["currentActivity"] as? NSDictionary, currentActivity = FSCActivity.modelObjectWithDictionary(currentActivityDict as [NSObject : AnyObject])
                {
                    if let harmonyConfigDict = message["configuration"] as? NSDictionary, harmonyConfig = FSCHarmonyConfiguration.modelObjectWithDictionary(harmonyConfigDict as [NSObject : AnyObject]) {
                        
                        self.refreshTableWithConfig(harmonyConfig, currentActivity: currentActivity)
                    }
                }
            }
        }
    }
}
