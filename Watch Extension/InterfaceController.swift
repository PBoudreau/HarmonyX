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
    var dataLoadedOnce = false
    
    override init() {
        super.init()
        
        self.loadData()
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    private func loadData() {
        session = WCSession.defaultSession()
        
        session!.sendMessage(["command": "getHarmonyState"], replyHandler:
            {
                (response) -> Void in
                
                let currentActivityDict = response["currentActivity"] as? NSDictionary
                let currentActivity = FSCActivity.modelObjectWithDictionary(currentActivityDict as! [NSObject : AnyObject]) as FSCActivity
                
                if let harmonyConfigDict = response["configuration"] as? NSDictionary, harmonyConfig = FSCHarmonyConfiguration.modelObjectWithDictionary(harmonyConfigDict as [NSObject : AnyObject]) {
                    
                    let activities = harmonyConfig.activity

                    dispatch_async(dispatch_get_main_queue(), { () -> Void in

                        self.table.setNumberOfRows(activities.count, withRowType: "ActivityTableRowController")
                        
                        for (index, element) in activities.enumerate() {
                            let row = self.table.rowControllerAtIndex(index) as! ActivityTableRowController
                            
                            let activity = element as! FSCActivity
                            
                            row.image.setImage(activity.watchImage(currentActivity.activityIdentifier == activity.activityIdentifier))
                            row.activityName.setText(activity.label);
                        }
                        
                        self.activityImage.stopAnimating()
                        self.activityImage.setHidden(true)
                        self.table.setHidden(false)
                    })
                }
                
                self.dataLoadedOnce = true
                
            }, errorHandler: { (error) -> Void in
                print(error)
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    self.activityImage.stopAnimating()
                    self.activityImage.setHidden(true)
                    self.table.setHidden(false)
                    
                    self.dataLoadedOnce = true
                })
        })
    }
}
