//
//  NXTDevice.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

public final class NXTDevice: Device {
	// The device will wait until all critical commands complete before going away.
	public func enqueueCommand(command: NXTCommand, isCritical: Bool = true, responseHandler: NXTCommandHandler) {
		let operation = NXTCommandOperation(transport: transport, command: command, isCritical: isCritical, responseHandler: responseHandler)
		enqueueOperation(operation)
	}

	override func handleData(data: NSData) {
		for operation in operations {
			if let commandOperation = operation as? NXTCommandOperation where commandOperation.canHandleResponseData(data) {
				commandOperation.handleResponseData(data)
				return
			}
		}

		print("Unhandled NXT response")
	}

	override func wroteData() {
		guard let usbTransport = transport as? LegacyUSBDeviceTransport else {
			// Skip scheduling reads for Bluetooth transports.
			return
		}

		usbTransport.scheduleRead()
	}
}
