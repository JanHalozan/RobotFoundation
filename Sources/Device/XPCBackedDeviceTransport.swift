//
//  HIDDeviceTransport.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

#if os(OSX)

import Foundation
import IOKit.hid

class XPCBackedDeviceTransport: DeviceTransport, XPCTransportClientProtocol {
	private var serviceConnection: NSXPCConnection?
	private let connectionQueue = dispatch_queue_create(nil, nil)

	var serviceName: String {
		fatalError("Subclasses must override this method")
	}

	var identifier: String {
		fatalError("Subclasses must override this method")
	}

	private func accessConnection(errorHandler: () -> (), accessor: (NSXPCConnection) -> Bool) -> Bool {
		var result = false
		dispatch_sync(connectionQueue) {
			guard let connection = self.serviceConnection else {
				errorHandler()
				return
			}

			result = accessor(connection)
		}
		return result
	}

	private func modifyConnection(errorHandler: () -> (), modifier: (NSXPCConnection) -> NSXPCConnection?) {
		dispatch_barrier_async(connectionQueue) {
			guard let connection = self.serviceConnection else {
				errorHandler()
				return
			}

			self.serviceConnection = modifier(connection)
		}
	}

	override func writeData(data: NSData, errorHandler: (ErrorType) -> ()) throws {
		dispatch_barrier_async(connectionQueue) {
			if self.serviceConnection != nil {
				return
			}

			let connection = NSXPCConnection(serviceName: self.serviceName)
			connection.remoteObjectInterface = NSXPCInterface(withProtocol: XPCTransportServiceProtocol.self)
			connection.exportedObject = self
			connection.exportedInterface = NSXPCInterface(withProtocol: XPCTransportClientProtocol.self)
			connection.resume()
			self.serviceConnection = connection
		}

		accessConnection({
			print("Tried to write to a device even though we have no XPC connection.")
		}) { connection in
			guard let proxy = connection.remoteObjectProxyWithErrorHandler({ error in
				print("Failed to communicate with the XPC transport service during write: \(error)")
				errorHandler(kIOReturnNoMedia)
			}) as? XPCTransportServiceProtocol else {
				errorHandler(kIOReturnNoMedia)
				assertionFailure()
				return false
			}

			proxy.writeData(data, identifier: self.identifier) { result in
				guard result == Int(kIOReturnSuccess) else {
					print("An error occured during write (\(result)).")
					errorHandler(IOReturn(result))
					return
				}

				self.wroteData()
			}

			return true
		}
	}

	override func scheduleRead() {
		accessConnection({
			print("Tried to write to a device even though we have no XPC connection.")
		}) { connection in
			guard let proxy = connection.remoteObjectProxy as? XPCTransportServiceProtocol else {
				assertionFailure()
				return false
			}

			proxy.scheduleRead(self.identifier, handler: { result in
				guard result == Int(kIOReturnSuccess) else {
					print("An error occured while scheduling a read (\(result)).")
					return
				}
			})

			return true
		}
	}

	@objc func handleTransportData(data: NSData) {
		self.handleData(data)
	}

	@objc func closedTransportConnection() {
		self.handleClosedConnection()
	}
}

#endif
