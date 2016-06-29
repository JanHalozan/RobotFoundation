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

	var serviceName: String {
		fatalError("Subclasses must override this method")
	}

	var identifier: String {
		fatalError("Subclasses must override this method")
	}

	override func open() throws {
		assert(NSThread.isMainThread())

		guard openState == .Closed else {
			return
		}

		if serviceConnection == nil {
			serviceConnection = NSXPCConnection(serviceName: serviceName)
		}

		guard let serviceConnection = serviceConnection else {
			assertionFailure()
			throw kIOReturnInternalError
		}

		serviceConnection.remoteObjectInterface = NSXPCInterface(withProtocol: XPCTransportServiceProtocol.self)
		serviceConnection.exportedObject = self
		serviceConnection.exportedInterface = NSXPCInterface(withProtocol: XPCTransportClientProtocol.self)
		serviceConnection.resume()

		guard let proxy = serviceConnection.remoteObjectProxy as? XPCTransportServiceProtocol else {
			assertionFailure()
			throw kIOReturnInternalError
		}

		beganOpening()

		proxy.open(identifier) { result in
			dispatch_async(dispatch_get_main_queue()) {
				if result == Int(kIOReturnSuccess) {
					self.opened()
				} else {
					self.failedToOpenWithError(IOReturn(result))
				}
			}
		}
	}

	override func close() {
		guard let serviceConnection = serviceConnection else {
			debugPrint("Tried to close a device even though we have no XPC connection.")
			return
		}

		guard let proxy = serviceConnection.remoteObjectProxy as? XPCTransportServiceProtocol else {
			assertionFailure()
			return
		}

		proxy.close(identifier) { result in
			dispatch_async(dispatch_get_main_queue()) {
				self.closed()
			}
		}
	}

	override func writeData(data: NSData, handler: NSData -> (), errorHandler: () -> ()) throws {
		guard let serviceConnection = serviceConnection else {
			debugPrint("Tried to write to a device even though we have no XPC connection.")
			return
		}

		guard let proxy = serviceConnection.remoteObjectProxy as? XPCTransportServiceProtocol else {
			assertionFailure()
			return
		}

		proxy.writeData(data, identifier: identifier) { result in
			dispatch_async(dispatch_get_main_queue()) {
				guard result == 0 else {
					debugPrint("An error occured during write (\(result)).")
					errorHandler()
					return
				}

				self.wroteData()
			}
		}
	}

	@objc func handleTransportData(data: NSData) {
		dispatch_async(dispatch_get_main_queue()) {
			self.handleData(data)
		}
	}

	override func closed() {
		super.closed()

		serviceConnection?.suspend()
		serviceConnection?.invalidate()
		serviceConnection = nil
	}
}

#endif
