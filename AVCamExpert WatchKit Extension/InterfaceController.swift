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
    /** Called when the session has completed activation. If session state is WCSessionActivationStateNotActivated there will be an error with more details. */
    @available(watchOS 2.2, *)
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }

    @IBOutlet var imageView: WKInterfaceImage!
    
    @IBOutlet var mainGroup: WKInterfaceGroup!
    @IBOutlet var startLabel: WKInterfaceLabel!
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        if (WCSession.isSupported()){
            let session = WCSession.default()
            session.delegate = self
            session.activate()
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
    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        mainGroup.setHidden(false)
        startLabel.setHidden(true)
        
        DispatchQueue.main.async { () -> Void in
            self.imageView.setImageData(messageData)
        }
        
    }
    func session(_ session: WCSession, didReceiveMessageData messageData: Data, replyHandler: @escaping (Data) -> Void) {
        mainGroup.setHidden(false)
        startLabel.setHidden(true)
        
        DispatchQueue.main.async { () -> Void in
            self.imageView.setImageData(messageData)
        }
    }
    // MARK: -  actions
    @IBAction func grabAction() {
        if (WCSession.default().isReachable){
            let messageDict = ["action":"grab"]
            WCSession.default().sendMessage(messageDict, replyHandler: { (_: [String : Any]) in
                // do something            
            }, errorHandler: { (Error) in
                // do something
            })

            
        }
    }
    @IBAction func switchAction() {
        if (WCSession.default().isReachable){
            let messageDict = ["action":"switch"]
            
            WCSession.default().sendMessage(messageDict, replyHandler: { (_: [String : Any]) in
                // do something
            }, errorHandler: { (Error) in
                // do something
            })
            
        }
    }
    
}
