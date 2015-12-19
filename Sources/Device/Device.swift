//
//  Device.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

protocol DeviceDelegate: class {
	func deviceDidOpen(device: Device)
	func device(device: Device, didFailToOpenWithError error: ErrorType)

	func deviceDidClose()
}

class Device: DeviceTransportDelegate {
	let transport: DeviceTransport

	var isOpen: Bool {
		return transport.isOpen
	}

	weak var delegate: DeviceDelegate?

	init(transport: DeviceTransport) {
		self.transport = transport
		transport.delegate = self
	}

	deinit {
		close()
	}

	func open() throws {
		try transport.open()
	}

	func close() {
		transport.close()
	}

	func deviceTransportDidWriteData(transport: DeviceTransport) {
		wroteData()
	}

	func deviceTransport(transport: DeviceTransport, didReceiveData data: NSData) {
		receivedData(data)
	}

	func deviceTransportDidClose(transport: DeviceTransport) {
		delegate?.deviceDidClose()
	}

	func deviceTransport(transport: DeviceTransport, didFailToOpenWithError error: ErrorType) {
		delegate?.device(self, didFailToOpenWithError: error)
	}

	func deviceTransportDidOpen(transport: DeviceTransport) {
		openedTransport()
		delegate?.deviceDidOpen(self)
	}

	/* this is only for use by subclasses */
	func openedTransport() {
		fatalError("Subclasses must override")
	}

	func wroteData() {
		fatalError("Subclasses must override")
	}

	func receivedData(data: NSData) {
		fatalError("Subclasses must override")
	}
}
