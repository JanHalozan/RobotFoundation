//
//  main.m
//  HIDTransportService
//
//  Created by Matt on 12/26/15.
//  Copyright © 2015 Matt Rajca. All rights reserved.
//

import Foundation

class ServiceDelegate : NSObject, NSXPCListenerDelegate {
	func listener(listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
		// This method is where the NSXPCListener configures, accepts, and resumes a new incoming NSXPCConnection.

		// Configure the connection.
		// First, set the interface that the exported object implements.
		newConnection.exportedInterface = NSXPCInterface(withProtocol: HIDTransportServiceProtocol.self)

		// Next, set the object that the connection exports. All messages sent on the connection to this service will be sent to the exported object to handle. The connection retains the exported object.
		let exportedObject = HIDTransportService()
		newConnection.exportedObject = exportedObject

		// Resuming the connection allows the system to deliver more incoming messages.
		newConnection.resume()

		// Returning YES from this method tells the system that you have accepted this connection. If you want to reject the connection for some reason, call -invalidate on the connection and return NO.
		return true
	}
}

    // Create the delegate for the service.
    let delegate = ServiceDelegate()
    
    // Set up the one NSXPCListener for this service. It will handle all incoming connections.
    let listener = NSXPCListener.serviceListener()
    listener.delegate = delegate;
    
    // Resuming the serviceListener starts this service. This method does not return.
    listener.resume()
