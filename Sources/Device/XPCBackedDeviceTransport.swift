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
	private let connectionQueue = DispatchQueue(label: "xpc transport", attributes: [])

	var serviceName: String {
		fatalError("Subclasses must override this method")
	}

	var identifier: String {
		fatalError("Subclasses must override this method")
	}

	private func accessConnection(errorHandler: @escaping () -> (), accessor: @escaping (NSXPCConnection) -> Bool) -> Bool {
		var result = false
		connectionQueue.sync {
			guard let connection = self.serviceConnection else {
				errorHandler()
				return
			}

			result = accessor(connection)
		}
		return result
	}

	private func modifyConnection(errorHandler: @escaping () -> (), modifier: @escaping (NSXPCConnection) -> NSXPCConnection?) {
		connectionQueue.async(flags: .barrier) {
			guard let connection = self.serviceConnection else {
				errorHandler()
				return
			}

			self.serviceConnection = modifier(connection)
		}
	}

	override func writeData(_ data: Data, errorHandler: @escaping (Error) -> ()) throws {
		connectionQueue.async(flags: .barrier) {
			if self.serviceConnection != nil {
				return
			}

			let connection = NSXPCConnection(serviceName: self.serviceName)
			connection.remoteObjectInterface = NSXPCInterface(with: XPCTransportServiceProtocol.self)
			connection.exportedObject = self
			connection.exportedInterface = NSXPCInterface(with: XPCTransportClientProtocol.self)
			connection.resume()
			self.serviceConnection = connection
		}

		accessConnection(errorHandler: {
			print("Tried to write to a device even though we have no XPC connection.")
		}) { connection in
			guard let proxy = connection.remoteObjectProxyWithErrorHandler({ error in
				print("Failed to communicate with the XPC transport service during write: \(error)")
				errorHandler(kIOReturnNoMedia as Error)
			}) as? XPCTransportServiceProtocol else {
				errorHandler(kIOReturnNoMedia as Error)
				assertionFailure()
				return false
			}

			proxy.writeData(data as NSData, identifier: self.identifier as NSString) { result in
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
		accessConnection(errorHandler: {
			print("Tried to write to a device even though we have no XPC connection.")
		}) { connection in
			guard let proxy = connection.remoteObjectProxy as? XPCTransportServiceProtocol else {
				assertionFailure()
				return false
			}

			proxy.scheduleRead(self.identifier as NSString, handler: { result in
				guard result == Int(kIOReturnSuccess) else {
					print("An error occured while scheduling a read (\(result)).")
					return
				}
			})

			return true
		}
	}

	@objc func handleTransportData(_ data: NSData) {
		self.handleData(data as Data)
	}

	@objc func closedTransportConnection() {
		self.handleClosedConnection()
	}
}

#endif
