//
//  DeviceTransport.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

protocol DeviceTransportDelegate: class {
	func deviceTransportDidWriteData(_ transport: DeviceTransport)
	func deviceTransportHandleData(_ transport: DeviceTransport, data: Data)

	func deviceTransportDidClose(_ transport: DeviceTransport)
}

class DeviceTransport {
	weak var delegate: DeviceTransportDelegate?

	func writeData(_ data: Data, errorHandler: @escaping (Error) -> ()) throws {
		fatalError("Must be overriden")
	}

	/* these methods should only be called by subclasses to invoke delegate methods */
	func wroteData() {
		delegate?.deviceTransportDidWriteData(self)
	}

	func handleData(_ data: Data) {
		delegate?.deviceTransportHandleData(self, data: data)
	}

	func handleClosedConnection() {
		delegate?.deviceTransportDidClose(self)
	}
}
