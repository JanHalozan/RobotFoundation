//
//  DeviceTransport.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

protocol DeviceTransportDelegate: class {
	func deviceTransportDidWriteData(transport: DeviceTransport)
	func deviceTransportHandleData(transport: DeviceTransport, data: NSData)

	func deviceTransportDidOpen(transport: DeviceTransport)
	func deviceTransport(transport: DeviceTransport, didFailToOpenWithError error: ErrorType)

	func deviceTransportDidClose(transport: DeviceTransport)
}

enum DeviceTransportOpenState {
	case Closed
	case Opening
	case Opened
}

extension DeviceTransportOpenState: Initializable {
	init() {
		self = .Closed
	}
}

class DeviceTransport {
	let openState = SimpleAtomic<DeviceTransportOpenState>()

	weak var delegate: DeviceTransportDelegate?

	func open() throws {
		fatalError("Must be overriden")
	}

	func close() {
		fatalError("Must be overriden")
	}

	func writeData(data: NSData, errorHandler: (ErrorType) -> ()) throws {
		fatalError("Must be overriden")
	}

	func scheduleRead() {
		// May be overriden
	}

	/* these methods should only be called by subclasses to invoke delegate methods */
	func wroteData() {
		delegate?.deviceTransportDidWriteData(self)
	}

	func handleData(data: NSData) {
		delegate?.deviceTransportHandleData(self, data: data)
	}

	func beganOpening() {
		assert(openState.get() == .Closed)
		openState.set(.Opening)
	}
	
	func opened() {
		assert(openState.get() == .Opening)
		openState.set(.Opened)

		delegate?.deviceTransportDidOpen(self)
	}

	func failedToOpenWithError(error: ErrorType) {
		assert(openState.get() == .Opening)
		openState.set(.Closed)

		delegate?.deviceTransport(self, didFailToOpenWithError: error)
	}

	func closed() {
		assert(openState.get() == .Opened)
		openState.set(.Closed)

		delegate?.deviceTransportDidClose(self)
	}
}
