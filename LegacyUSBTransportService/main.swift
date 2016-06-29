//
//  main.swift
//  RobotFoundation
//
//  Created by Matt on 6/29/16.
//

import Foundation

final class ServiceDelegate : NSObject, NSXPCListenerDelegate, LegacyUSBTransportServiceDelegate {
	private lazy var exportedObject: LegacyUSBTransportService = {
		LegacyUSBTransportService(delegate: self)
	}()

	private var connections = Set<NSXPCConnection>()

	func listener(listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
		connections.insert(newConnection)

		newConnection.exportedInterface = NSXPCInterface(withProtocol: XPCTransportServiceProtocol.self)
		newConnection.remoteObjectInterface = NSXPCInterface(withProtocol: XPCTransportClientProtocol.self)
		newConnection.exportedObject = exportedObject
		newConnection.invalidationHandler = { [unowned self] in
			dispatch_async(dispatch_get_main_queue()) {
				self.connections.remove(newConnection)

				if self.connections.isEmpty {
					// Exit if no more connections...
					exit(0)
				}
			}
		}
		newConnection.resume()

		return true
	}

	func handleData(data: NSData) {
		for connection in connections {
			if let client = connection.remoteObjectProxy as? XPCTransportClientProtocol {
				client.handleTransportData(data)
			} else {
				assertionFailure()
			}
		}
	}
}

let delegate = ServiceDelegate()

let listener = NSXPCListener.serviceListener()
listener.delegate = delegate

// This method does not return.
listener.resume()

