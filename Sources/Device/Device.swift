//
//  Device.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

public class Device: DeviceTransportDelegate {
	let transport: DeviceTransport

	init(transport: DeviceTransport) {
		self.transport = transport
		transport.delegate = self
	}

	// MARK: - Device Transport Delegate

	func deviceTransportDidWriteData(transport: DeviceTransport) {
		wroteData()
	}

	func deviceTransportDidClose(transport: DeviceTransport) {
		// TODO: should we do anything else here?
	}

	func deviceTransportHandleData(transport: DeviceTransport, data: NSData) {
		handleData(data)
	}

	/* this is only for use by subclasses */
	func wroteData() {
		// no-op by default
	}

	func handleData(data: NSData) {
		fatalError("Subclasses must override")
	}
}
