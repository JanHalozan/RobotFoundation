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

	func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
		connections.insert(newConnection)

		newConnection.exportedInterface = NSXPCInterface(with: XPCTransportServiceProtocol.self)
		newConnection.remoteObjectInterface = NSXPCInterface(with: XPCTransportClientProtocol.self)
		newConnection.exportedObject = exportedObject
		newConnection.invalidationHandler = { [unowned self] in
			DispatchQueue.main.async {
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

	func handle(_ data: Data) {
		for connection in connections {
			if let client = connection.remoteObjectProxy as? XPCTransportClientProtocol {
				client.handleTransportData(data as NSData)
			} else {
				assertionFailure()
			}
		}
	}
}

let delegate = ServiceDelegate()

let listener = NSXPCListener.service()
listener.delegate = delegate

// This method does not return.
listener.resume()

