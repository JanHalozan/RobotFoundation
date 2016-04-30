//
//  main.m
//  HIDTransportService
//
//  Created by Matt on 12/26/15.
//

import Foundation

final class ServiceDelegate : NSObject, NSXPCListenerDelegate, HIDTransportServiceDelegate {
	private lazy var exportedObject: HIDTransportService = {
		return HIDTransportService(delegate: self)
	}()

	private var clients = [XPCTransportClientProtocol]()
	
	func listener(listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
		newConnection.exportedInterface = NSXPCInterface(withProtocol: XPCTransportServiceProtocol.self)
		newConnection.remoteObjectInterface = NSXPCInterface(withProtocol: XPCTransportClientProtocol.self)
		newConnection.exportedObject = exportedObject
		newConnection.resume()

		if let client = newConnection.remoteObjectProxy as? XPCTransportClientProtocol {
			clients.append(client)
		}

		return true
	}

	func handleData(data: NSData) {
		for client in clients {
			client.handleTransportData(data)
		}
	}
}

let delegate = ServiceDelegate()

let listener = NSXPCListener.serviceListener()
listener.delegate = delegate

// This method does not return.
listener.resume()
