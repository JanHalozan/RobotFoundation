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

	func closed() {
		assert(openState.get() == .Opened)
		openState.set(.Closed)

		delegate?.deviceTransportDidClose(self)
	}
}
