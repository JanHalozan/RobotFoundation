//
//  Device.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

public class Device: DeviceTransportDelegate {
	let transport: DeviceTransport

	public var isOpen: Bool {
		return transport.openState.get() == .Opened
	}

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

	// MARK: - Device Transport Delegate

	func deviceTransportDidWriteData(transport: DeviceTransport) {
		wroteData()
	}

	func deviceTransportDidClose(transport: DeviceTransport) {
		// TODO: should we do anything else here?
	}

	func deviceTransport(transport: DeviceTransport, didFailToOpenWithError error: ErrorType) {
		failedToOpenTransport()
	}

	func deviceTransportDidOpen(transport: DeviceTransport) {
		openedTransport()
	}

	func deviceTransportHandleData(transport: DeviceTransport, data: NSData) {
		handleData(data)
	}

	/* this is only for use by subclasses */
	func failedToOpenTransport() {
		// no-op by default
	}

	func openedTransport() {
		fatalError("Subclasses must override")
	}

	func wroteData() {
		// no-op by default
	}

	func handleData(data: NSData) {
		fatalError("Subclasses must override")
	}
}
