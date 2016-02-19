//
//  InterfaceController.swift
//  test WatchKit Extension
//
//  Created by Sébastien Luneau on 18/02/2016.
//  Copyright © 2016 MatchPix SARL. All rights reserved.
//

import WatchKit
import WatchConnectivity
import Foundation

class InterfaceController: WKInterfaceController, WCSessionDelegate {
    @IBOutlet var imageView: WKInterfaceImage!
    
    @IBOutlet var mainGroup: WKInterfaceGroup!
    @IBOutlet var startLabel: WKInterfaceLabel!
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
        if (WCSession.isSupported()){
            let session = WCSession.defaultSession()
            session.delegate = self
            session.activateSession()
        }
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        mainGroup.setHidden(true)
        startLabel.setHidden(false)
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        mainGroup.setHidden(true)
        startLabel.setHidden(false)
        
    }
    
    // MARK: -  WatchConnectivity delegates
    func session(session: WCSession, didReceiveMessageData messageData: NSData) {
        mainGroup.setHidden(false)
        startLabel.setHidden(true)
        
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.imageView.setImageData(messageData)
        }
        
    }
    func session(session: WCSession, didReceiveMessageData messageData: NSData, replyHandler: (NSData) -> Void) {
        mainGroup.setHidden(false)
        startLabel.setHidden(true)
        
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.imageView.setImageData(messageData)
        }
    }
    // MARK: -  actions
    @IBAction func grabAction() {
        if (WCSession.defaultSession().reachable){
            let messageDict = ["action":"grab"]
            WCSession.defaultSession().sendMessage(messageDict, replyHandler: { (reply : [String : AnyObject]) -> Void in
                // do something
                }, errorHandler: { (NSError) -> Void in
                    // do something
            })
            
        }
    }
    @IBAction func switchAction() {
        if (WCSession.defaultSession().reachable){
            let messageDict = ["action":"switch"]
            
            WCSession.defaultSession().sendMessage(messageDict, replyHandler: { (reply : [String : AnyObject]) -> Void in
                // do something
                }, errorHandler: { (NSError) -> Void in
                    // do something
            })
            
        }
    }
    
}
