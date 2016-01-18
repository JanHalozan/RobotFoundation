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

enum DeviceTransportOpenState {
	case Closed
	case Opening
	case Opened
}

class DeviceTransport {
	private(set) var openState = DeviceTransportOpenState.Closed

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

	func beganOpening() {
		assert(NSThread.isMainThread())
		
		assert(openState == .Closed)
		openState = .Opening
	}
	
	func opened() {
		assert(NSThread.isMainThread())

		assert(openState == .Opening)
		openState = .Opened

		delegate?.deviceTransportDidOpen(self)
	}

	func failedToOpenWithError(error: ErrorType) {
		assert(NSThread.isMainThread())

		assert(openState == .Opening)
		openState = .Closed

		delegate?.deviceTransport(self, didFailToOpenWithError: error)
	}

	func closed() {
		assert(NSThread.isMainThread())

		assert(openState == .Opened)
		openState = .Closed

		delegate?.deviceTransportDidClose(self)
	}
}
