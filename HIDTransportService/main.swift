//
//  main.m
//  HIDTransportService
//
//  Created by Matt on 12/26/15.
//

import Foundation

final class ServiceDelegate : NSObject, NSXPCListenerDelegate, HIDTransportServiceDelegate {
	private lazy var exportedObject: HIDTransportService = {
		HIDTransportService(delegate: self)
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

	func handleData(_ data: Data) {
		for connection in connections {
			if let client = connection.remoteObjectProxyWithErrorHandler({ error in
				print("Error communicating with the client after data was received: \(error)")
			}) as? XPCTransportClientProtocol {
				client.handleTransportData(data as NSData)
			} else {
				assertionFailure()
			}
		}
	}

	func closedConnection() {
		for connection in connections {
			if let client = connection.remoteObjectProxyWithErrorHandler({ error in
				print("Error communicating with the client after a device connection was closed: \(error)")
			}) as? XPCTransportClientProtocol {
				client.closedTransportConnection()
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
