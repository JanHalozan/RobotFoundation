//
//  main.m
//  HIDTransportService
//
//  Created by Matt on 12/26/15.
//

import Foundation

final class ServiceDelegate : NSObject, NSXPCListenerDelegate {
	private let exportedObject = HIDTransportService()
	
	func listener(listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
		newConnection.exportedInterface = NSXPCInterface(withProtocol: XPCTransportServiceProtocol.self)
		newConnection.exportedObject = exportedObject
		newConnection.resume()

		return true
	}
}

let delegate = ServiceDelegate()

let listener = NSXPCListener.serviceListener()
listener.delegate = delegate

// This method does not return.
listener.resume()
