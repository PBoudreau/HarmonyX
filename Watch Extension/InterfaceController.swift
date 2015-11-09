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
        
        session = WCSession.defaultSession()
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        print("willActivate")

        if (!self.stateInitialized)
        {
            self.stateInitialized = true
            
            self.initializeState()
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

    private func initializeState() {
        
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
        
        replyHandler([:]);
    }
}
