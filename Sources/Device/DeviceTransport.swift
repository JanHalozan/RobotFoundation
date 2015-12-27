//
//  DeviceTransport.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

protocol DeviceTransportDelegate: class {
	func deviceTransportDidWriteData(transport: DeviceTransport)

	func deviceTransportDidOpen(transport: DeviceTransport)
	func deviceTransport(transport: DeviceTransport, didFailToOpenWithError error: ErrorType)

	func deviceTransportDidClose(transport: DeviceTransport)
}

class DeviceTransport {
	private(set) var isOpen = false

	weak var delegate: DeviceTransportDelegate?

	func open() throws {
		fatalError("Must be overriden")
	}

	func close() {
		fatalError("Must be overriden")
	}

	func writeData(data: NSData, handler: NSData -> ()) throws {
		fatalError("Must be overriden")
	}

	/* these methods should only be called by subclasses to invoke delegate methods */
	func wroteData() {
		assert(NSThread.isMainThread())
		delegate?.deviceTransportDidWriteData(self)
	}
	
	func opened() {
		assert(NSThread.isMainThread())

		isOpen = true
		delegate?.deviceTransportDidOpen(self)
	}

	func failedToOpenWithError(error: ErrorType) {
		assert(NSThread.isMainThread())

		isOpen = false
		delegate?.deviceTransport(self, didFailToOpenWithError: error)
	}

	func closed() {
		assert(NSThread.isMainThread())

		isOpen = false
		delegate?.deviceTransportDidClose(self)
	}
}
