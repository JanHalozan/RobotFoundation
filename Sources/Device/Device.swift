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

public class Device: DeviceTransportDelegate {
	let transport: DeviceTransport

	var isOpen: Bool {
		return transport.openState == .Opened
	}

	weak var delegate: DeviceDelegate?

	init(transport: DeviceTransport) {
		self.transport = transport
		transport.delegate = self
	}

	deinit {
		close()
	}

	public func open() throws {
		try transport.open()
	}

	public func close() {
		transport.close()
	}

	func deviceTransportDidWriteData(transport: DeviceTransport) {
		wroteData()
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
}
